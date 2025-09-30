Rails.application.routes.draw do
  get 'nutritionist_ai_messages/create'
  get 'nutritionist_ai_chats/index'
  get 'nutritionist_ai_chats/show'
  get 'nutritionist_ai_chats/create'
  get 'patient_ai_messages/create'
  get 'patient_ai_chats/index'
  get 'patient_ai_chats/show'
  get 'patient_ai_chats/create'
  get 'messages/create'
  get 'chats/index'
  get 'chats/show'
  get 'chats/create'
  get 'daily_check_ins/index'
  get 'daily_check_ins/create'
  get 'meal_logs/index'
  get 'meal_logs/create'
  get 'meal_logs/destroy'
  get 'nutrition_plans/index'
  get 'nutrition_plans/show'
  get 'nutrition_plans/create'
  get 'nutrition_plans/update'
  get 'nutrition_plans/destroy'
  get 'profiles/show'
  get 'profiles/edit'
  get 'profiles/update'
  get 'patients/index'
  get 'patients/show'
  get 'patients/new'
  get 'patients/edit'
  get 'patients/create'
  get 'patients/update'
  get 'patients/destroy'
  devise_for :users
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
