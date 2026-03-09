class NutritionPlansController < ApplicationController
  before_action :authenticate_nutritionist!
  before_action :set_patient
  before_action :set_nutrition_plan, only: [:show, :edit, :update, :destroy]

  def index
    @nutrition_plans = @patient.nutrition_plans
  end

  def show
  end

  def new
    @nutrition_plan = NutritionPlan.new
  end

  def create
    unless @patient.profile.present?
      redirect_to patient_path(@patient), alert: "Debes completar el perfil antes de generar un plan."
      return
    end

    response = NutritionPlanGeneratorService.new(@patient.profile, Date.today, Date.today + 6).call

    @nutrition_plan = @patient.nutrition_plans.create(
      objective: response["plan"]["objective"],
      calories: response["plan"]["calories"],
      protein: response["plan"]["protein"],
      fat: response["plan"]["fat"],
      carbs: response["plan"]["carbs"],
      meal_distribution: response["plan"]["meal_distribution"],
      notes: response["plan"]["notes"],
      ai_rationale: response["criteria_explanation"],
      nutritionist: current_nutritionist,
      status: 'active',
      start_date: Date.today,
      end_date: Date.today + 6
    )

    # Poblar plans y meals desde meal_distribution
    meal_distribution = response["plan"]["meal_distribution"]
    meal_distribution.each do |date_str, daily_meals|
      plan = @nutrition_plan.plans.create(date: Date.parse(date_str))

      daily_meals.each do |meal_type, meal_data|
        plan.meals.create(
          meal_type: normalize_meal_type(meal_type),
          ingredients: meal_data["ingredients"],
          recipe: meal_data["recipe"],
          calories: meal_data["calorias"],
          protein: meal_data["protein"],
          carbs: meal_data["carbs"],
          fat: meal_data["fat"],
          status: 'pending'
        )
      end
    end

    redirect_to edit_patient_nutrition_plan_path(@patient, @nutrition_plan)
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
    @nutrition_plan = @patient.nutrition_plans.find(params[:id])
  end

  def normalize_meal_type(value)
    value.to_s.strip.downcase.singularize
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
end
