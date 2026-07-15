# frozen_string_literal: true

class AddHybridMembershipSupport < ActiveRecord::Migration[7.1]
  def change
    add_column :discourse_dodo_subscription_products,
               :billing_type,
               :string,
               null: false,
               default: "subscription"
    add_column :discourse_dodo_subscription_products, :plan_key, :string
    add_column :discourse_dodo_subscription_products,
               :wechat_pay_enabled,
               :boolean,
               null: false,
               default: false
    add_column :discourse_dodo_subscription_products,
               :position,
               :integer,
               null: false,
               default: 0

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE discourse_dodo_subscription_products
          SET plan_key = name
          WHERE plan_key IS NULL
        SQL
      end
    end

    change_column_null :discourse_dodo_subscription_products, :plan_key, false
    add_index :discourse_dodo_subscription_products, :plan_key
    add_index :discourse_dodo_subscription_products, :billing_type

    add_column :discourse_dodo_subscriptions, :opened_notified_at, :datetime

    create_table :discourse_dodo_membership_orders do |t|
      t.bigint :user_id, null: false
      t.bigint :product_id, null: false
      t.string :external_id, null: false
      t.string :source, null: false
      t.string :status, null: false, default: "succeeded"
      t.integer :amount_cents
      t.string :currency
      t.string :payment_method
      t.datetime :starts_at, null: false
      t.datetime :expires_at, null: false
      t.bigint :created_by_id
      t.text :note
      t.json :metadata
      t.json :reminders_sent, null: false, default: []
      t.datetime :opened_notified_at
      t.datetime :expired_notified_at
      t.timestamps
    end

    add_index :discourse_dodo_membership_orders, :external_id, unique: true
    add_index :discourse_dodo_membership_orders, :user_id
    add_index :discourse_dodo_membership_orders, :product_id
    add_index :discourse_dodo_membership_orders, :status
    add_index :discourse_dodo_membership_orders, :expires_at
    add_index :discourse_dodo_membership_orders,
              %i[user_id product_id expires_at],
              name: "idx_dodo_orders_user_product_expiry"

    create_table :discourse_dodo_membership_order_events do |t|
      t.bigint :order_id, null: false
      t.bigint :actor_id
      t.string :action, null: false
      t.json :details
      t.datetime :created_at, null: false
    end

    add_index :discourse_dodo_membership_order_events, :order_id
    add_index :discourse_dodo_membership_order_events, :actor_id
  end
end
