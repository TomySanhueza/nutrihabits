class Meal < ApplicationRecord
  belongs_to :plan
  has_one :meal_log, dependent: :destroy
end
