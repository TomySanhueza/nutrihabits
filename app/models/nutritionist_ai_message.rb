class NutritionistAiMessage < ApplicationRecord
  belongs_to :nutritionist_ai_chat, touch: true

  validates :role, presence: true, inclusion: { in: %w[user assistant system] }
  validates :content, presence: true

  # Scopes útiles
  scope :user_messages, -> { where(role: 'user') }
  scope :assistant_messages, -> { where(role: 'assistant') }
  scope :recent, ->(limit = 10) { order(created_at: :desc).limit(limit) }

  def user?
    role == 'user'
  end

  def assistant?
    role == 'assistant'
  end
end
