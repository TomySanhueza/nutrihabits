class NutritionPlan < ApplicationRecord
  belongs_to :user
  belongs_to :nutritionist, class_name: "User"

  validates :objective, presence: true
  validates :calories, :protein, :fat, :carbs, numericality: { greater_than: 0 }, allow_nil: true

  # Parsear meal_distribution si viene como string desde el formulario
  before_validation :parse_meal_distribution

  private

  def parse_meal_distribution
    return if meal_distribution.blank?
    return if meal_distribution.is_a?(Hash)

    # Si es string, intentar parsearlo como JSON
    if meal_distribution.is_a?(String)
      begin
        self.meal_distribution = JSON.parse(meal_distribution)
      rescue JSON::ParserError => e
        errors.add(:meal_distribution, "formato JSON inválido: #{e.message}")
      end
    end
  end
end
