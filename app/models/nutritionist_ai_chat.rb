class NutritionistAiChat < ApplicationRecord
  belongs_to :user   # nutricionista
  has_many :nutritionist_ai_messages, dependent: :destroy
end
