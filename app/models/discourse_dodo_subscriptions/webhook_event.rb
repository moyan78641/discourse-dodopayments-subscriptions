# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class WebhookEvent < ActiveRecord::Base
    self.table_name = "discourse_dodo_webhook_events"

    validates :external_id, :event_type, :status, presence: true
    validates :external_id, uniqueness: true
  end
end
