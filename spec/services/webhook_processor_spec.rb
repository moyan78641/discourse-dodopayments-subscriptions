# frozen_string_literal: true

RSpec.describe DiscourseDodoSubscriptions::WebhookProcessor do
  before do
    SiteSetting.discourse_dodo_subscriptions_notify_on_purchase = false
    SiteSetting.discourse_dodo_subscriptions_notify_on_expiration = false
  end

  let(:user) { Fabricate(:user) }
  let(:group) { Fabricate(:group, name: "dodo_members") }
  let!(:product) { Fabricate(:dodo_product, external_id: "pdt_123", group_name: group.name) }
  let(:user_reference) do
    user.signed_id(
      expires_in: DiscourseDodoSubscriptions::CHECKOUT_USER_REFERENCE_EXPIRES_IN,
      purpose: DiscourseDodoSubscriptions::CHECKOUT_USER_REFERENCE_PURPOSE,
    )
  end

  def event(type: "subscription.active", status: "active")
    {
      type: type,
      data: {
        subscription_id: "sub_123",
        product_id: product.external_id,
        status: status,
        customer: {
          customer_id: "cus_123",
          email: user.email,
        },
        metadata: {
          discourse_user_reference: user_reference,
          dodo_product_id: product.external_id,
        },
      },
    }
  end

  it "grants the configured group when a subscription becomes active" do
    expect { described_class.process!(event: event) }.to change { group.users.count }.by(1)

    expect(
      DiscourseDodoSubscriptions::Subscription.exists?(
        external_id: "sub_123",
        status: "active",
      ),
    ).to eq(true)
  end

  it "revokes the group when an existing subscription is cancelled" do
    customer = Fabricate(:dodo_customer, user_id: user.id, external_id: "cus_123", email: user.email)
    Fabricate(:dodo_subscription, customer: customer, product: product, external_id: "sub_123")
    group.add(user)

    cancel_event = {
      type: "subscription.cancelled",
      data: {
        subscription_id: "sub_123",
        product_id: product.external_id,
        status: "cancelled",
        customer: {
          customer_id: "cus_123",
          email: user.email,
        },
      },
    }

    expect { described_class.process!(event: cancel_event) }.to change { group.users.count }.by(-1)
  end

  it "creates a one-time membership order from a successful payment" do
    one_time_product =
      Fabricate(
        :dodo_product,
        external_id: "pdt_one_time",
        group_name: group.name,
        billing_type: "one_time",
        recurring_interval: "quarter",
        currency: "CNY",
        amount_cents: 1000,
      )
    payment_event = {
      type: "payment.succeeded",
      data: {
        payment_id: "pay_123",
        total_amount: 1000,
        currency: "CNY",
        payment_method_type: "we_chat_pay",
        customer: { email: user.email },
        product_cart: [{ product_id: one_time_product.external_id, quantity: 1 }],
        metadata: {
          discourse_user_reference: user_reference,
          discourse_product_id: one_time_product.id.to_s,
          dodo_product_id: one_time_product.external_id,
        },
      },
    }

    expect { described_class.process!(event: payment_event) }.to change {
      DiscourseDodoSubscriptions::Order.count
    }.by(1).and change { group.users.count }.by(1)

    order = DiscourseDodoSubscriptions::Order.find_by(external_id: "pay_123")
    expect(order.payment_method).to eq("we_chat_pay")
    expect(order.expires_at).to be_within(1.minute).of(3.months.from_now)

    expect { described_class.process!(event: payment_event) }.not_to change {
      DiscourseDodoSubscriptions::Order.count
    }
  end

  it "repairs group access when a successful payment webhook is retried" do
    one_time_product =
      Fabricate(
        :dodo_product,
        external_id: "pdt_one_time",
        group_name: group.name,
        billing_type: "one_time",
      )
    Fabricate(
      :dodo_order,
      user: user,
      product: one_time_product,
      external_id: "pay_123",
    )

    expect {
      described_class.process!(
        event: {
          type: "payment.succeeded",
          data: {
            payment_id: "pay_123",
            customer: { email: user.email },
            product_cart: [{ product_id: one_time_product.external_id, quantity: 1 }],
          },
        },
      )
    }.to change { group.users.count }.by(1)
  end

  it "extends one-time access from the existing expiry" do
    one_time_product =
      Fabricate(
        :dodo_product,
        external_id: "pdt_one_time",
        group_name: group.name,
        billing_type: "one_time",
        recurring_interval: "quarter",
      )
    existing_order =
      Fabricate(
        :dodo_order,
        user: user,
        product: one_time_product,
        expires_at: 3.days.from_now,
      )

    described_class.process!(
      event: {
        type: "payment.succeeded",
        data: {
          payment_id: "pay_renewal",
          customer: { email: user.email },
          product_cart: [{ product_id: one_time_product.external_id, quantity: 1 }],
          total_amount: 1000,
          currency: "USD",
          metadata: {
            discourse_user_reference: user_reference,
            discourse_product_id: one_time_product.id.to_s,
          },
        },
      },
    )

    renewal = DiscourseDodoSubscriptions::Order.find_by(external_id: "pay_renewal")
    expect(renewal.starts_at).to be_within(1.second).of(existing_order.expires_at)
    expect(renewal.expires_at).to be_within(1.second).of(existing_order.expires_at + 3.months)
  end

  it "keeps group access when another valid source remains" do
    one_time_product =
      Fabricate(
        :dodo_product,
        external_id: "pdt_one_time",
        group_name: group.name,
        billing_type: "one_time",
      )
    Fabricate(:dodo_order, user: user, product: one_time_product, expires_at: 1.month.from_now)
    customer = Fabricate(:dodo_customer, user_id: user.id, external_id: "cus_123", email: user.email)
    Fabricate(:dodo_subscription, customer: customer, product: product, external_id: "sub_123")
    group.add(user)

    described_class.process!(
      event: {
        type: "subscription.cancelled",
        data: {
          subscription_id: "sub_123",
          product_id: product.external_id,
          status: "cancelled",
          customer: { customer_id: "cus_123", email: user.email },
        },
      },
    )

    expect(group.users).to include(user)
  end

  it "revokes one-time access after a full refund" do
    one_time_product =
      Fabricate(:dodo_product, group_name: group.name, billing_type: "one_time")
    order = Fabricate(:dodo_order, user: user, product: one_time_product, external_id: "pay_123")
    group.add(user)

    described_class.process!(
      event: {
        type: "refund.succeeded",
        data: {
          payment_id: order.external_id,
          refund_id: "rfd_123",
          is_partial: false,
          amount: 500,
        },
      },
    )

    expect(order.reload.status).to eq("refunded")
    expect(group.users).not_to include(user)
  end
end
