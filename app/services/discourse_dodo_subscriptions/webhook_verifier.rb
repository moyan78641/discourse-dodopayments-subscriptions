# frozen_string_literal: true

require "base64"
require "openssl"

module DiscourseDodoSubscriptions
  class WebhookVerifier
    TOLERANCE = 5.minutes

    def self.verify!(payload:, webhook_id:, timestamp:, signature:, secret:)
      new(
        payload: payload,
        webhook_id: webhook_id,
        timestamp: timestamp,
        signature: signature,
        secret: secret,
      ).verify!
    end

    def initialize(payload:, webhook_id:, timestamp:, signature:, secret:)
      @payload = payload
      @webhook_id = webhook_id
      @timestamp = timestamp
      @signature = signature
      @secret = secret
    end

    def verify!
      raise Discourse::InvalidParameters.new(:webhook_headers) if missing_required_value?
      raise Discourse::InvalidAccess if timestamp_outside_tolerance?

      valid_signature =
        provided_signatures.any? do |provided|
          signature_candidates.any? { |candidate| secure_match?(candidate, provided) }
        end

      raise Discourse::InvalidAccess unless valid_signature

      true
    end

    private

    attr_reader :payload, :webhook_id, :timestamp, :signature, :secret

    def missing_required_value?
      payload.blank? || webhook_id.blank? || timestamp.blank? || signature.blank? || secret.blank?
    end

    def timestamp_outside_tolerance?
      sent_at = Time.zone.at(Integer(timestamp))
      (Time.zone.now - sent_at).abs > TOLERANCE
    rescue ArgumentError
      true
    end

    def signature_candidates
      signed_payload = "#{webhook_id}.#{timestamp}.#{payload}"
      digest = OpenSSL::HMAC.digest("SHA256", secret_bytes, signed_payload)
      hexdigest = OpenSSL::HMAC.hexdigest("SHA256", secret_bytes, signed_payload)
      base64 = Base64.strict_encode64(digest)
      urlsafe_base64 = Base64.urlsafe_encode64(digest, padding: false)

      [hexdigest, base64, urlsafe_base64]
    end

    def provided_signatures
      signature.to_s.split(" ").flat_map do |part|
        version, value = part.split(",", 2)
        value.present? && version.start_with?("v") ? value : part
      end
    end

    def secret_bytes
      return secret unless secret.start_with?("whsec_")

      encoded = secret.delete_prefix("whsec_")
      begin
        Base64.urlsafe_decode64(encoded)
      rescue ArgumentError
        begin
          Base64.decode64(encoded)
        rescue ArgumentError
          secret
        end
      end
    end

    def secure_match?(candidate, provided)
      ActiveSupport::SecurityUtils.secure_compare(candidate, provided.to_s)
    rescue ArgumentError
      false
    end
  end
end
