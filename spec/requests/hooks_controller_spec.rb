# frozen_string_literal: true

RSpec.describe DiscourseDodoSubscriptions::HooksController do
  before do
    SiteSetting.discourse_dodo_subscriptions_enabled = true
    SiteSetting.discourse_dodo_subscriptions_webhook_secret = "secret"
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
  let(:payload_hash) do
    {
      type: "subscription.active",
      data: {
        subscription_id: "sub_123",
        product_id: product.external_id,
        status: "active",
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
  let(:payload) { JSON.dump(payload_hash) }
  let(:webhook_id) { "evt_123" }
  let(:timestamp) { Time.zone.now.to_i.to_s }

  def headers
    signature =
      Base64.strict_encode64(
        OpenSSL::HMAC.digest(
          "SHA256",
          "secret",
          "#{webhook_id}.#{timestamp}.#{payload}",
        ),
      )

    {
      "webhook-id" => webhook_id,
      "webhook-timestamp" => timestamp,
      "webhook-signature" => "v1,#{signature}",
    }
  end

  it "processes a valid webhook and grants the group" do
    expect { post "/subscribe/webhooks/dodo.json", params: payload, headers: headers }.to change {
      group.users.count
    }.by(1)

    expect(response.status).to eq(200)
  end

  it "is idempotent by webhook id" do
    post "/subscribe/webhooks/dodo.json", params: payload, headers: headers
    expect(response.status).to eq(200)

    expect { post "/subscribe/webhooks/dodo.json", params: payload, headers: headers }.not_to change {
      DiscourseDodoSubscriptions::Subscription.count
    }
    expect(response.status).to eq(200)
  end
end
