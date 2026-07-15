# frozen_string_literal: true

Fabricator(:dodo_order, from: "DiscourseDodoSubscriptions::Order") do
  user
  product(fabricator: :dodo_product)
  external_id { sequence(:external_id) { |i| "pay_#{i}" } }
  source "dodo"
  status "succeeded"
  starts_at { Time.zone.now }
  expires_at { 1.month.from_now }
end
