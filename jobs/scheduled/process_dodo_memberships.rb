# frozen_string_literal: true

module Jobs
  class ProcessDodoMemberships < ::Jobs::Scheduled
    every 1.hour

    def execute(_args)
      return unless SiteSetting.discourse_dodo_subscriptions_enabled

      now = Time.zone.now
      expire_orders(now)
      send_expiry_reminders(now)
    end

    private

    def expire_orders(now)
      DiscourseDodoSubscriptions::Order
        .where(status: DiscourseDodoSubscriptions::Order::ACTIVE_STATUSES)
        .where("expires_at <= ?", now)
        .includes(:user, :product)
        .find_each do |order|
          expired = false
          order.with_lock do
            active_statuses = DiscourseDodoSubscriptions::Order::ACTIVE_STATUSES
            next unless active_statuses.include?(order.status)
            next unless order.expires_at <= now

            order.update!(status: "expired")
            order.events.create!(action: "expired", details: {}, created_at: now)
            expired = true
          end
          next unless expired

          DiscourseDodoSubscriptions::AccessManager.sync!(
            user: order.user,
            group_name: order.product.group_name,
          )

          unless DiscourseDodoSubscriptions::AccessManager.active?(
                   user: order.user,
                   group_name: order.product.group_name,
                 )
            DiscourseDodoSubscriptions::MembershipNotifier.expired!(order)
          end
        end
    end

    def send_expiry_reminders(now)
      reminder_days = parsed_reminder_days
      return if reminder_days.empty?

      candidates =
        DiscourseDodoSubscriptions::Order
          .where(status: DiscourseDodoSubscriptions::Order::ACTIVE_STATUSES)
          .where("expires_at > ?", now)
          .includes(:user, :product)

      candidates
        .group_by { |order| [order.user_id, order.product.group_name] }
        .each_value do |orders|
          order = orders.max_by(&:expires_at)
          days = (order.expires_at.to_date - Time.zone.today).to_i
          next unless reminder_days.include?(days)

          DiscourseDodoSubscriptions::MembershipNotifier.expiry_reminder!(order, days: days)
        end
    end

    def parsed_reminder_days
      SiteSetting.discourse_dodo_subscriptions_reminder_days
        .to_s
        .split(",")
        .filter_map { |value| Integer(value.strip, exception: false) }
        .select(&:positive?)
        .uniq
        .sort
    end
  end
end
