# frozen_string_literal: true

class CreateDodoSubscriptionProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_dodo_subscription_products do |t|
      t.string :external_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :group_name, null: false
      t.boolean :active, null: false, default: true
      t.boolean :repurchaseable, null: false, default: false
      t.integer :amount_cents
      t.string :currency
      t.string :recurring_interval
      t.timestamps
    end

    add_index :discourse_dodo_subscription_products, :external_id, unique: true
    add_index :discourse_dodo_subscription_products, :active
  end
end
