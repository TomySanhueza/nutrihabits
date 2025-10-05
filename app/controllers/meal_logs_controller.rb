class MealLogsController < ApplicationController
  before_action :authenticate_patient!
  before_action :set_meal, only: [:new, :create]
  before_action :set_meal_log, only: [:show, :destroy]

  def index
    @meal_logs = current_patient.meal_logs_through_plans.order(created_at: :desc)
  end

  def show
  end

  def new
    @meal_log = MealLog.new
  end

  def create
    @meal_log = @meal.build_meal_log(meal_log_params)
    @meal_log.logged_at = Time.current
    @meal_log.meal_type = @meal.meal_type

    if @meal_log.photo.attached?
      # Guardar primero para obtener el signed_id
      if @meal_log.save
        # Analizar imagen con IA
        analysis_service = MealLogAnalysisService.new(@meal_log.photo, @meal)
        analysis_result = analysis_service.call

        # Actualizar con resultados del análisis
        @meal_log.update(
          ai_calories: analysis_result["ai_calories"],
          ai_protein: analysis_result["ai_protein"],
          ai_carbs: analysis_result["ai_carbs"],
          ai_fat: analysis_result["ai_fat"],
          ai_health_score: analysis_result["ai_health_score"],
          ai_feedback: analysis_result["ai_feedback"],
          ai_comparison: analysis_result["ai_comparison"]
        )

        redirect_to meal_meal_log_path(@meal, @meal_log), notice: 'Tu comida fue registrada y analizada exitosamente.'
      else
        render :new
      end
    else
      @meal_log.errors.add(:photo, "debe estar presente")
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

  def set_meal
    @meal = Meal.find(params[:meal_id])
  end

  def set_meal_log
    @meal_log = MealLog.find(params[:id])
  end

  def meal_log_params
    params.require(:meal_log).permit(:photo)
  end
end
