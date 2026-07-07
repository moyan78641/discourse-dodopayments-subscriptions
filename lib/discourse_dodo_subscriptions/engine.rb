# frozen_string_literal: true

module ::DiscourseDodoSubscriptions
  class Engine < ::Rails::Engine
    engine_name "discourse-dodopayments-subscriptions"
    isolate_namespace DiscourseDodoSubscriptions
  end
end
