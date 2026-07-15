# frozen_string_literal: true

RSpec.describe DiscourseDodoSubscriptions::Client do
  before do
    SiteSetting.discourse_dodo_subscriptions_api_key = "api-key"
    SiteSetting.discourse_dodo_subscriptions_environment = "test"
  end

  let(:user) { Fabricate(:user) }

  def successful_response
    Net::HTTPOK.new("1.1", "200", "OK").tap do |response|
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, JSON.dump(checkout_url: "https://checkout.example/test"))
    end
  end

  it "enables WeChat Pay with card fallbacks for eligible one-time products" do
    product =
      Fabricate(
        :dodo_product,
        billing_type: "one_time",
        wechat_pay_enabled: true,
        currency: "CNY",
        amount_cents: 500,
      )
    client = described_class.new
    client
      .expects(:perform)
      .with do |_uri, request|
        body = JSON.parse(request.body)
        expect(body["allowed_payment_method_types"]).to eq(%w[we_chat_pay credit debit])
        expect(body["billing_currency"]).to eq("CNY")
        true
      end
      .returns(successful_response)

    client.create_checkout(
      product: product,
      user: user,
      return_url: "https://example.com/success",
    )
  end

  it "leaves payment methods to Dodo for subscription products" do
    product = Fabricate(:dodo_product, billing_type: "subscription")
    client = described_class.new
    client
      .expects(:perform)
      .with do |_uri, request|
        body = JSON.parse(request.body)
        expect(body).not_to have_key("allowed_payment_method_types")
        expect(body).not_to have_key("billing_currency")
        true
      end
      .returns(successful_response)

    client.create_checkout(
      product: product,
      user: user,
      return_url: "https://example.com/success",
    )
  end
end
