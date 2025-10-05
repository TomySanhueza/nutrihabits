class MealLogsController < ApplicationController
  before_action :authenticate_patient!
  before_action :set_meal_log, only: [:show, :edit, :update, :destroy]

  def index
    @meal_logs = current_patient.meal_logs_through_plans.order(created_at: :desc)
  end

  def show
  end

  def new
    @meal_log = MealLog.new
    @meals = current_patient.available_meals
  end

  def create
    @meal = Meal.find(params[:meal_log][:meal_id])
    @meal_log = @meal.build_meal_log(meal_log_params)
    @meal_log.logged_at = Time.current

    if @meal_log.photo.attached?
      # Analizar imagen con IA
      image_data = @meal_log.photo.download
      nutrition_plan = @meal.plan.nutrition_plan

      analysis_service = MealLogAnalysisService.new(image_data, nutrition_plan)
      analysis_result = analysis_service.call

      # Guardar resultados del análisis
      @meal_log.meal_type = @meal.meal_type
      @meal_log.ai_calories = analysis_result["ai_calories"]
      @meal_log.ai_protein = analysis_result["ai_protein"]
      @meal_log.ai_carbs = analysis_result["ai_carbs"]
      @meal_log.ai_fat = analysis_result["ai_fat"]
      @meal_log.ai_health_score = analysis_result["ai_health_score"]
      @meal_log.ai_feedback = analysis_result["ai_feedback"]

      if @meal_log.save
        redirect_to @meal_log, notice: 'Tu comida fue registrada y analizada exitosamente.'
      else
        @meals = current_patient.available_meals
        render :new
      end
    else
      @meals = current_patient.available_meals
      render :new
    end
  end

  def edit
  end

  def update
    if @meal_log.update(meal_log_params)
      redirect_to @meal_log, notice: 'Registro actualizado exitosamente.'
    else
      render :edit
    end
  end

  def destroy
    @meal_log.destroy
    redirect_to meal_logs_path, notice: 'Registro eliminado exitosamente.'
  end

  private

  def set_meal_log
    @meal_log = MealLog.find(params[:id])
  end

  def meal_log_params
    params.require(:meal_log).permit(:photo)
  end
end
