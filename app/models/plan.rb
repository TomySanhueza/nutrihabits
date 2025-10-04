class Plan < ApplicationRecord
  belongs_to :nutrition_plan
  has_many :meals
end
