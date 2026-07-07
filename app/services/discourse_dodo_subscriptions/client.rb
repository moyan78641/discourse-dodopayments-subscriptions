# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module DiscourseDodoSubscriptions
  class Client
    class Error < StandardError
      attr_reader :status, :body

      def initialize(message, status: nil, body: nil)
        super(message)
        @status = status
        @body = body
      end
    end

    LIVE_BASE_URL = "https://live.dodopayments.com"
    TEST_BASE_URL = "https://test.dodopayments.com"

    def create_checkout(product:, user:, return_url:, cancel_url: nil)
      post(
        "/checkouts",
        {
          product_cart: [{ product_id: product.external_id, quantity: 1 }],
          customer: {
            email: user.email,
            name: user.name.presence || user.username,
          },
          metadata: checkout_metadata(product, user),
          return_url: return_url,
          cancel_url: cancel_url,
          minimal_address: true,
        }.compact,
      )
    end

    private

    def checkout_metadata(product, user)
      {
        discourse_user_reference: user.signed_id(
          expires_in: DiscourseDodoSubscriptions::CHECKOUT_USER_REFERENCE_EXPIRES_IN,
          purpose: DiscourseDodoSubscriptions::CHECKOUT_USER_REFERENCE_PURPOSE,
        ),
        discourse_user_id: user.id.to_s,
        discourse_username: user.username_lower,
        discourse_product_id: product.id.to_s,
        dodo_product_id: product.external_id,
      }
    end

    def post(path, body)
      uri = URI.join("#{base_url}/", path.delete_prefix("/"))
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{SiteSetting.discourse_dodo_subscriptions_api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.dump(body)

      response = perform(uri, request)
      parsed = JSON.parse(response.body.presence || "{}", symbolize_names: true)

      unless response.is_a?(Net::HTTPSuccess)
        raise Error.new("Dodo Payments API request failed", status: response.code, body: parsed)
      end

      parsed
    rescue JSON::ParserError => e
      raise Error.new("Invalid Dodo Payments API response: #{e.message}")
    end

    def perform(uri, request)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
    end

    def base_url
      override = SiteSetting.discourse_dodo_subscriptions_base_url
      return override if override.present?

      SiteSetting.discourse_dodo_subscriptions_environment == "live" ? LIVE_BASE_URL : TEST_BASE_URL
    end
  end
end
