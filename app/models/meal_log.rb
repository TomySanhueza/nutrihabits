class MealLog < ApplicationRecord
  belongs_to :user

  has_one_attached :photo

  validates :logged_at, presence: true
end
