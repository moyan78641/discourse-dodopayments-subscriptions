# frozen_string_literal: true

class CreateDodoWebhookEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_dodo_webhook_events do |t|
      t.string :external_id, null: false
      t.string :event_type, null: false
      t.string :status, null: false, default: "received"
      t.json :payload
      t.datetime :processed_at
      t.text :error
      t.timestamps
    end

    add_index :discourse_dodo_webhook_events, :external_id, unique: true
    add_index :discourse_dodo_webhook_events, :event_type
    add_index :discourse_dodo_webhook_events, :status
  end
end
