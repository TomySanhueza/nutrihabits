class MealLog < ApplicationRecord
  belongs_to :meal
  has_one_attached :photo
  delegate :meal_type, to: :meal, allow_nil: true

  enum :analysis_status, {
    not_requested: "not_requested",
    queued: "queued",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, default: :not_requested

  validates :photo, presence: true
end
