class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { patient: "patient", nutritionist: "nutritionist" }

  scope :patients, -> { where(role: "patient") }
  scope :nutritionists, -> { where(role: "nutritionist") }

  has_one_attached :user_photo

  # Perfil (datos básicos, objetivos, condiciones, etc.)
  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile

  # Si es paciente
  has_many :nutrition_plans, foreign_key: "user_id", dependent: :destroy
  has_many :patient_histories, foreign_key: "user_id", dependent: :destroy
  has_many :meal_logs, dependent: :destroy
  has_many :daily_check_ins, dependent: :destroy
  has_many :patient_ai_chats, dependent: :destroy

  # Si es nutricionista
  has_many :nutritionist_plans, class_name: "NutritionPlan", foreign_key: "nutritionist_id", dependent: :destroy
  has_many :nutritionist_histories, class_name: "PatientHistory", foreign_key: "nutritionist_id", dependent: :destroy
  has_many :nutritionist_ai_chats, dependent: :destroy

  # Chat general (futuro sprint: nutricionista-paciente)
  has_many :chats_as_nutritionist, class_name: "Chat", foreign_key: "nutritionist_id"
  has_many :chats_as_patient, class_name: "Chat", foreign_key: "patient_id"
end
