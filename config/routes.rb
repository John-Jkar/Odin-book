Rails.application.routes.draw do
  devise_for :users

  root "pages#home"

  resources :posts, only: [ :index, :create, :destroy ] do
    resource :like, only: [ :create, :destroy ]
    resources :comments, only: :create
  end
  resources :comments, only: :destroy

  get "discover", to: "posts#discover", as: :discover

  resources :users, only: [ :index, :show ] do
    resource :follow, only: [ :create, :destroy ], controller: :follows
    resources :follow_requests, only: [ :update, :destroy ],
      controller: :follow_requests
  end

  resource :profile, only: [ :edit, :update ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
