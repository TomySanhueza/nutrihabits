class PatientAiMessage < ApplicationRecord
  belongs_to :patient_ai_chat

  validates :content, presence: true
  enum role: { user: "user", assistant: "assistant" }
end
