# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class Order < ActiveRecord::Base
    self.table_name = "discourse_dodo_membership_orders"

    SOURCES = %w[dodo manual].freeze
    ACTIVE_STATUSES = %w[succeeded].freeze
    TERMINAL_STATUSES = %w[expired revoked refunded].freeze

    belongs_to :user, class_name: "::User"
    belongs_to :product, class_name: "DiscourseDodoSubscriptions::Product"
    belongs_to :created_by, class_name: "::User", optional: true
    has_many :events,
             class_name: "DiscourseDodoSubscriptions::OrderEvent",
             dependent: :destroy

    scope :active_at,
          lambda { |time = Time.zone.now|
            where(status: ACTIVE_STATUSES).where(
              "starts_at <= ? AND expires_at > ?",
              time,
              time,
            )
          }

    validates :external_id, presence: true, uniqueness: true
    validates :source, inclusion: { in: SOURCES }
    validates :status, inclusion: { in: ACTIVE_STATUSES + TERMINAL_STATUSES }
    validates :amount_cents,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
              },
              allow_nil: true
    validates :starts_at, :expires_at, presence: true
    validate :expires_after_start

    def active?(time = Time.zone.now)
      ACTIVE_STATUSES.include?(status) && starts_at <= time && expires_at > time
    end

    private

    def expires_after_start
      return if starts_at.blank? || expires_at.blank? || expires_at > starts_at

      errors.add(:expires_at, :invalid)
    end
  end
end
