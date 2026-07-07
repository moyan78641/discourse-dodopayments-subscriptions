# frozen_string_literal: true

module DiscourseDodoSubscriptions
  module Dodo
    extend ActiveSupport::Concern

    def dodo_configured?
      SiteSetting.discourse_dodo_subscriptions_api_key.present?
    end

    def dodo_client
      DiscourseDodoSubscriptions::Client.new
    end
  end
end
