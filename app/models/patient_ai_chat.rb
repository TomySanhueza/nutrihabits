class PatientAiChat < ApplicationRecord
  belongs_to :patient
  has_many :patient_ai_messages, dependent: :destroy

  # Callback para inicializar context con datos del paciente
  before_create :set_initial_context

  # Actualizar timestamp cuando se agregan mensajes
  after_touch :update_timestamp

  def first_user_message
    patient_ai_messages.where(role: 'user').first
  end

  def last_message
    patient_ai_messages.order(created_at: :desc).first
  end

  def active_nutrition_plan
    @active_plan ||= patient.nutrition_plans.find_by(status: 'active')
  end

  private

  def set_initial_context
    active_plan = patient.nutrition_plans.find_by(status: 'active')
    self.context = {
      patient_id: patient.id,
      nutrition_plan_id: active_plan&.id,
      plan_objective: active_plan&.objective,
      initial_weight: patient.profile&.weight,
      created_at: Time.current.iso8601
    }
  end

  def update_timestamp
    touch
  end
end
