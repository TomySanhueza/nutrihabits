class NutritionistAiMessage < ApplicationRecord
  belongs_to :nutritionist_ai_chat
  
  validates :content, presence: true
  enum role: { user: "user", assistant: "assistant" }
end
