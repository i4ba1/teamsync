require "sidekiq/web"

Rails.application.routes.draw do
  # Health check
  get "/health", to: proc { [200, {}, ["OK"]] }
  get "/up", to: proc { [200, {}, ["OK"]] }

  # API documentation (Swagger UI)
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  # Action Cable
  mount ActionCable.server => "/cable"

  # Sidekiq Web UI (in production, protect with authentication)
  mount Sidekiq::Web => "/sidekiq"

  namespace :api do
    namespace :v1 do
      # Authentication routes
      namespace :auth do
        post "/signup", to: "registrations#create"
        post "/login", to: "sessions#create"
        delete "/logout", to: "sessions#destroy"
        get "/me", to: "users#show"
        put "/me", to: "users#update"
        post "/refresh", to: "sessions#refresh"
      end

      # Teams routes
      resources :teams, param: :slug do
        member do
          post :invite
          post :join
        end

        resources :members, only: %i[index destroy], controller: "team_members" do
          member do
            patch :update_role
          end
        end

        # Standups routes nested under teams
        resources :standups, only: %i[index show create update destroy] do
          collection do
            get :today
          end
        end
      end

      # Notifications
      resources :notifications, only: %i[index show update] do
        collection do
          post :mark_all_read
        end
      end
    end
  end
end
