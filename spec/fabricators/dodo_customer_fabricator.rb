# frozen_string_literal: true

Fabricator(:dodo_customer, from: "DiscourseDodoSubscriptions::Customer") do
  user_id { Fabricate(:user).id }
  external_id { sequence(:external_id) { |i| "cus_#{i}" } }
end
