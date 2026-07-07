# frozen_string_literal: true

# name: discourse-dodopayments-subscriptions
# about: Sell Dodo Payments subscriptions that grant access to Discourse groups.
# version: 0.1.0
# authors: Codex
# url: https://github.com/discourse/discourse

enabled_site_setting :discourse_dodo_subscriptions_enabled

register_asset "stylesheets/common/main.scss"
register_svg_icon "credit-card"

add_admin_route "discourse_dodo_subscriptions.admin_navigation", "discourse-dodo-subscriptions.products"

Discourse::Application.routes.append do
  get "/admin/plugins/discourse-dodo-subscriptions" => "admin/plugins#index",
      constraints: AdminConstraint.new
  get "/admin/plugins/discourse-dodo-subscriptions/products" => "admin/plugins#index",
      constraints: AdminConstraint.new
end

module ::DiscourseDodoSubscriptions
  PLUGIN_NAME = "discourse-dodopayments-subscriptions"
  CHECKOUT_USER_REFERENCE_PURPOSE = "dodo_checkout_user"
  CHECKOUT_USER_REFERENCE_EXPIRES_IN = 30.days
end

require_relative "lib/discourse_dodo_subscriptions/engine"
require_relative "app/controllers/concerns/discourse_dodo_subscriptions/dodo"
require_relative "app/controllers/concerns/discourse_dodo_subscriptions/group"

after_initialize do
  Discourse::Application.routes.append { mount DiscourseDodoSubscriptions::Engine, at: "subscribe" }

  add_to_serializer(
    :current_user,
    :discourse_dodo_subscriptions_checkout_user_reference,
    include_condition: -> { SiteSetting.discourse_dodo_subscriptions_enabled },
  ) do
    object.signed_id(
      expires_in: DiscourseDodoSubscriptions::CHECKOUT_USER_REFERENCE_EXPIRES_IN,
      purpose: DiscourseDodoSubscriptions::CHECKOUT_USER_REFERENCE_PURPOSE,
    )
  end
end
