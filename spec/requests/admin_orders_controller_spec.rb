# frozen_string_literal: true

RSpec.describe DiscourseDodoSubscriptions::Admin::OrdersController do
  before do
    SiteSetting.discourse_dodo_subscriptions_enabled = true
    SiteSetting.discourse_dodo_subscriptions_notify_on_purchase = false
    sign_in(Fabricate(:admin))
  end

  let(:user) { Fabricate(:user) }
  let!(:product) do
    Fabricate(
      :dodo_product,
      billing_type: "one_time",
      recurring_interval: "quarter",
      currency: "CNY",
      amount_cents: 2000,
    )
  end

  it "creates a manual membership order" do
    expect {
      post "/subscribe/admin/orders.json",
           params: {
             username_or_email: user.username,
             product_id: product.id,
             duration_days: 45,
             payment_method: "offline_transfer",
             note: "Private payment",
             notify_user: false,
           }
    }.to change { DiscourseDodoSubscriptions::Order.count }.by(1)

    expect(response.status).to eq(200)
    order = DiscourseDodoSubscriptions::Order.last
    expect(order.source).to eq("manual")
    expect(order.payment_method).to eq("offline_transfer")
    expect(order.expires_at).to be_within(1.minute).of(45.days.from_now)
    expect(order.events.pluck(:action)).to contain_exactly("created")
  end

  it "revokes a manual membership order" do
    order = Fabricate(:dodo_order, user: user, product: product)

    patch "/subscribe/admin/orders/#{order.id}.json",
          params: {
            operation: "revoke",
            note: "Charge reversed",
          }

    expect(response.status).to eq(200)
    expect(order.reload.status).to eq("revoked")
  end
end
