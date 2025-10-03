class NutritionPlansController < ApplicationController
  def index
    @patient = Patient.find(params[:patient_id])
    @nutrition_plans = @patient.nutrition_plans
  end

  def show
    @nutrition_plan = NutritionPlan.find(params[:id])
    @patient = @nutrition_plan.patient
  end

  def new
    @patient = Patient.find(params[:patient_id])
    @nutrition_plan = NutritionPlan.new
  end

  def create
    @patient = Patient.find(params[:patient_id])
    @nutrition_plan = NutritionPlan.new(nutrition_plan_params)
    @nutrition_plan.patient_id = @patient.id
    @nutrition_plan.nutritionist_id = current_nutritionist.id
    @nutrition_plan.status = "active"
    if @nutrition_plan.save
      redirect_to patient_nutrition_plan_path(@patient, @nutrition_plan), notice: 'Plan nutricional creado exitosamente.'
    else
      render :new
    end
  end

  def edit
    @nutrition_plan = NutritionPlan.find(params[:id])
    @patient = @nutrition_plan.patient
  end

  def update
    @nutrition_plan = NutritionPlan.find(params[:id])
    @patient = @nutrition_plan.patient
    if @nutrition_plan.update(nutrition_plan_params)
      redirect_to patient_nutrition_plan_path(@patient, @nutrition_plan), notice: 'Plan nutricional actualizado exitosamente.'
    else
      render :edit
    end
  end

  def destroy
    @nutrition_plan = NutritionPlan.find(params[:id])
    @patient = @nutrition_plan.patient
    @nutrition_plan.destroy
    redirect_to patient_nutrition_plans_path(@patient), notice: 'Plan nutricional eliminado exitosamente.'
  end

  private

  def nutrition_plan_params
    params.require(:nutrition_plan).permit(:objective, :calories, :protein, :fat, :carbs, :notes, :start_date, :end_date)
  end
end
