# frozen_string_literal: true

RSpec.describe DiscourseDodoSubscriptions::Product do
  it "allows WeChat Pay for eligible one-time products" do
    product =
      Fabricate.build(
        :dodo_product,
        billing_type: "one_time",
        wechat_pay_enabled: true,
        currency: "CNY",
        amount_cents: 100,
      )

    expect(product).to be_valid
  end

  it "rejects WeChat Pay for subscription products" do
    product =
      Fabricate.build(
        :dodo_product,
        billing_type: "subscription",
        wechat_pay_enabled: true,
        currency: "USD",
        amount_cents: 500,
      )

    expect(product).not_to be_valid
  end

  it "rejects a WeChat Pay amount below the currency minimum" do
    product =
      Fabricate.build(
        :dodo_product,
        billing_type: "one_time",
        wechat_pay_enabled: true,
        currency: "USD",
        amount_cents: 49,
      )

    expect(product).not_to be_valid
  end
end
