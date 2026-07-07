# frozen_string_literal: true

RSpec.describe DiscourseDodoSubscriptions::SubscribeController do
  before do
    SiteSetting.discourse_dodo_subscriptions_enabled = true
    SiteSetting.discourse_dodo_subscriptions_api_key = "api-key"
  end

  describe "#index" do
    it "lists published products" do
      Fabricate(:dodo_product, external_id: "pdt_123", name: "Members")

      get "/subscribe.json"

      expect(response.parsed_body.first).to include("id" => "pdt_123", "name" => "Members")
    end
  end

  describe "#create_checkout" do
    let(:user) { Fabricate(:user) }
    let!(:product) { Fabricate(:dodo_product, external_id: "pdt_123") }

    before { sign_in(user) }

    it "creates a Dodo checkout and returns its URL" do
      client = instance_double(DiscourseDodoSubscriptions::Client)
      DiscourseDodoSubscriptions::Client.expects(:new).returns(client)
      client
        .expects(:create_checkout)
        .with(has_entries(product: product, user: user))
        .returns(checkout_url: "https://checkout.dodopayments.com/test")

      post "/subscribe/checkout.json", params: { product_id: product.external_id }

      expect(response.parsed_body["checkout_url"]).to eq("https://checkout.dodopayments.com/test")
    end
  end
end
