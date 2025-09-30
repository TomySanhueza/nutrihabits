class PatientHistory < ApplicationRecord
  belongs_to :user

  belongs_to :nutritionist, class_name: "User"

  validates :visit_date, presence: true
  validates :notes, length: { maximum: 1000 }, allow_nil: true
end
