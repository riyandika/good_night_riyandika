Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :users, only: [ :index, :show ] do
        resources :follows, only: [ :create, :index ] do
          collection do
            delete ":target_user_id", action: :destroy
          end
        end
        resources :sleep_records, only: [ :create, :index ] do
          collection do
            get :friends_sleep_records
          end
        end
      end
    end
  end
end
