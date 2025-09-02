Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"
  
  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post 'auth/signup', to: 'auth#signup'
      post 'auth/login', to: 'auth#login'
      delete 'auth/logout', to: 'auth#logout'
      get 'auth/me', to: 'auth#me'
      
      # User routes
      get 'users/me', to: 'users#me'
      patch 'users/me', to: 'users#update'
    end
  end
end
