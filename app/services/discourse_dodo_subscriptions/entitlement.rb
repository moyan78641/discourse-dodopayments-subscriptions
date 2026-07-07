# frozen_string_literal: true

module DiscourseDodoSubscriptions
  class Entitlement
    def self.grant!(user:, product:)
      new(user: user, product: product).grant!
    end

    def self.revoke!(user:, product:)
      new(user: user, product: product).revoke!
    end

    def initialize(user:, product:)
      @user = user
      @product = product
    end

    def grant!
      group&.add(user)
    end

    def revoke!
      group&.remove(user)
    end

    private

    attr_reader :user, :product

    def group
      @group ||= ::Group.find_by_name(product.group_name)
    end
  end
end
