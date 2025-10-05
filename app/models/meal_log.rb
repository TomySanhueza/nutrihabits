class MealLog < ApplicationRecord
  belongs_to :meal
  has_one_attached :photo

  validates :photo, presence: true
end
