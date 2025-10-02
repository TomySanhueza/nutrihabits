Rails.application.routes.draw do
  devise_for :patients
  devise_for :nutritionists
  root to: "pages#home"

  authenticate :nutritionist do 
    get 'nutritionist_dashboard', to: 'nutritionists#dashboard', as: :nutritionist_dashboard
    resources :patients
  end
end
