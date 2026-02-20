Rails.application.routes.draw do
  namespace :api do
    post "login", to: "sessions#create"
    post "logout", to: "sessions#destroy"
    get "me", to: "sessions#me"

    resources :expenses, only: %i[index show create update destroy] do
      member do
        post :submit
        post :approve
        post :reject
        get :audit_logs
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
