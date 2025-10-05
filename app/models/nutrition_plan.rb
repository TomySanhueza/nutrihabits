class NutritionPlan < ApplicationRecord
  belongs_to :patient
  belongs_to :nutritionist
  has_many :plans, dependent: :destroy
  has_many :patient_histories

  accepts_nested_attributes_for :plans, allow_destroy: true, reject_if: :all_blank
end
