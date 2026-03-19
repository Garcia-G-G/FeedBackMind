Rails.application.routes.draw do
  devise_for :users

  # Sidekiq Web UI (owner-only access)
  authenticate :user, ->(u) { u.owner? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # ── Webhooks (public, no auth) ──
  namespace :webhooks do
    post "intercom",  to: "intercom#create"
    post "slack",     to: "slack#create"
    post "typeform",  to: "typeform#create"
    post "jira",      to: "jira#create"
    post "gmail",     to: "gmail#create"
    post "stripe",    to: "stripe#create"
  end

  # ── API v1 (Bearer token auth) ──
  namespace :api do
    namespace :v1 do
      resource  :account, only: [:show, :update] do
        post :regenerate_token, on: :member
      end
      resources :sources, only: [:index, :show, :create, :update, :destroy]
      resources :feedbacks, only: [:index, :show] do
        collection do
          post :import_csv
        end
      end
      resources :chat_messages, only: [:index, :create]
      resources :syntheses, only: [:index, :show]
      resource  :billing, only: [] do
        post :create_checkout, on: :member
      end
    end
  end

  # ── Web App (Devise auth) ──
  authenticated :user do
    root "dashboard#index", as: :authenticated_root

    # Dashboard
    get "dashboard", to: "dashboard#index", as: :dashboard

    # Feedbacks
    resources :feedbacks, only: [:index, :show]

    # Syntheses
    resources :syntheses, only: [:index, :show, :new, :create]

    # Sources
    resources :sources, only: [:index, :show, :new, :create, :destroy]

    # Pipeline
    resource :pipeline, only: [:show], controller: "pipeline"

    # Closed-Loop Tracker
    resource :loop_tracker, only: [:show], controller: "loop_tracker"

    # Settings
    resource :settings, only: [:show, :update], controller: "settings"

    # AI Chat (Turbo Stream)
    post "chat", to: "chat#create", as: :chat
  end

  # ── Marketing landing (non-logged-in users) ──
  root "pages#home"
end
