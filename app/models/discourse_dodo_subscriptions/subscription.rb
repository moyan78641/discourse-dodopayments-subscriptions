# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class Subscription < ActiveRecord::Base
    self.table_name = "discourse_dodo_subscriptions"

    GRANTING_STATUSES = %w[active renewed].freeze
    REVOKING_STATUSES = %w[cancelled failed expired on_hold paused].freeze

    belongs_to :customer
    belongs_to :product

    validates :external_id, presence: true, uniqueness: true
  end
end
