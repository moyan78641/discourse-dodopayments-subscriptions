# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class HooksController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    layout false

    skip_before_action :check_xhr
    skip_before_action :redirect_to_login_if_required
    skip_before_action :verify_authenticity_token, only: [:create]

    def create
      secret = SiteSetting.discourse_dodo_subscriptions_webhook_secret
      return head :forbidden if secret.blank?

      payload = request.body.read
      webhook_id = request.headers["webhook-id"]
      timestamp = request.headers["webhook-timestamp"]
      signature = request.headers["webhook-signature"]

      DiscourseDodoSubscriptions::WebhookVerifier.verify!(
        payload: payload,
        webhook_id: webhook_id,
        timestamp: timestamp,
        signature: signature,
        secret: secret,
      )

      event = JSON.parse(payload)
      webhook_event = WebhookEvent.find_or_initialize_by(external_id: webhook_id)
      return head :ok if webhook_event.persisted? && webhook_event.status == "processed"

      webhook_event.event_type = event["type"].to_s
      webhook_event.payload = event
      webhook_event.status = "received"
      webhook_event.save!

      WebhookProcessor.process!(event: event)

      webhook_event.update!(status: "processed", processed_at: Time.zone.now, error: nil)
      head :ok
    rescue JSON::ParserError => e
      render_json_error e.message
    rescue Discourse::InvalidParameters
      render_json_error I18n.t("discourse_dodo_subscriptions.webhook_missing_headers"),
                        status: :forbidden
    rescue Discourse::InvalidAccess => e
      render_json_error(e.message.presence || I18n.t("discourse_dodo_subscriptions.webhook_invalid_signature"),
                        status: :forbidden)
    rescue Discourse::NotFound => e
      mark_failed_webhook(webhook_id, e)
      render_json_error e.message
    rescue StandardError => e
      mark_failed_webhook(webhook_id, e)
      raise
    end

    private

    def mark_failed_webhook(webhook_id, error)
      return if webhook_id.blank?

      WebhookEvent.where(external_id: webhook_id).update_all(
        status: "failed",
        error: error.message,
        updated_at: Time.zone.now,
      )
    end
  end
end
