class NutritionPlan < ApplicationRecord
  belongs_to :patient
  belongs_to :nutritionist
end
