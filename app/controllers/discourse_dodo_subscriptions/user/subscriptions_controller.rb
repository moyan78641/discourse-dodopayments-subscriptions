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
          subscriptions.map { |subscription| serialize_subscription(subscription) },
        )
      end

      private

      def serialize_subscription(subscription)
        product = subscription.product

        {
          id: subscription.external_id,
          status: subscription.status,
          current_period_end: subscription.current_period_end,
          cancel_at_period_end: subscription.cancel_at_period_end,
          created_at: subscription.created_at,
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
