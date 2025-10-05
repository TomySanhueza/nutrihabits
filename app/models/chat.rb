class Chat < ApplicationRecord
  belongs_to :nutritionist
  belongs_to :patient
  has_many :messages
end
