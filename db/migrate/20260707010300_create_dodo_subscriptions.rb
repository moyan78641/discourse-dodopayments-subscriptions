# frozen_string_literal: true

class CreateDodoSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_dodo_subscriptions do |t|
      t.bigint :customer_id, null: false
      t.bigint :product_id, null: false
      t.string :external_id, null: false
      t.string :status
      t.datetime :current_period_end
      t.boolean :cancel_at_period_end, null: false, default: false
      t.timestamps
    end

    add_index :discourse_dodo_subscriptions, :customer_id
    add_index :discourse_dodo_subscriptions, :product_id
    add_index :discourse_dodo_subscriptions, :external_id, unique: true
    add_index :discourse_dodo_subscriptions, :status
  end
end
