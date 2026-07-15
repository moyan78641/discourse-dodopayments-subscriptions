# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class WebhookProcessor
    SUBSCRIPTION_GRANT_EVENTS = %w[
      subscription.active
      subscription.renewed
      subscription.updated
      subscription.plan_changed
    ].freeze
    SUBSCRIPTION_REVOKE_EVENTS = %w[
      subscription.cancelled
      subscription.failed
      subscription.expired
      subscription.on_hold
      subscription.paused
    ].freeze
    PAYMENT_EVENTS = %w[payment.succeeded].freeze
    REFUND_EVENTS = %w[refund.succeeded].freeze
    HANDLED_EVENTS =
      (SUBSCRIPTION_GRANT_EVENTS + SUBSCRIPTION_REVOKE_EVENTS + PAYMENT_EVENTS + REFUND_EVENTS).freeze

    def self.process!(event:)
      new(event: event).process!
    end

    def initialize(event:)
      @event = event.with_indifferent_access
      @data = @event[:data].to_h.with_indifferent_access
    end

    def process!
      return unless HANDLED_EVENTS.include?(event_type)

      return process_payment! if payment_event?
      return process_refund! if refund_event?

      process_subscription!
    end

    private

    attr_reader :event, :data

    def event_type
      event[:type].to_s
    end

    def payment_event?
      PAYMENT_EVENTS.include?(event_type)
    end

    def refund_event?
      REFUND_EVENTS.include?(event_type)
    end

    def process_payment!
      return if data[:subscription_id].present?

      product = find_product
      if product.blank?
        raise Discourse::NotFound, I18n.t("discourse_dodo_subscriptions.webhook_product_not_found")
      end
      return unless product.one_time?

      user = trusted_user || existing_order&.user
      validate_user!(user)

      order =
        OrderManager.open!(
          user: user,
          product: product,
          external_id: payment_id,
          source: "dodo",
          amount_cents: data[:total_amount],
          currency: data[:currency],
          payment_method: data[:payment_method_type].presence || data[:payment_method],
          metadata: data.to_h,
        )
      PendingCheckout.clear(user: user, product: product)
      order
    end

    def process_subscription!
      product = find_product
      raise Discourse::NotFound, I18n.t("discourse_dodo_subscriptions.webhook_product_not_found") if product.blank?
      return unless product.subscription?

      user = trusted_user || existing_subscription&.customer&.user
      validate_user!(user)

      customer = upsert_customer!(user)
      previous_product = existing_subscription&.product
      subscription = upsert_subscription!(customer, product)
      PendingCheckout.clear(user: user, product: product)

      AccessManager.sync!(user: user, group_name: product.group_name)
      if Subscription::GRANTING_STATUSES.include?(subscription.status.to_s)
        MembershipNotifier.subscription_opened!(subscription)
      end
      if previous_product && previous_product.group_name != product.group_name
        AccessManager.sync!(user: user, group_name: previous_product.group_name)
      end

      subscription
    end

    def process_refund!
      return if data[:is_partial]

      order = existing_order
      return if order.blank? || order.status == "refunded"

      order.update!(status: "refunded")
      order.events.create!(
        action: "refunded",
        details: { refund_id: data[:refund_id], amount: data[:amount], reason: data[:reason] },
        created_at: Time.zone.now,
      )
      AccessManager.sync!(user: order.user, group_name: order.product.group_name)
      order
    end

    def validate_user!(user)
      raise Discourse::InvalidAccess, I18n.t("discourse_dodo_subscriptions.webhook_missing_user") if user.blank?
      return if customer_email.blank? || email_belongs_to_user?(user)

      raise Discourse::InvalidAccess, I18n.t("discourse_dodo_subscriptions.webhook_email_mismatch")
    end

    def upsert_customer!(user)
      customer_data = data[:customer].to_h.with_indifferent_access
      external_customer_id =
        customer_data[:customer_id].presence || data[:customer_id].presence ||
          "unknown:#{user.id}:#{subscription_id}"

      Customer.find_or_initialize_by(user_id: user.id, external_id: external_customer_id).tap do |customer|
        customer.email = customer_email
        customer.save!
      end
    end

    def upsert_subscription!(customer, product)
      Subscription.find_or_initialize_by(external_id: subscription_id).tap do |subscription|
        subscription.customer = customer
        subscription.product = product
        subscription.status = data[:status].presence || event_type.delete_prefix("subscription.")
        subscription.current_period_end = parse_time(data[:next_billing_date] || data[:expires_at])
        subscription.cancel_at_period_end = !!data[:cancel_at_next_billing_date]
        subscription.save!
      end
    end

    def trusted_user
      reference = metadata[:discourse_user_reference]
      return if reference.blank?

      ::User.find_signed(
        reference,
        purpose: DiscourseDodoSubscriptions::CHECKOUT_USER_REFERENCE_PURPOSE,
      )
    end

    def email_belongs_to_user?(user)
      ::UserEmail.exists?(user_id: user.id, email: ::Email.downcase(customer_email))
    end

    def metadata
      data[:metadata].to_h.with_indifferent_access
    end

    def customer_email
      data.dig(:customer, :email).presence || data[:customer_email].presence || metadata[:email].presence
    end

    def find_product
      local_id = metadata[:discourse_product_id]
      return Product.find_by(id: local_id) if local_id.present?

      Product.find_by(external_id: product_id)
    end

    def product_id
      metadata[:dodo_product_id].presence || data[:product_id].presence ||
        data[:product_cart].to_a.first.to_h.with_indifferent_access[:product_id].presence ||
        existing_subscription&.product&.external_id || existing_order&.product&.external_id
    end

    def payment_id
      data[:payment_id].presence || data[:id].presence
    end

    def subscription_id
      data[:subscription_id].presence || data[:id].presence
    end

    def existing_order
      return if payment_id.blank?

      @existing_order ||= Order.includes(:user, :product).find_by(external_id: payment_id)
    end

    def existing_subscription
      return if subscription_id.blank?

      @existing_subscription ||= Subscription.includes(:product, customer: :user).find_by(
        external_id: subscription_id,
      )
    end

    def parse_time(value)
      return if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
