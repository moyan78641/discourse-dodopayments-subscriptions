# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class MembershipNotifier
    def self.purchase_opened!(order, force: false)
      return unless force || SiteSetting.discourse_dodo_subscriptions_notify_on_purchase

      order.with_lock do
        return if order.opened_notified_at.present? && !force

        send_message(order, :dodo_membership_opened)
        order.update_column(:opened_notified_at, Time.zone.now)
      end
    end

    def self.expiry_reminder!(order, days:)
      order.with_lock do
        sent = Array(order.reminders_sent).map(&:to_i)
        return if sent.include?(days.to_i)

        send_message(order, :dodo_membership_expiry_reminder, days: days)
        order.update_column(:reminders_sent, (sent + [days.to_i]).uniq.sort.reverse)
      end
    end

    def self.expired!(order)
      return unless SiteSetting.discourse_dodo_subscriptions_notify_on_expiration

      order.with_lock do
        return if order.expired_notified_at.present?

        send_message(order, :dodo_membership_expired)
        order.update_column(:expired_notified_at, Time.zone.now)
      end
    end

    def self.subscription_opened!(subscription)
      return unless SiteSetting.discourse_dodo_subscriptions_notify_on_purchase

      subscription.with_lock do
        return if subscription.opened_notified_at.present?

        user = subscription.customer.user
        SystemMessage.create_from_system_user(
          user,
          :dodo_subscription_opened,
          plan_name: subscription.product.name,
          renews_at: localized_time(user, subscription.current_period_end),
          membership_url: "#{Discourse.base_url}/u/#{user.username}/billing/subscriptions",
        )
        subscription.update_column(:opened_notified_at, Time.zone.now)
      end
    end

    def self.send_message(order, type, days: nil)
      SystemMessage.create_from_system_user(
        order.user,
        type,
        plan_name: order.product.name,
        expires_at: localized_time(order.user, order.expires_at),
        days: days,
        renew_url: "#{Discourse.base_url}/subscribe",
      )
    end
    private_class_method :send_message

    def self.localized_time(user, time)
      return "-" if time.blank?

      I18n.with_locale(user.effective_locale) { I18n.l(time, format: :long) }
    end
    private_class_method :localized_time
  end
end
