class MealLogsController < ApplicationController
  before_action :authenticate_patient!
  before_action :set_meal, only: [:new, :create, :show, :destroy]
  before_action :set_meal_log, only: [:show, :destroy]

  def index
    @meal_logs = current_patient.meal_logs_through_plans.order(created_at: :desc)
  end

  def show
  end

  def new
    @meal_log = MealLog.new
  end

  def preflight
    render json: ImagePreflightService.new(params[:photo]).call
  end

  def create
    @meal_log = @meal.build_meal_log(meal_log_params)
    @meal_log.logged_at = Time.current
    @meal_log.analysis_status = "queued"

    if @meal_log.photo.attached?
      if @meal_log.save
        MealLogAnalysisJob.perform_later(@meal_log.id)
        redirect_to meal_meal_log_path(@meal, @meal_log), notice: 'Tu comida fue registrada y quedó en análisis.'
      else
        render :new, status: :unprocessable_content
      end
    else
      @meal_log.errors.add(:photo, "debe estar presente")
      render :new, status: :unprocessable_content
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
    redirect_to pats_dashboard_path, notice: 'Registro eliminado exitosamente.'
  end

  private

  def set_meal
    @meal = current_patient.meals.find(params[:meal_id])
  end

  def set_meal_log
    @meal_log = @meal.meal_log
    raise ActiveRecord::RecordNotFound unless @meal_log&.id == params[:id].to_i
  end

  def meal_log_params
    params.require(:meal_log).permit(:photo)
  end
end
