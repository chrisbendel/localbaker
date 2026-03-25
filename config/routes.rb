Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resource :session, only: [:new, :create, :destroy] do
    get :verify, on: :collection
    post :confirm, on: :collection
  end

  # Singular store for member actions (a user owns at most one store)
  resource :store, shallow: true, only: [:new, :create, :show, :edit, :update, :destroy] do
    resources :events, shallow: true, module: :stores do
      member do
        post :publish
        post :duplicate
      end
      resources :event_products, shallow: true, only: [:new, :create, :edit, :update, :destroy]
    end
  end

  get "unsub/:token", to: "public_unsubscribes#unsubscribe", as: :unsubscribe

  get "/shop/:slug", to: "storefront#show", as: :storefront

  scope "/shop/:slug", module: :storefront, as: :storefront do
    resource :notification, only: [:create, :destroy]

    resources :events, only: [:show], shallow: true do
      resources :order_items, only: [:create, :update, :destroy]
    end
  end

  resource :profile, only: [:show, :update]

  get "/dashboard", to: "dashboard#index", as: :dashboard

  root to: "sessions#new"

  # Test-only: direct sign-in without OTP (used by system tests to bypass email auth)
  if Rails.env.test?
    get "/test/sign_in/:user_id", to: "test/auth#create", as: :test_sign_in
  end
end
