class PatientAiMessage < ApplicationRecord
  belongs_to :patient_ai_chat, touch: true

  validates :role, presence: true, inclusion: { in: %w[user assistant system] }
  validates :content, presence: true

  # Callback para agregar metadata automáticamente
  before_create :set_metadata

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

  private

  def set_metadata
    self.metadata ||= {}
    self.metadata.merge!({
      timestamp: Time.current.iso8601,
      role: role
    })
  end
end
