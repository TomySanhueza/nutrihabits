class NutritionistAiChat < ApplicationRecord
  belongs_to :nutritionist
  has_many :nutritionist_ai_messages, dependent: :destroy

  # Actualizar timestamp cuando se agregan mensajes
  after_touch :update_timestamp

  def first_user_message
    nutritionist_ai_messages.where(role: 'user').first
  end

  def last_message
    nutritionist_ai_messages.order(created_at: :desc).first
  end

  private

  def update_timestamp
    touch
  end
end
