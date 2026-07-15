# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class Product < ActiveRecord::Base
    self.table_name = "discourse_dodo_subscription_products"

    BILLING_TYPES = %w[subscription one_time].freeze
    INTERVAL_MONTHS = {
      "month" => 1,
      "quarter" => 3,
      "half_year" => 6,
      "year" => 12,
    }.freeze
    WECHAT_CURRENCIES = %w[USD CNY].freeze
    WECHAT_MINIMUMS = { "USD" => 50, "CNY" => 100 }.freeze

    scope :published, -> { where(active: true) }

    has_many :subscriptions, dependent: :destroy
    has_many :orders,
             class_name: "DiscourseDodoSubscriptions::Order",
             dependent: :restrict_with_error

    validates :external_id, presence: true, uniqueness: true
    validates :name, :group_name, :plan_key, presence: true
    validates :billing_type, inclusion: { in: BILLING_TYPES }
    validates :recurring_interval, inclusion: { in: INTERVAL_MONTHS.keys }
    validates :position,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
              }
    validate :wechat_pay_configuration

    before_validation :set_defaults

    def subscription?
      billing_type == "subscription"
    end

    def one_time?
      billing_type == "one_time"
    end

    def membership_duration
      INTERVAL_MONTHS.fetch(recurring_interval, 1).months
    end

    def advance_membership_from(time)
      time + membership_duration
    end

    def active_order_for?(user)
      return false if user.blank?

      Order
        .joins(:product)
        .active_at
        .where(user_id: user.id)
        .where(Product.table_name => { group_name: group_name })
        .exists?
    end

    def active_subscription_for?(user)
      return false if user.blank?

      Subscription
        .joins(:customer, :product)
        .where(Customer.table_name => { user_id: user.id })
        .where(Product.table_name => { group_name: group_name })
        .where(status: Subscription::GRANTING_STATUSES)
        .exists?
    end

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

    private

    def set_defaults
      self.plan_key = group_name if plan_key.blank?
      self.recurring_interval = "month" if recurring_interval.blank?
    end

    def wechat_pay_configuration
      return unless wechat_pay_enabled

      errors.add(:wechat_pay_enabled, :invalid) unless one_time?
      errors.add(:currency, :inclusion) unless WECHAT_CURRENCIES.include?(currency)

      minimum = WECHAT_MINIMUMS[currency]
      if minimum && amount_cents.to_i < minimum
        errors.add(:amount_cents, :greater_than_or_equal_to, count: minimum)
      end
    end
  end
end
