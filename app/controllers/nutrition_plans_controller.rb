class NutritionPlansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_patient
  before_action :set_nutrition_plan, only: [:show, :edit, :update, :destroy]
  before_action :ensure_nutritionist, except: [:show]

  def index
    @nutrition_plans = @patient.nutrition_plans.order(created_at: :desc)
  end

  def show
    # Verificar permisos: nutricionista o el mismo paciente
    unless current_user.nutritionist? || current_user.id == @patient.id
      redirect_to root_path, alert: "No tienes permiso para ver este plan."
      return
    end
  end

  def new
    @nutrition_plan = @patient.nutrition_plans.build
  end

  def edit
  end

  def create
    @nutrition_plan = @patient.nutrition_plans.build(nutrition_plan_params)
    @nutrition_plan.nutritionist = current_user

    if @nutrition_plan.save
      redirect_to patient_nutrition_plan_path(@patient, @nutrition_plan),
                  notice: "Plan nutricional creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @nutrition_plan.update(nutrition_plan_params)
      redirect_to patient_nutrition_plan_path(@patient, @nutrition_plan),
                  notice: "Plan nutricional actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @nutrition_plan.destroy
      redirect_to patient_nutrition_plans_path(@patient),
                  notice: "Plan nutricional eliminado exitosamente."
    else
      redirect_to patient_nutrition_plan_path(@patient, @nutrition_plan),
                  alert: "No se pudo eliminar el plan."
    end
  end

  # Generar sugerencia con IA
  # Soporta dos modos:
  # 1. AJAX (JSON) - devuelve JSON para prellenar dinámicamente
  # 2. Server-side - redirige a new con valores prellenados
  def generate_with_ai
    service = NutritionPlanGeneratorService.new(@patient)
    result = service.generate

    if result[:error]
      respond_to do |format|
        format.json { render json: { error: result[:error] }, status: :unprocessable_entity }
        format.html do
          redirect_to new_patient_nutrition_plan_path(@patient),
                      alert: "Error al generar sugerencia: #{result[:error]}"
        end
      end
    else
      respond_to do |format|
        format.json { render json: result, status: :ok }
        format.html do
          # Prellenar @nutrition_plan con los valores sugeridos
          @nutrition_plan = @patient.nutrition_plans.build(
            objective: result[:objective],
            calories: result[:calories],
            protein: result[:protein],
            fat: result[:fat],
            carbs: result[:carbs],
            meal_distribution: result[:meal_distribution],
            notes: result[:notes]
          )
          flash.now[:notice] = "Sugerencia generada con IA. Revisa y ajusta antes de guardar."
          render :new
        end
      end
    end
  end

  private

  def set_patient
    @patient = User.patients.find(params[:patient_id])
  end

  def set_nutrition_plan
    @nutrition_plan = @patient.nutrition_plans.find(params[:id])
  end

  def ensure_nutritionist
    unless current_user.nutritionist?
      redirect_to root_path, alert: "Solo los nutricionistas pueden realizar esta acción."
    end
  end

  def nutrition_plan_params
    params.require(:nutrition_plan).permit(
      :objective,
      :calories,
      :protein,
      :fat,
      :carbs,
      :notes,
      :status,
      meal_distribution: {}
    )
  end
end
