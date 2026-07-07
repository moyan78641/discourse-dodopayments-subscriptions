# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class Product < ActiveRecord::Base
    self.table_name = "discourse_dodo_subscription_products"

    scope :published, -> { where(active: true) }

    has_many :subscriptions, dependent: :destroy

    validates :external_id, presence: true, uniqueness: true
    validates :name, :group_name, presence: true

    def subscribed_by?(user)
      return false if user.blank?

      Subscription
        .joins(:customer)
        .where(
          product_id: id,
          Customer.table_name => {
            user_id: user.id,
          },
        )
        .where(status: Subscription::GRANTING_STATUSES)
        .exists?
    end
  end
end
