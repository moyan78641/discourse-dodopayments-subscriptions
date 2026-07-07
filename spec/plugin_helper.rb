# frozen_string_literal: true

Dir[Rails.root.join("plugins/discourse-dodopayments-subscriptions/spec/fabricators/*.rb")].each do |f|
  require f
end
