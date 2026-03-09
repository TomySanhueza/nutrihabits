Rails.application.routes.draw do
  devise_for :patients
  devise_for :nutritionists
  root to: "pages#home"
  get "up", to: "rails/health#show", as: :rails_health_check

  authenticate :nutritionist do
    get 'nutritionist_dashboard', to: 'nutritionists#dashboard', as: :nutritionist_dashboard
    resources :patients do
      member do
        post :invite
        post :resend_invite
        post :suspend_access
        post :reactivate_access
      end
      resources :profiles, only: [:new, :create]
      resources :nutrition_plans
      resources :patient_histories
    end
    get "nutritionist_dashboard/patient_radar", to: "nutritionists#patient_radar", as: :nutritionist_patient_radar
  end

  authenticate :patient do
    namespace :pats do
      get 'dashboard', to: 'dashboard#show'
      post 'update_status', to: 'status#update'
    end
    post "meal_logs/preflight", to: "meal_logs#preflight", as: :meal_logs_preflight
    resources :meal_logs, only: [:index]
    resources :meals do
      resources :meal_logs, except: [:index, :edit, :update]
    end
    resources :grocery_lists, only: [] do
      collection do
        get :current
        post :generate
      end
    end
    resources :weight_patients
    # get "dashboard", to: "patients#dashboard"
  end
end
