class PatientAiChat < ApplicationRecord
  belongs_to :patient
  has_many :patient_ai_messages
end
