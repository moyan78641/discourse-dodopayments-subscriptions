# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class SubscribeController < ::ApplicationController
    include DiscourseDodoSubscriptions::Dodo

    requires_plugin PLUGIN_NAME

    requires_login except: %i[index show success]

    def index
      products = Product.published.order(:id).map { |product| serialize_product(product) }
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

      if !product.repurchaseable && product.subscribed_by?(current_user)
        return render_json_dump subscribed: true
      end

      checkout =
        dodo_client.create_checkout(
          product: product,
          user: current_user,
          return_url: "#{Discourse.base_url}/subscribe/success",
          cancel_url: "#{Discourse.base_url}/subscribe/#{product.external_id}",
        )

      url = checkout_url(checkout)
      raise DiscourseDodoSubscriptions::Client::Error.new("Missing checkout_url") if url.blank?

      render_json_dump checkout_url: url
    rescue DiscourseDodoSubscriptions::Client::Error => e
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
  end
end
