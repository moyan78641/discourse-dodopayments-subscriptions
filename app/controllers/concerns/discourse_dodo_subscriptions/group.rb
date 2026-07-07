# frozen_string_literal: true

module DiscourseDodoSubscriptions
  module Group
    extend ActiveSupport::Concern

    def product_group(product)
      ::Group.find_by_name(product.group_name)
    end
  end
end
