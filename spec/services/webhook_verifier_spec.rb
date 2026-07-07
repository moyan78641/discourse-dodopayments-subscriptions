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
