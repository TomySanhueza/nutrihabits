class PatientAiChat < ApplicationRecord
  belongs_to :user

  has_many :patient_ai_messages, dependent: :destroy
end
