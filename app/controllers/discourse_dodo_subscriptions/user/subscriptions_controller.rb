# frozen_string_literal: true

module DiscourseDodoSubscriptions
  module User
    class SubscriptionsController < ::ApplicationController
      requires_plugin PLUGIN_NAME

      requires_login

      def index
        render_json_dump(subscription_records + order_records)
      end

      private

      def subscription_records
        subscriptions =
          Subscription
            .includes(:product, :customer)
            .joins(:customer)
            .where(Customer.table_name => { user_id: current_user.id })
            .order(created_at: :desc)

        visible_subscription_records(subscriptions).map do |record|
          serialize_subscription(
            record[:subscription],
            duplicate_subscription_count: record[:duplicate_subscription_count],
          )
        end
      end

      def order_records
        orders = Order.includes(:product).where(user_id: current_user.id).order(created_at: :desc)

        orders
          .to_a
          .group_by { |order| [order.product.group_name, order.product.plan_key] }
          .map do |_key, grouped|
            granting =
              grouped.select do |order|
                Order::ACTIVE_STATUSES.include?(order.status) && order.expires_at > Time.zone.now
              end
            order =
              (granting.presence || grouped).max_by do |item|
                [item.expires_at, item.created_at]
              end
            serialize_order(order, active: grouped.any?(&:active?))
          end
      end

      def visible_subscription_records(subscriptions)
        subscriptions
          .to_a
          .group_by do |subscription|
            [subscription.product.group_name, subscription.product.plan_key]
          end
          .flat_map do |_key, grouped|
            product = grouped.first.product

            if product.repurchaseable
              grouped.map do |subscription|
                {
                  subscription: subscription,
                  duplicate_subscription_count: 0,
                }
              end
            else
              [
                {
                  subscription: primary_subscription(grouped),
                  duplicate_subscription_count: duplicate_granting_count(grouped),
                },
              ]
            end
          end
      end

      def primary_subscription(subscriptions)
        subscriptions.max_by do |subscription|
          [
            Subscription::GRANTING_STATUSES.include?(subscription.status.to_s) ? 1 : 0,
            subscription.current_period_end || subscription.created_at || Time.zone.at(0),
            subscription.created_at || Time.zone.at(0),
          ]
        end
      end

      def duplicate_granting_count(subscriptions)
        granting_count =
          subscriptions.count do |subscription|
            Subscription::GRANTING_STATUSES.include?(subscription.status.to_s)
          end

        [granting_count - 1, 0].max
      end

      def serialize_subscription(subscription, duplicate_subscription_count:)
        {
          id: subscription.external_id,
          billing_type: "subscription",
          source: "dodo",
          status: subscription.status,
          current_period_end: subscription.current_period_end,
          cancel_at_period_end: subscription.cancel_at_period_end,
          created_at: subscription.created_at,
          payment_method: nil,
          duplicate_subscription_count: duplicate_subscription_count,
          product: serialize_product(subscription.product),
        }
      end

      def serialize_order(order, active:)
        {
          id: order.external_id,
          billing_type: "one_time",
          source: order.source,
          status: active ? "active" : order.status,
          current_period_end: order.expires_at,
          cancel_at_period_end: false,
          created_at: order.created_at,
          payment_method: order.payment_method,
          duplicate_subscription_count: 0,
          product: serialize_product(order.product),
        }
      end

      def serialize_product(product)
        {
          id: product.external_id,
          name: product.name,
          plan_key: product.plan_key,
          group_name: product.group_name,
          amount_cents: product.amount_cents,
          currency: product.currency,
          recurring_interval: product.recurring_interval,
          billing_type: product.billing_type,
          wechat_pay_enabled: product.wechat_pay_enabled,
        }
      end
    end
  end
end
