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

  # Acción AJAX para generar sugerencia con IA
  # No persiste nada, solo devuelve JSON para prellenar el formulario
  def generate_with_ai
    service = NutritionPlanGeneratorService.new(@patient)
    result = service.generate

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      # Devolver la sugerencia como JSON para que el front prellene el form
      render json: result, status: :ok
    end
  end

  private

  def set_patient
    @patient = User.patients.find_by(id: params[:patient_id])
    unless @patient
      redirect_to patients_path, alert: "Paciente no encontrado."
    end
  end

  def set_nutrition_plan
    @nutrition_plan = @patient.nutrition_plans.find_by(id: params[:id])
    unless @nutrition_plan
      redirect_to patient_nutrition_plans_path(@patient), alert: "Plan nutricional no encontrado."
    end
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
      :meal_distribution,
      :notes,
      :status
    )
  end
end
