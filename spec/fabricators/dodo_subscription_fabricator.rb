# frozen_string_literal: true

Fabricator(:dodo_subscription, from: "DiscourseDodoSubscriptions::Subscription") do
  customer(fabricator: :dodo_customer)
  product(fabricator: :dodo_product)
  external_id { sequence(:external_id) { |i| "sub_#{i}" } }
  status "active"
end
