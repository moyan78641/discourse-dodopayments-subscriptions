# frozen_string_literal: true

DiscourseDodoSubscriptions::Engine.routes.draw do
  namespace :admin, constraints: AdminConstraint.new do
    resources :products
    resources :orders, only: %i[index create update]
  end

  namespace :user do
    resources :subscriptions, only: %i[index]
  end

  get "/" => "subscribe#index"
  get ".json" => "subscribe#index"
  get "/success" => "subscribe#success"
  get "/success.json" => "subscribe#success"
  get "/:id" => "subscribe#show"
  post "/checkout" => "subscribe#create_checkout"

  post "/webhooks/dodo" => "hooks#create"
end
