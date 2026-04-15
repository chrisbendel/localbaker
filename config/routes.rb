Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", :as => :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", :as => :pwa_service_worker
  get "offline" => "pwa#offline", :as => :pwa_offline

  resource :session, only: [:new, :create, :destroy] do
    get :verify, on: :collection
    post :confirm, on: :collection
  end

  # Baker Management Portal
  resource :dashboard, controller: "dashboard", only: [:show] do
    get :qr
    post :dismiss_onboarding

    # Nested actions in Dashboard:: namespace
    scope module: :dashboard do
      resource :store, only: [:new, :create, :show, :update, :destroy], controller: "stores"
      resource :profile, only: [:show, :update], controller: "profiles"
      resource :payments, only: [:show, :update], controller: "payments"

      resources :events, shallow: true do
        member do
          post :publish
          post :duplicate
          get :prep
        end
        resources :event_products, shallow: true, only: [:new, :create, :edit, :update, :destroy]
      end
    end
  end

  # User Account Settings
  namespace :settings do
    root to: redirect("/settings/account")
    resource :account, only: [:show, :update], controller: "accounts"
    resources :notifications, only: [:index, :destroy], controller: "notifications"
  end

  get "unsub/:token", to: "public_unsubscribes#unsubscribe", as: :unsubscribe

  get "/shop/:slug", to: "shop#show", as: :shop
  get "/shop/:slug/about", to: "shop#about", as: :shop_about

  scope "/shop/:slug", module: :shop, as: :shop do
    resource :notification, only: [:create, :destroy]

    resources :events, only: [:show], shallow: true do
      member do
        post :confirm, controller: "orders"
        post :unconfirm, controller: "orders"
      end
      resources :order_items, only: [:create, :destroy]
    end
    # ICS download removed — use Google Calendar button instead
  end

  get "billing/upgrade", to: "billing#upgrade"
  post "billing/checkout", to: "billing#checkout"
  get "billing/success", to: "billing#success"
  post "billing/portal", to: "billing#portal"
  resource :contact, only: [:new, :create]

  resources :orders, only: [:index]
  root to: "pages#home"
  get "home", to: "pages#home" # Keep landing page accessible at /home
  get "about", to: "pages#about", as: :about
  get "explore", to: "locations#explore", as: :explore
  get "bakers", to: "locations#bakers", as: :bakers

  # Test-only: direct sign-in without OTP (used by system tests to bypass email auth)
  if Rails.env.test?
    get "/test/sign_in/:user_id", to: "test/auth#create", as: :test_sign_in
  end
end
