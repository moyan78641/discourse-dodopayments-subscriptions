# frozen_string_literal: true

module DiscourseDodoSubscriptions
  module Admin
    class OrdersController < ::Admin::AdminController
      requires_plugin PLUGIN_NAME

      def index
        orders = filtered_orders.limit(250)
        render_json_dump(
          orders: orders.map { |order| serialize_order(order) },
          subscriptions:
            filtered_subscriptions.limit(250).map do |subscription|
              serialize_subscription(subscription)
            end,
          summary: summary,
          products:
            Product
              .published
              .where(billing_type: "one_time")
              .order(:position, :id)
              .map { |product| serialize_product(product) },
        )
      end

      def create
        user = ::User.find_by_username_or_email(params.require(:username_or_email))
        raise Discourse::NotFound, "User not found" if user.blank?

        product = Product.published.find(params.require(:product_id))
        raise Discourse::InvalidParameters.new(:product_id) unless product.one_time?

        order =
          OrderManager.open!(
            user: user,
            product: product,
            external_id: "manual_#{SecureRandom.hex(12)}",
            source: "manual",
            amount_cents: params[:amount_cents],
            currency: params[:currency],
            payment_method: params[:payment_method].presence || "manual",
            actor: current_user,
            note: params[:note],
            duration_days: positive_integer_param(:duration_days),
            notify_user: boolean_param(:notify_user, default: true),
          )

        render_json_dump serialize_order(order)
      end

      def update
        order = Order.includes(:user, :product, :created_by).find(params[:id])

        case params.require(:operation)
        when "extend"
          order = extend_order(order)
        when "set_expiry"
          expires_at = Time.zone.parse(params.require(:expires_at).to_s)
          raise Discourse::InvalidParameters.new(:expires_at) if expires_at.blank?

          order =
            OrderManager.set_expiry!(
              order: order,
              expires_at: expires_at,
              actor: current_user,
              note: params[:note],
              notify_user: boolean_param(:notify_user),
            )
        when "revoke"
          order =
            OrderManager.revoke!(
              order: order,
              actor: current_user,
              note: params[:note],
              notify_user: boolean_param(:notify_user),
            )
        else
          raise Discourse::InvalidParameters.new(:operation)
        end

        render_json_dump serialize_order(order.reload)
      rescue ArgumentError
        raise Discourse::InvalidParameters.new(:expires_at)
      end

      private

      def filtered_orders
        scope = Order.includes(:user, :product, :created_by).order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(source: params[:source]) if params[:source].present?
        if params[:q].present?
          scope = scope.where(user_id: matching_user_ids)
        end
        scope
      end

      def summary
        {
          active: Order.active_at.count,
          expiring_soon: Order.active_at.where("expires_at <= ?", 7.days.from_now).count,
          expired: Order.where(status: "expired").count,
          manual: Order.where(source: "manual").count,
          subscriptions: Subscription.where(status: Subscription::GRANTING_STATUSES).count,
        }
      end

      def filtered_subscriptions
        return Subscription.none if params[:source] == "manual"

        scope = Subscription.includes(:product, customer: :user).order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        if params[:q].present?
          scope =
            scope
              .joins(:customer)
              .where(Customer.table_name => { user_id: matching_user_ids })
        end
        scope
      end

      def extend_order(order)
        OrderManager.open!(
          user: order.user,
          product: order.product,
          external_id: "manual_#{SecureRandom.hex(12)}",
          source: "manual",
          payment_method: "manual_extension",
          actor: current_user,
          note: params[:note],
          duration_days: positive_integer_param(:duration_days),
          notify_user: boolean_param(:notify_user),
        )
      end

      def positive_integer_param(key)
        return if params[key].blank?

        number = Integer(params[key], exception: false)
        raise Discourse::InvalidParameters.new(key) unless number&.positive?

        number
      end

      def matching_user_ids
        term = params[:q].to_s.strip
        return [] if term.blank?

        pattern = "%#{term}%"
        user_ids = ::User.where("username ILIKE ?", pattern).pluck(:id)
        user_ids.concat(::UserEmail.where("email ILIKE ?", pattern).pluck(:user_id)).uniq
      end

      def boolean_param(key, default: false)
        return default unless params.key?(key)

        ActiveModel::Type::Boolean.new.cast(params[key])
      end

      def serialize_order(order)
        {
          id: order.id,
          external_id: order.external_id,
          source: order.source,
          status: order.status,
          amount_cents: order.amount_cents,
          currency: order.currency,
          payment_method: order.payment_method,
          starts_at: order.starts_at,
          expires_at: order.expires_at,
          note: order.note,
          created_at: order.created_at,
          user: { id: order.user.id, username: order.user.username, email: order.user.email },
          product: serialize_product(order.product),
          created_by:
            order.created_by &&
              {
                id: order.created_by.id,
                username: order.created_by.username,
              },
          events: order.events.order(created_at: :desc).limit(20).map do |event|
            {
              action: event.action,
              actor_id: event.actor_id,
              details: event.details,
              created_at: event.created_at,
            }
          end,
        }
      end

      def serialize_subscription(subscription)
        {
          id: subscription.id,
          external_id: subscription.external_id,
          status: subscription.status,
          current_period_end: subscription.current_period_end,
          cancel_at_period_end: subscription.cancel_at_period_end,
          created_at: subscription.created_at,
          user: {
            id: subscription.customer.user.id,
            username: subscription.customer.user.username,
            email: subscription.customer.user.email,
          },
          product: serialize_product(subscription.product),
        }
      end

      def serialize_product(product)
        {
          id: product.id,
          name: product.name,
          plan_key: product.plan_key,
          recurring_interval: product.recurring_interval,
          amount_cents: product.amount_cents,
          currency: product.currency,
        }
      end
    end
  end
end
