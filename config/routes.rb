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
    resources :nutritionist_ai_chats, only: [:index, :create, :show, :destroy] do
      member do
        post :ask
      end
    end
  end

  authenticate :patient do
    resources :meals do
      resources :meal_logs, except: [:edit, :update]
    end
    resources :patient_ai_chats, only: [:index, :create, :show, :destroy] do
      member do
        post :ask
      end
    end
  end
end
