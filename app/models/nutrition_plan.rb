class NutritionPlan < ApplicationRecord
  belongs_to :patient
  belongs_to :nutritionist
  has_many :plans
  has_many :patient_histories
end
