# frozen_string_literal: true

RSpec.describe DiscourseDodoSubscriptions::WebhookProcessor do
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
end
