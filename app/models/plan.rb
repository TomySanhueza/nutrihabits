class Plan < ApplicationRecord
  belongs_to :nutrition_plan
  has_many :meals, dependent: :destroy

  accepts_nested_attributes_for :meals, allow_destroy: true, reject_if: :all_blank
end
