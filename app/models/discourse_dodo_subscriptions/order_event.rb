# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class OrderEvent < ActiveRecord::Base
    self.table_name = "discourse_dodo_membership_order_events"

    belongs_to :order, class_name: "DiscourseDodoSubscriptions::Order"
    belongs_to :actor, class_name: "::User", optional: true

    validates :action, :created_at, presence: true
  end
end
