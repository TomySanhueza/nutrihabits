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
      start_date: Date.today
    )

    # Poblar plans y meals desde meal_distribution
    meal_distribution = response["plan"]["meal_distribution"]
    meal_distribution.each do |date_str, daily_meals|
      plan = @nutrition_plan.plans.create(date: Date.parse(date_str))

      daily_meals.each do |meal_type, meal_data|
        plan.meals.create(
          meal_type: meal_type,
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
