class Profile < ApplicationRecord
  belongs_to :patient
  has_one :nutritionist, through: :patient

  validates :patient_id, uniqueness: true
end
