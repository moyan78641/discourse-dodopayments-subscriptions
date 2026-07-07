# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class WebhookProcessor
    GRANT_EVENTS = %w[
      subscription.active
      subscription.renewed
      subscription.updated
      subscription.plan_changed
    ].freeze
    REVOKE_EVENTS = %w[
      subscription.cancelled
      subscription.failed
      subscription.expired
      subscription.on_hold
    ].freeze
    HANDLED_EVENTS = (GRANT_EVENTS + REVOKE_EVENTS).freeze

    def self.process!(event:)
      new(event: event).process!
    end

    def initialize(event:)
      @event = event.with_indifferent_access
      @data = @event[:data].to_h.with_indifferent_access
    end

    def process!
      return unless HANDLED_EVENTS.include?(event_type)

      product = Product.published.find_by(external_id: product_id)
      raise Discourse::NotFound, I18n.t("discourse_dodo_subscriptions.webhook_product_not_found") if product.blank?

      user = trusted_user || existing_user
      raise Discourse::InvalidAccess, I18n.t("discourse_dodo_subscriptions.webhook_missing_user") if user.blank?
      if customer_email.present? && !email_belongs_to_user?(user)
        raise Discourse::InvalidAccess, I18n.t("discourse_dodo_subscriptions.webhook_email_mismatch")
      end

      customer = upsert_customer!(user)
      previous_product = existing_subscription&.product
      subscription = upsert_subscription!(customer, product)
      PendingCheckout.clear(user: user, product: product)

      if grant_event?
        if previous_product && previous_product.id != product.id &&
             !active_subscription_exists_for?(user, previous_product)
          Entitlement.revoke!(user: user, product: previous_product)
        end
        Entitlement.grant!(user: user, product: product)
      elsif revoke_event? && !active_subscription_exists_for?(user, product)
        Entitlement.revoke!(user: user, product: product)
      end

      subscription
    end

    private

    attr_reader :event, :data

    def event_type
      event[:type]
    end

    def grant_event?
      GRANT_EVENTS.include?(event_type) && Subscription::GRANTING_STATUSES.include?(data[:status].to_s)
    end

    def revoke_event?
      REVOKE_EVENTS.include?(event_type) || Subscription::REVOKING_STATUSES.include?(data[:status].to_s)
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

    def existing_user
      user_id = existing_subscription&.customer&.user_id
      ::User.find_by(id: user_id) if user_id
    end

    def email_belongs_to_user?(user)
      email = customer_email
      ::UserEmail.exists?(user_id: user.id, email: ::Email.downcase(email))
    end

    def metadata
      data[:metadata].to_h.with_indifferent_access
    end

    def customer_email
      data.dig(:customer, :email).presence || data[:customer_email].presence || metadata[:email].presence
    end

    def product_id
      data[:product_id].presence || metadata[:dodo_product_id].presence ||
        existing_subscription&.product&.external_id
    end

    def subscription_id
      data[:subscription_id].presence || data[:id].presence
    end

    def existing_subscription
      return if subscription_id.blank?

      @existing_subscription ||= Subscription.includes(:customer, :product).find_by(
        external_id: subscription_id,
      )
    end

    def active_subscription_exists_for?(user, product)
      Subscription
        .joins(:customer)
        .where(
          product_id: product.id,
          Customer.table_name => {
            user_id: user.id,
          },
        )
        .where(status: Subscription::GRANTING_STATUSES)
        .exists?
    end

    def parse_time(value)
      return if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
