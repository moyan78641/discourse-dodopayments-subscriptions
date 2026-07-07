# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class PendingCheckout
    TTL = 15.minutes
    KEY_PREFIX = "discourse_dodo_subscriptions:pending_checkout"
    PENDING_VALUE = "pending"
    URL_PREFIX = "url:"

    def self.reserve(user:, product:)
      Discourse.redis.set(redis_key(user, product), PENDING_VALUE, nx: true, ex: TTL.to_i)
    end

    def self.checkout_url(user:, product:)
      value = Discourse.redis.get(redis_key(user, product))
      return if value.blank? || !value.start_with?(URL_PREFIX)

      value.delete_prefix(URL_PREFIX)
    end

    def self.store_checkout_url(user:, product:, url:)
      Discourse.redis.setex(redis_key(user, product), TTL.to_i, "#{URL_PREFIX}#{url}")
    end

    def self.clear(user:, product:)
      Discourse.redis.del(redis_key(user, product))
    end

    def self.redis_key(user, product)
      "#{KEY_PREFIX}:#{user.id}:#{product.id}"
    end
    private_class_method :redis_key
  end
end
