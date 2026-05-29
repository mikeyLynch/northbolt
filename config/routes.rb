Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  authenticate :user do
    mount Rswag::Ui::Engine  => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  end
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, path: "", path_names: { sign_in: "sign_in", sign_out: "sign_out", password: "password" }, skip: [ :registrations ]

  namespace :public, path: "" do
    root "home#index"
  end

  namespace :core, path: "" do
    get  "dashboard",              to: "dashboard#index",       as: :dashboard
    get  "activity",               to: "activity#index",        as: :activity
    get  "billing",                to: "billing#index",         as: :billing
    get    "settings",                to: "settings#index",         as: :settings
    patch  "settings",                to: "settings#update_general", as: :settings_general
    patch  "settings/stora",         to: "settings#update_stora",  as: :settings_stora
    post   "settings/api_keys",              to: "settings#create_api_key",   as: :settings_api_keys
    delete "settings/api_keys/:id",          to: "settings#revoke_api_key",   as: :settings_api_key
    post   "settings/invitations",           to: "settings#create_invitation", as: :settings_invitations
    post   "settings/invitations/:id/resend", to: "settings#resend_invitation", as: :resend_settings_invitation
    delete "settings/invitations/:id",       to: "settings#cancel_invitation", as: :settings_invitation
    delete "settings/members/:id",           to: "settings#remove_member",    as: :settings_member

    get  "notifications",          to: "notifications#index",   as: :notifications
    get  "notifications/unread_count", to: "notifications#unread_count", as: :notifications_unread_count
    patch "notifications/read_all", to: "notifications#read_all", as: :notifications_read_all
    patch "notifications/:id/read", to: "notifications#read",   as: :notification_read
    resources :locks, only: [ :index, :show ] do
      resources :access_grants, only: [ :new, :create ], module: :locks
    end
    resources :tenants, only: %i[ index show new create edit update destroy ] do
      resource  :lock_assignments, only: %i[ new create ], module: :tenants
      resources :access_grants,    only: %i[ new create ], module: :tenants
    end
    resources :access_grants, only: %i[ edit update ] do
      member { patch :revoke }
    end
  end

  get  "invitations/:token", to: "invitations#show",   as: :invitation
  post "invitations/:token", to: "invitations#accept", as: :accept_invitation

  namespace :webhooks do
    post "stora/:token", to: "stora#create", as: :stora
  end

  namespace :api do
    namespace :public do
      namespace :v1 do
        resources :locks,   only: %i[ index show ]
        resources :tenants, only: %i[ index create ]
      end
    end

    namespace :private do
      namespace :v1 do
        resource :heartbeat, only: %i[ create ]
      end
    end
  end
end
