# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class SubscribeController < ::ApplicationController
    include DiscourseDodoSubscriptions::Dodo

    requires_plugin PLUGIN_NAME

    requires_login except: %i[index show success]

    def index
      products = Product.published.order(:position, :id).map { |product| serialize_product(product) }
      render_json_dump products
    end

    def show
      product = Product.published.find_by(external_id: params[:id])
      raise Discourse::NotFound, I18n.t("discourse_dodo_subscriptions.product_not_found") if product.blank?

      render_json_dump serialize_product(product)
    end

    def success
      render_json_dump success: true
    end

    def create_checkout
      params.require(:product_id)

      raise Discourse::InvalidAccess unless dodo_configured?

      product = Product.published.find_by(external_id: params[:product_id])
      raise Discourse::NotFound, I18n.t("discourse_dodo_subscriptions.product_not_found") if product.blank?

      if product.subscription? && !product.repurchaseable && product.subscribed_by?(current_user)
        return render_json_dump subscribed: true
      end

      conflict = purchase_conflict(product)
      return render_json_dump conflict: conflict if conflict.present?

      if product.one_time? || !product.repurchaseable
        pending_checkout_url =
          DiscourseDodoSubscriptions::PendingCheckout.checkout_url(
            user: current_user,
            product: product,
          )
        return render_json_dump checkout_url: pending_checkout_url if pending_checkout_url.present?

        unless DiscourseDodoSubscriptions::PendingCheckout.reserve(user: current_user, product: product)
          return render_json_dump pending: true
        end
      end

      checkout =
        dodo_client.create_checkout(
          product: product,
          user: current_user,
          return_url: "#{Discourse.base_url}/subscribe/success",
          cancel_url: "#{Discourse.base_url}/subscribe",
        )

      url = checkout_url(checkout)
      raise DiscourseDodoSubscriptions::Client::Error.new("Missing checkout_url") if url.blank?

      DiscourseDodoSubscriptions::PendingCheckout.store_checkout_url(
        user: current_user,
        product: product,
        url: url,
      ) if product.one_time? || !product.repurchaseable

      render_json_dump checkout_url: url
    rescue DiscourseDodoSubscriptions::Client::Error => e
      DiscourseDodoSubscriptions::PendingCheckout.clear(user: current_user, product: product) if product
      Rails.logger.warn("Dodo checkout failed: #{e.message} #{e.body}") if verbose_logging?
      render_json_error I18n.t("discourse_dodo_subscriptions.checkout_failed")
    end

    private

    def serialize_product(product)
      {
        id: product.external_id,
        name: product.name,
        description: PrettyText.cook(product.description.to_s),
        amount_cents: product.amount_cents,
        currency: product.currency,
        recurring_interval: product.recurring_interval,
        billing_type: product.billing_type,
        plan_key: product.plan_key,
        wechat_pay_enabled: product.wechat_pay_enabled,
        conflict: purchase_conflict(product),
        subscribed: product.subscribed_by?(current_user),
        repurchaseable: product.repurchaseable,
      }
    end

    def checkout_url(checkout)
      checkout[:checkout_url].presence || checkout[:url].presence || checkout.dig(:data, :checkout_url)
    end

    def verbose_logging?
      SiteSetting.discourse_dodo_subscriptions_enable_verbose_logging
    end

    def purchase_conflict(product)
      return if current_user.blank?
      return "active_subscription" if product.one_time? && product.active_subscription_for?(current_user)
      return "active_one_time" if product.subscription? && product.active_order_for?(current_user)
    end
  end
end
