class NutritionistsController < ApplicationController
  def dashboard
    @patients = current_nutritionist.patients 
  end
end
