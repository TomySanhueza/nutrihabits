class NutritionPlan < ApplicationRecord
  belongs_to :user

  belongs_to :nutritionist, class_name: "User"

  validates :objective, presence: true
  validates :calories, :protein, :fat, :carbs, numericality: { greater_than: 0 }, allow_nil: true
end
