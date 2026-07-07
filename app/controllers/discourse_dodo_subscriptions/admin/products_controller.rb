# frozen_string_literal: true

module DiscourseDodoSubscriptions
  module Admin
    class ProductsController < ::Admin::AdminController
      requires_plugin PLUGIN_NAME

      def index
        render_json_dump Product.order(:id).map { |product| serialize_product(product) }
      end

      def show
        render_json_dump serialize_product(find_product)
      end

      def create
        product = Product.create!(product_params)
        render_json_dump serialize_product(product)
      end

      def update
        product = find_product
        product.update!(product_params)
        render_json_dump serialize_product(product)
      end

      def destroy
        product = find_product
        product.destroy!
        render_json_dump success: true
      end

      private

      def find_product
        Product.find(params[:id])
      end

      def product_params
        params.permit(
          :external_id,
          :name,
          :description,
          :group_name,
          :active,
          :repurchaseable,
          :amount_cents,
          :currency,
          :recurring_interval,
        )
      end

      def serialize_product(product)
        product.as_json(
          only: %i[
            id
            external_id
            name
            description
            group_name
            active
            repurchaseable
            amount_cents
            currency
            recurring_interval
          ],
        )
      end
    end
  end
end
