Rails.application.routes.draw do
  # === Devise Authentication ===
  devise_for :users

  # === Sidekiq Web Dashboard (admin only) ===
  require "sidekiq/web"
  require "sidekiq/cron/web"
  authenticate :user, ->(user) { user.role_owner? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # === Health Check ===
  get "up" => "rails/health#show", as: :rails_health_check

  # === Webhook Receivers (no auth — verified by signature) ===
  namespace :webhooks, defaults: { format: :json } do
    post "intercom", to: "intercom#create"
    post "slack",    to: "slack#create"
    post "typeform", to: "typeform#create"
    post "jira",     to: "jira#create"
    post "gmail",    to: "gmail#create"
    post "stripe",   to: "stripe#create"
  end

  # === API v1 (token auth) ===
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resource :account, only: [:show, :update]

      resources :sources, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :activate
          post :deactivate
        end
      end

      resources :feedbacks, only: [:index, :show] do
        collection do
          post :import_csv
        end
      end

      resources :chat_messages, only: [:index, :create], path: "chat"

      resources :syntheses, only: [:index, :show], controller: "syntheses"

      namespace :billing do
        post "checkout", to: "checkout#create"
        post "portal",   to: "portal#create"
      end
    end
  end

  # === Root ===
  root "pages#home"
end
