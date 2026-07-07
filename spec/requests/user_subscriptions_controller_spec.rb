# frozen_string_literal: true

RSpec.describe DiscourseDodoSubscriptions::User::SubscriptionsController do
  before { SiteSetting.discourse_dodo_subscriptions_enabled = true }

  describe "#index" do
    let(:user) { Fabricate(:user) }
    let(:other_user) { Fabricate(:user) }
    let(:product) do
      Fabricate(
        :dodo_product,
        external_id: "pdt_123",
        name: "Members",
        amount_cents: 500,
        currency: "USD",
        recurring_interval: "month",
      )
    end

    before do
      customer = Fabricate(:dodo_customer, user_id: user.id)
      other_customer = Fabricate(:dodo_customer, user_id: other_user.id)

      Fabricate(
        :dodo_subscription,
        customer: customer,
        product: product,
        external_id: "sub_123",
        current_period_end: 1.month.from_now,
      )
      Fabricate(
        :dodo_subscription,
        customer: other_customer,
        product: product,
        external_id: "sub_other",
      )

      sign_in(user)
    end

    it "lists subscriptions for the current user" do
      get "/subscribe/user/subscriptions.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to contain_exactly(
        include(
          "id" => "sub_123",
          "status" => "active",
          "product" => include(
            "id" => "pdt_123",
            "name" => "Members",
            "amount_cents" => 500,
            "currency" => "USD",
            "recurring_interval" => "month",
          ),
        ),
      )
    end
  end
end
