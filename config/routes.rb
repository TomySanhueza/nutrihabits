Rails.application.routes.draw do
  devise_for :patients
  devise_for :nutritionists
  root to: "pages#home"

  authenticate :nutritionist do
    get 'nutritionist_dashboard', to: 'nutritionists#dashboard', as: :nutritionist_dashboard
    resources :patients do
      resources :profiles, only: [:new, :create]
      resources :nutrition_plans
    end
  end

  authenticate :patient do
    resources :meal_logs, except: [:edit, :update]
  end
end
