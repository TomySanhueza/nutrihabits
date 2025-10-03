class Patient < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :validatable
  belongs_to :nutritionist
  has_one :profile, dependent: :destroy
  has_many :nutrition_plans, dependent: :destroy
end
