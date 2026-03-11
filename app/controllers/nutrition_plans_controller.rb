class NutritionPlansController < ApplicationController
  before_action :authenticate_nutritionist!
  before_action :set_patient
  before_action :set_nutrition_plan, only: [:show, :edit, :update, :destroy]

  def index
    @nutrition_plans = @patient.nutrition_plans
      .includes(:patient, plans: :meals)
      .order(start_date: :desc, created_at: :desc)

    @nutrition_plan_stats = {
      total: @nutrition_plans.size,
      active: @nutrition_plans.count { |plan| plan.status == "active" },
      draft: @nutrition_plans.count { |plan| plan.status == "draft" },
      completed: @nutrition_plans.count { |plan| plan.status == "completed" }
    }
  end

  def show
    @daily_plans = @nutrition_plan.plans.includes(:meals).order(date: :asc)
  end

  def new
    @nutrition_plan = NutritionPlan.new
    prepare_new_plan_context
  end

  def create
    unless @patient.profile.present?
      redirect_to patient_path(@patient), alert: "Debes completar el perfil antes de generar un plan."
      return
    end

    @nutrition_plan = NutritionPlanGeneratorService.new(
      patient: @patient,
      nutritionist: current_nutritionist,
      start_date: Date.current,
      end_date: Date.current + 6.days
    ).call

    redirect_to edit_patient_nutrition_plan_path(@patient, @nutrition_plan)
  rescue NutritionPlanGeneratorService::GenerationError
    @nutrition_plan = NutritionPlan.new
    prepare_new_plan_context
    flash.now[:alert] = "No se pudo generar el plan nutricional."
    render :new, status: :unprocessable_content
  end

  def edit
  end

  def update
    if @nutrition_plan.update(nutrition_plan_params)
      redirect_to patient_nutrition_plan_path(@patient, @nutrition_plan), notice: 'Plan nutricional actualizado exitosamente.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @nutrition_plan.destroy
    redirect_to patient_nutrition_plans_path(@patient), notice: 'Plan nutricional eliminado exitosamente.'
  end

  private

  def set_patient
    @patient = current_nutritionist.patients.find(params[:patient_id])
  end

  def set_nutrition_plan
    @nutrition_plan = @patient.nutrition_plans.includes(plans: :meals).find(params[:id])
  end

  def nutrition_plan_params
    params.require(:nutrition_plan).permit(
      :objective, :calories, :protein, :fat, :carbs, :notes, :start_date, :end_date, :meal_distribution,
      plans_attributes: [
        :id, :date, :mood, :energy_level, :activity, :notes, :_destroy,
        meals_attributes: [
          :id, :meal_type, :ingredients, :recipe, :calories, :protein, :carbs, :fat, :status, :_destroy
        ]
      ]
    )
  end

  def prepare_new_plan_context
    @recent_histories = @patient.patient_histories
      .includes(:nutrition_plan)
      .order(visit_date: :desc, created_at: :desc)
      .limit(3)
    @latest_plan = @patient.nutrition_plans.order(start_date: :desc, created_at: :desc).first
  end
end
