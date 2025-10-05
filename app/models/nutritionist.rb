class Nutritionist < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  # has_one_attached :user_photo
  has_many :patients
  has_many :profiles, through: :patients
  has_many :nutrition_plans, through: :patients
  has_many :patient_histories
  has_many :chats
  has_many :nutritionist_ai_chats
end
