class PatientPrioritySnapshot < ApplicationRecord
  belongs_to :patient
  belongs_to :nutritionist

  validates :priority_level, :captured_at, presence: true
end
