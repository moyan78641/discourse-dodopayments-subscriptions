# frozen_string_literal: true

class CreateDodoSubscriptionCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_dodo_subscription_customers do |t|
      t.bigint :user_id, null: false
      t.string :external_id, null: false
      t.string :email
      t.timestamps
    end

    add_index :discourse_dodo_subscription_customers, :user_id
    add_index :discourse_dodo_subscription_customers, :external_id
    add_index :discourse_dodo_subscription_customers,
              %i[user_id external_id],
              unique: true,
              name: "idx_dodo_customers_on_user_and_external"
  end
end
