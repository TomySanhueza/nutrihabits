Rails.application.routes.draw do
  devise_for :patients
  devise_for :nutritionists
  root to: "pages#home"

  # Rutas de pacientes (solo nutricionistas)
  resources :patients do
    # Recursos anidados del paciente
    resources :nutrition_plans do
      collection do
        post :generate_with_ai
      end
    end
    resources :meal_logs, only: [:index, :new, :create, :destroy]
    resources :daily_check_ins, only: [:index, :new, :create]
  end

  # Perfil del usuario actual
  resource :profile, only: [:show, :edit, :update]

  # Chats nutricionista-paciente (futuro sprint)
  resources :chats, only: [:index, :show, :create] do
    resources :messages, only: [:create]
  end

  # Chats con IA para pacientes
  resources :patient_ai_chats, only: [:index, :show, :create, :destroy] do
    resources :patient_ai_messages, only: [:create]
  end

  # Chats con IA para nutricionistas
  resources :nutritionist_ai_chats, only: [:index, :show, :create, :destroy] do
    resources :nutritionist_ai_messages, only: [:create]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
