require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  # === Health Check ===
  get "up" => "rails/health#show", as: :rails_health_check

  # === Devise Auth ===
  devise_for :users, controllers: { registrations: "users/registrations" }

  # === Sidekiq Dashboard (owner-only) ===
  authenticate :user, ->(u) { u.owner? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # === Webhooks (public, no auth — signature verified per source) ===
  namespace :webhooks do
    post "intercom/:account_id", to: "intercom#create", as: :intercom
    post "slack/:account_id",    to: "slack#create",    as: :slack
    post "typeform/:account_id", to: "typeform#create", as: :typeform
    post "jira/:account_id",     to: "jira#create",     as: :jira
    post "gmail/:account_id",    to: "gmail#create",    as: :gmail
    post "stripe",               to: "stripe#create",   as: :stripe
  end

  # === API v1 (Bearer token auth) ===
  namespace :api do
    namespace :v1 do
      resource :account, only: [:show, :update] do
        post :regenerate_token, on: :member
      end

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

      resources :chat_messages, only: [:index, :create]
      resources :syntheses, only: [:index, :show]

      namespace :billing do
        post "checkout", to: "checkout#create"
        post "portal",   to: "portal#create"
      end
    end
  end

  # === Web App (Devise auth) ===
  authenticated :user do
    root "dashboard#index", as: :authenticated_root

    get "dashboard", to: "dashboard#index", as: :dashboard

    resources :feedbacks, only: [:index, :show]
    resources :syntheses, only: [:index, :show, :new, :create]
    resources :sources, only: [:index, :show, :new, :create, :destroy]

    resource :pipeline, only: [:show], controller: "pipeline"
    resource :loop_tracker, only: [:show], controller: "loop_tracker"
    resource :settings, only: [:show, :update], controller: "settings" do
      post :regenerate_token
      post :invite_member
      delete :remove_member
    end

    post "chat", to: "chat#create", as: :chat

    # Onboarding wizard
    resource :onboarding, only: [:show, :update], controller: "onboarding"

    # Source OAuth connections
    post "sources/connect/:provider", to: "source_connections#create", as: :connect_source
    get "sources/callback/intercom", to: "source_connections#intercom_callback"
    get "sources/callback/jira", to: "source_connections#jira_callback"
    get "sources/callback/typeform", to: "source_connections#typeform_callback"

    # CSV import
    post "sources/import_csv", to: "source_connections#import_csv", as: :import_csv_source
  end

  # OmniAuth callbacks (outside authenticated — middleware handles auth)
  get "/auth/:provider/callback", to: "source_connections#omniauth_callback"
  get "/auth/failure", to: "source_connections#omniauth_failure"

  # Redirect unauthenticated users to sign-in for app routes
  get "dashboard", to: redirect("/users/sign_in")
  get "feedbacks", to: redirect("/users/sign_in")
  get "syntheses", to: redirect("/users/sign_in")
  get "sources", to: redirect("/users/sign_in")
  get "pipeline", to: redirect("/users/sign_in")
  get "settings", to: redirect("/users/sign_in")

  # === Marketing landing (non-logged-in users) ===
  root "pages#home"
end
