# frozen_string_literal: true

class NormalizeDodoMembershipPlanKeys < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE discourse_dodo_subscription_products
      SET plan_key = group_name
      WHERE plan_key = name
    SQL
  end

  def down
    # Plan keys are configuration data and cannot be restored reliably.
  end
end
