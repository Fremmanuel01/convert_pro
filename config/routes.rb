Rails.application.routes.draw do
  devise_for :users
  
  post 'users/auth/firebase', to: 'users/firebase_auth#create'

  root "pages#home"

  get "pricing", to: "pages#pricing"
  get "dashboard", to: "pages#dashboard"
  get "analytics", to: "analytics#index"

  resource :billing, controller: "billing", only: [:show] do
    get :upgrade
    post :create_subscription
    get :callback
  end

  namespace :webhooks do
    post "paystack", to: "paystack#create"
  end

  resources :tools, only: [:index, :show, :create], param: :tool_id
  resources :conversions, only: [:index, :show] do
    member do
      get :download
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
