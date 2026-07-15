# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class AccessManager
    def self.sync!(user:, group_name:)
      new(user: user, group_name: group_name).sync!
    end

    def self.active?(user:, group_name:)
      new(user: user, group_name: group_name).active?
    end

    def initialize(user:, group_name:)
      @user = user
      @group_name = group_name
    end

    def sync!
      return if group.blank?

      active? ? group.add(user) : group.remove(user)
    end

    def active?
      active_subscription? || active_order?
    end

    private

    attr_reader :user, :group_name

    def group
      @group ||= ::Group.find_by_name(group_name)
    end

    def active_subscription?
      Subscription
        .joins(:customer, :product)
        .where(Customer.table_name => { user_id: user.id })
        .where(Product.table_name => { group_name: group_name })
        .where(status: Subscription::GRANTING_STATUSES)
        .exists?
    end

    def active_order?
      Order
        .joins(:product)
        .active_at
        .where(user_id: user.id)
        .where(Product.table_name => { group_name: group_name })
        .exists?
    end
  end
end
