# frozen_string_literal: true

RSpec.describe DiscourseDodoSubscriptions::WebhookVerifier do
  let(:payload) { '{"type":"subscription.active"}' }
  let(:webhook_id) { "evt_123" }
  let(:timestamp) { Time.zone.now.to_i.to_s }
  let(:secret) { "secret" }

  def signature_for(secret)
    Base64.strict_encode64(
      OpenSSL::HMAC.digest("SHA256", secret, "#{webhook_id}.#{timestamp}.#{payload}"),
    )
  end

  it "accepts a valid Standard Webhooks signature" do
    expect {
      described_class.verify!(
        payload: payload,
        webhook_id: webhook_id,
        timestamp: timestamp,
        signature: "v1,#{signature_for(secret)}",
        secret: secret,
      )
    }.not_to raise_error
  end

  it "accepts a valid Standard Webhooks signature with a whsec secret" do
    decoded_secret = "decoded-secret"
    webhook_secret = "whsec_#{Base64.urlsafe_encode64(decoded_secret, padding: false)}"

    expect {
      described_class.verify!(
        payload: payload,
        webhook_id: webhook_id,
        timestamp: timestamp,
        signature: "v1,#{signature_for(decoded_secret)}",
        secret: webhook_secret,
      )
    }.not_to raise_error
  end

  it "accepts a whsec secret as a raw fallback" do
    webhook_secret = "whsec_not_base64"

    expect {
      described_class.verify!(
        payload: payload,
        webhook_id: webhook_id,
        timestamp: timestamp,
        signature: "v1,#{signature_for(webhook_secret)}",
        secret: webhook_secret,
      )
    }.not_to raise_error
  end

  it "rejects an invalid signature" do
    expect {
      described_class.verify!(
        payload: payload,
        webhook_id: webhook_id,
        timestamp: timestamp,
        signature: "v1,bad",
        secret: secret,
      )
    }.to raise_error(Discourse::InvalidAccess)
  end
end
