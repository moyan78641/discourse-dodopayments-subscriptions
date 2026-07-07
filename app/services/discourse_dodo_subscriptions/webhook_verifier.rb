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
      secret_candidates.flat_map do |candidate_secret|
        digest = OpenSSL::HMAC.digest("SHA256", candidate_secret, signed_payload)
        hexdigest = OpenSSL::HMAC.hexdigest("SHA256", candidate_secret, signed_payload)
        base64 = Base64.strict_encode64(digest)
        urlsafe_base64 = Base64.urlsafe_encode64(digest, padding: false)

        [hexdigest, base64, urlsafe_base64]
      end.uniq
    end

    def provided_signatures
      signature.to_s.split(" ").flat_map do |part|
        version, value = part.split(",", 2)
        value.present? && version.start_with?("v") ? value : part
      end
    end

    def secret_candidates
      candidates = [secret]
      decoded_secret = decode_standard_webhook_secret
      candidates.unshift(decoded_secret) if decoded_secret&.bytesize&.positive?

      candidates.uniq
    end

    def decode_standard_webhook_secret
      return unless secret.start_with?("whsec_")

      encoded = secret.delete_prefix("whsec_")
      padded = encoded.ljust((encoded.length + 3) / 4 * 4, "=")

      [encoded, padded].each do |value|
        decoded = decode_base64_secret(value)
        return decoded if decoded.present?
      end

      nil
    end

    def decode_base64_secret(value)
      [
        -> { Base64.urlsafe_decode64(value) },
        -> { Base64.strict_decode64(value) },
        -> { Base64.decode64(value) },
      ].each do |decoder|
        decoded = decoder.call
        return decoded if decoded.bytesize.positive?
      rescue ArgumentError
        next
      end

      nil
    end

    def secure_match?(candidate, provided)
      ActiveSupport::SecurityUtils.secure_compare(candidate, provided.to_s)
    rescue ArgumentError
      false
    end
  end
end
