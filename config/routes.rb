Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, path: "", path_names: { sign_in: "sign_in", sign_out: "sign_out", password: "password" }, skip: [:registrations]

  namespace :public, path: "" do
    root "home#index"
  end

  namespace :core, path: "" do
    get "dashboard", to: "dashboard#index", as: :dashboard
  end

  namespace :api do
  end
end
