class Patient < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable
  belongs_to :nutritionist
  has_one :profile, dependent: :destroy
  has_many :nutrition_plans, dependent: :destroy
  has_many :patient_histories
  has_many :chats
  has_many :patient_ai_chats
  has_many :weight_patients, dependent: :destroy
  has_many :plans, through: :nutrition_plans
  has_many :meals, through: :plans

  # Obtener meal_logs a través de las meals
  def meal_logs_through_plans
    MealLog.joins(meal: { plan: :nutrition_plan }).where(nutrition_plans: { patient_id: id })
  end

  # Obtener meals disponibles (sin meal_log registrado)
  def available_meals
    meals.left_joins(:meal_log).where(meal_logs: { id: nil })
  end
end
