class NutritionistsController < ApplicationController
  def dashboard
    @patients = current_nutritionist.patients
    @nutritions = @patients.map(&:nutrition_plans).flatten.first(5)
  end
end
