# frozen_string_literal: true

Fabricator(:dodo_product, from: "DiscourseDodoSubscriptions::Product") do
  external_id { sequence(:external_id) { |i| "pdt_#{i}" } }
  name { sequence(:name) { |i| "Product #{i}" } }
  group_name { sequence(:group_name) { |i| "dodo_group_#{i}" } }
  active true
end
