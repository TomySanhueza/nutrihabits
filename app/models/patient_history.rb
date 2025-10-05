class PatientHistory < ApplicationRecord
  belongs_to :patient
  belongs_to :nutritionist
  belongs_to :nutrition_plan
end
