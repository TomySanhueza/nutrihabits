class MealsController < ApplicationController
  before_action :set_meal, only: [:show, :edit, :update, :destroy]

  def index
    @meals = Meal.includes(:plan).all.order('plans.date DESC')
  end

  def show
  end

  def new
    @meal = Meal.new
    @plans = Plan.order(date: :desc)
  end

  def create
    @meal = Meal.new(meal_params)
    if @meal.save
      redirect_to @meal, notice: 'Comida creada exitosamente.'
    else
      @plans = Plan.order(date: :desc)
      render :new
    end
  end

  def edit
    @plans = Plan.order(date: :desc)
  end

  def update
    if @meal.update(meal_params)
      redirect_to @meal, notice: 'Comida actualizada exitosamente.'
    else
      @plans = Plan.order(date: :desc)
      render :edit
    end
  end

  def destroy
    @meal.destroy
    redirect_to meals_url, notice: 'Comida eliminada exitosamente.'
  end

  private

  def set_meal
    @meal = Meal.find(params[:id])
  end

  def meal_params
    params.require(:meal).permit(:plan_id, :meal_type, :ingredients, :recipe, :calories, :protein, :carbs, :fat, :status)
  end
end
