require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  # === Health Check ===
  get "up" => "rails/health#show", as: :rails_health_check

  # === Devise Auth ===
  devise_for :users

  # === Sidekiq Dashboard (admin only) ===
  authenticate :user, ->(user) { user.owner? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # === API v1 ===
  namespace :api do
    namespace :v1 do
      # Account
      resource :account, only: [:show, :update] do
        post :regenerate_token, on: :member
      end

      # Sources CRUD
      resources :sources

      # Feedbacks (read-only + CSV import)
      resources :feedbacks, only: [:index, :show] do
        collection do
          post :import_csv
        end
      end

      # Chat (RAG)
      resource :chat, only: [:create], controller: "chat" do
        get :history, on: :collection
      end

      # Weekly Syntheses
      resources :syntheses, only: [:index, :show] do
        get :latest, on: :collection
      end
    end
  end

  # === Webhooks (no auth — signature verified per source) ===
  namespace :webhooks do
    post "intercom(/:account_subdomain)", to: "intercom#create", as: :intercom
    post "slack",                          to: "slack#create",    as: :slack
    post "typeform(/:account_subdomain)",  to: "typeform#create", as: :typeform
    post "jira(/:account_subdomain)",      to: "jira#create",    as: :jira
    post "gmail(/:account_subdomain)",     to: "gmail#create",   as: :gmail
    post "stripe",                         to: "stripe#create",  as: :stripe
  end

  # === Billing (Devise-authenticated) ===
  namespace :billing do
    post "checkout", to: "checkout#create"
    post "portal",   to: "portal#create"
  end
end
