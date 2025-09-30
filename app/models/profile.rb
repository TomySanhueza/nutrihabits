class Profile < ApplicationRecord
  belongs_to :user

  validates :weight, :height, numericality: { greater_than: 0 }, allow_nil: true
  validates :goals, :conditions, :lifestyle, length: { maximum: 500 }, allow_nil: true
end
