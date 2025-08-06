# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  # Health Check
  get "up" => "rails/health#show", as: :rails_health_check

  # Admin routes
  namespace :admin do
    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy'
    get 'logout', to: 'sessions#destroy'  # Support GET method for easier logout
    resources :users, only: [:index, :show, :edit, :update] do
      member do
        get 'simulate_request_login', to: 'users#simulate_request_login'
        # Add POST route for updating users
        post '', to: 'users#update'
      end
      # Add nested resources for user syncs
      resources :syncs, controller: 'user_syncs', only: [:index, :show] do
        member do
          get 'sync_run/:sync_run_id/records', to: 'user_syncs#sync_records', as: 'records'
          get 'sync_run/:sync_run_id/logs', to: 'user_syncs#sync_logs', as: 'logs'
        end
      end
    end

    get 'syncs', to: 'user_syncs#syncs_index'
    get 'syncs/:id', to: 'user_syncs#sync_show', as: 'sync'
    get 'syncs/:id/sync_run/:sync_run_id/records', to: 'user_syncs#sync_run_records', as: 'sync_run_records'
    get 'syncs/:id/sync_run/:sync_run_id/logs', to: 'user_syncs#sync_run_logs', as: 'sync_run_logs'
    post 'syncs/:id/sync_run/:sync_run_id/update_status', to: 'user_syncs#update_sync_run_status', as: 'update_sync_run_status'

    root 'users#index'
    get 'setting/index', to: 'settings#index'
    post 'update/password' => 'settings#update_password', as: 'update_password'
    get 'users/reset_password/:id', to: 'users#reset_password', as: 'users_reset_password'
    post 'user/update/password/:id', to: 'users#update_password', as: 'user_update_password'
    resources :workspace_members, only: [:create]
  end

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication Routes
      post "signup", to: "auth#signup"
      get "verify_user", to: "auth#verify_user"
      post "login", to: "auth#login"
      delete "logout", to: "auth#logout"
      post "forgot_password", to: "auth#forgot_password"
      post "reset_password", to: "auth#reset_password"
      post "resend_verification", to: "auth#resend_verification"
      post "simulate_request", to: "auth#simulate_request"

      # Workspace Routes
      resources :workspaces do
        resources :members, controller: 'workspace_members', only: [:index, :create]
      end
      # Custom route for source syncs
      get 'connectors/sources/:id/syncs', to: 'connectors#source_syncs', as: 'connector_source_syncs'
      
      resources :connectors do
        member do
          get :discover
          post :query_source
          post :execute_model
        end
      end
      resources :catalogs, only: %i[create update]
      resources :models
      resources :syncs do
        collection do
          get :configurations
        end
        member do
          patch :enable
        end
        resources :sync_runs, only: %i[index show] do
          resources :sync_records, only: [:index]
        end
      end
      resources :connector_definitions, only: %i[index show] do
        collection do
          post :check_connection
        end
      end
      resources :users, only: [] do
        collection do
          get :me
        end
      end
      resources :reports do
        collection do
          get :workspace_activity
        end
      end

      post "schedule_syncs", to: "schedule_syncs#create"
      delete "schedule_syncs/:sync_id", to: "schedule_syncs#destroy"
    end
  end

  # Uncomment below if you have a root path
  root "rails/health#show"
end
