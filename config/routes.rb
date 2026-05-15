Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, path: "", path_names: { sign_in: "sign_in", sign_out: "sign_out", password: "password" }, skip: [ :registrations ]

  namespace :public, path: "" do
    root "home#index"
  end

  namespace :core, path: "" do
    get  "dashboard",              to: "dashboard#index",       as: :dashboard
    get  "activity",               to: "activity#index",        as: :activity
    get  "billing",                to: "billing#index",         as: :billing
    get  "settings",               to: "settings#index",        as: :settings
    get  "developers",             to: "developers#index",      as: :developers
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

  namespace :api do
  end
end
