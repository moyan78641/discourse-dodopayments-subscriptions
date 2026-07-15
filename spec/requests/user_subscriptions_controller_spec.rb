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

    it "shows one primary subscription per non-repurchaseable product" do
      customer = DiscourseDodoSubscriptions::Customer.find_by(user_id: user.id)
      Fabricate(
        :dodo_subscription,
        customer: customer,
        product: product,
        external_id: "sub_duplicate",
        current_period_end: 2.months.from_now,
      )

      get "/subscribe/user/subscriptions.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body).to contain_exactly(
        include(
          "id" => "sub_duplicate",
          "duplicate_subscription_count" => 1,
        ),
      )
    end

    it "lists one-time membership access" do
      one_time_product =
        Fabricate(
          :dodo_product,
          external_id: "pdt_one_time",
          name: "Members prepaid",
          plan_key: "members",
          billing_type: "one_time",
          recurring_interval: "year",
        )
      Fabricate(
        :dodo_order,
        user: user,
        product: one_time_product,
        external_id: "pay_123",
        payment_method: "we_chat_pay",
        expires_at: 1.year.from_now,
      )

      get "/subscribe/user/subscriptions.json"

      expect(response.parsed_body).to include(
        include(
          "id" => "pay_123",
          "billing_type" => "one_time",
          "status" => "active",
          "payment_method" => "we_chat_pay",
        ),
      )
    end

    it "ignores a refunded extension when calculating the active expiry" do
      one_time_product =
        Fabricate(
          :dodo_product,
          external_id: "pdt_one_time",
          name: "Members prepaid",
          plan_key: "members",
          billing_type: "one_time",
        )
      active_order =
        Fabricate(
          :dodo_order,
          user: user,
          product: one_time_product,
          external_id: "pay_active",
          expires_at: 1.month.from_now,
        )
      Fabricate(
        :dodo_order,
        user: user,
        product: one_time_product,
        external_id: "pay_refunded",
        status: "refunded",
        starts_at: 1.month.from_now,
        expires_at: 2.months.from_now,
      )

      get "/subscribe/user/subscriptions.json"

      record = response.parsed_body.find { |item| item["id"] == active_order.external_id }
      expect(record["status"]).to eq("active")
      expect(Time.zone.parse(record["current_period_end"])).to be_within(1.second).of(
        active_order.expires_at,
      )
    end
  end
end
