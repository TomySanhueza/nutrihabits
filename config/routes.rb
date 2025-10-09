Rails.application.routes.draw do
  devise_for :patients
  devise_for :nutritionists
  root to: "pages#home"

  authenticate :nutritionist do
    get 'nutritionist_dashboard', to: 'nutritionists#dashboard', as: :nutritionist_dashboard
    resources :patients do
      resources :profiles, only: [:new, :create]
      resources :nutrition_plans
      resources :patient_histories
    end
  end

  authenticate :patient do
    namespace :pats do
      get 'dashboard', to: 'dashboard#show'
      post 'update_status', to: 'status#update'
    end
    resources :meals do
      resources :meal_logs, except: [:edit, :update]
    end
    resources :weight_patients
    # get "dashboard", to: "patients#dashboard"
    # get "plans/:id", to: "plans#show", as: :plan
  end
end
