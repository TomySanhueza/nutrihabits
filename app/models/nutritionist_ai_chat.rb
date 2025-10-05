class NutritionistAiChat < ApplicationRecord
  belongs_to :nutritionist
  has_many :nutritionist_ai_messages
end
