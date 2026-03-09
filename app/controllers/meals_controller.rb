class MealsController < ApplicationController
  before_action :authenticate_patient!
  before_action :set_meal, only: [:show, :edit, :update, :destroy]

  def index
    @meals = current_patient.meals.joins(:plan).includes(:plan).order('plans.date DESC')
  end

  def show
  end

  def new
    @meal = Meal.new
    @plans = current_patient.plans.order(date: :desc)
  end

  def create
    @meal = current_patient.plans.find(meal_params[:plan_id]).meals.build(meal_params.except(:plan_id))
    if @meal.save
      redirect_to @meal, notice: 'Comida creada exitosamente.'
    else
      @plans = current_patient.plans.order(date: :desc)
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotFound
    @meal = Meal.new(meal_params.except(:plan_id))
    @meal.errors.add(:plan, "no es válido para este paciente")
    @plans = current_patient.plans.order(date: :desc)
    render :new, status: :unprocessable_content
  end

  def edit
    @plans = current_patient.plans.order(date: :desc)
  end

  def update
    scoped_params = meal_params.except(:plan_id)
    if meal_params[:plan_id].present?
      scoped_plan = current_patient.plans.find(meal_params[:plan_id])
      scoped_params[:plan_id] = scoped_plan.id
    end

    if @meal.update(scoped_params)
      redirect_to @meal, notice: 'Comida actualizada exitosamente.'
    else
      @plans = current_patient.plans.order(date: :desc)
      render :edit, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotFound
    @meal.errors.add(:plan, "no es válido para este paciente")
    @plans = current_patient.plans.order(date: :desc)
    render :edit, status: :unprocessable_content
  end

  def destroy
    @meal.destroy
    redirect_to meals_url, notice: 'Comida eliminada exitosamente.'
  end

  private

  def set_meal
    @meal = current_patient.meals.find(params[:id])
  end

  def meal_params
    params.require(:meal).permit(:plan_id, :meal_type, :ingredients, :recipe, :calories, :protein, :carbs, :fat, :status)
  end
end
