# frozen_string_literal: true

module DiscourseDodoSubscriptions
  module User
    class SubscriptionsController < ::ApplicationController
      requires_plugin PLUGIN_NAME

      requires_login

      def index
        subscriptions =
          Subscription
            .includes(:product, :customer)
            .joins(:customer)
            .where(Customer.table_name => { user_id: current_user.id })
            .order(created_at: :desc)

        render_json_dump(
          visible_subscription_records(subscriptions).map do |record|
            serialize_subscription(
              record[:subscription],
              duplicate_subscription_count: record[:duplicate_subscription_count],
            )
          end,
        )
      end

      private

      def visible_subscription_records(subscriptions)
        subscriptions.to_a.group_by(&:product_id).flat_map do |_product_id, product_subscriptions|
          product = product_subscriptions.first.product

          if product.repurchaseable
            product_subscriptions.map do |subscription|
              { subscription: subscription, duplicate_subscription_count: 0 }
            end
          else
            [
              {
                subscription: primary_subscription(product_subscriptions),
                duplicate_subscription_count: duplicate_granting_count(product_subscriptions),
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
        product = subscription.product

        {
          id: subscription.external_id,
          status: subscription.status,
          current_period_end: subscription.current_period_end,
          cancel_at_period_end: subscription.cancel_at_period_end,
          created_at: subscription.created_at,
          duplicate_subscription_count: duplicate_subscription_count,
          product: {
            id: product.external_id,
            name: product.name,
            group_name: product.group_name,
            amount_cents: product.amount_cents,
            currency: product.currency,
            recurring_interval: product.recurring_interval,
          },
        }
      end
    end
  end
end
