# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class Customer < ActiveRecord::Base
    self.table_name = "discourse_dodo_subscription_customers"

    belongs_to :user, class_name: "::User"
    has_many :subscriptions, dependent: :destroy

    validates :user_id, :external_id, presence: true
  end
end
