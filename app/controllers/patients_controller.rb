class PatientsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_nutritionist, except: [:show]
  before_action :set_patient, only: [:show, :edit, :update, :destroy]

  def index
    @patients = User.patients
                    .includes(:profile, :nutrition_plans, :patient_histories)
                    .order(created_at: :desc)
  end

  def show
    # Verificar que el usuario actual puede ver este paciente
    # (nutricionista o el mismo paciente)
    unless current_user.nutritionist? || current_user.id == @patient.id
      redirect_to root_path, alert: "No tienes permiso para ver este paciente."
      return
    end

    @profile = @patient.profile || @patient.build_profile
    @nutrition_plans = @patient.nutrition_plans.order(created_at: :desc)
    @patient_histories = @patient.patient_histories.order(visit_date: :desc)
    @meal_logs = @patient.meal_logs.order(logged_at: :desc).limit(10)
    @daily_check_ins = @patient.daily_check_ins.order(date: :desc).limit(7)
  end

  def new
    @patient = User.new(role: "patient")
    @patient.build_profile
  end

  def edit
    @profile = @patient.profile || @patient.build_profile
  end

  def create
    @patient = User.new(patient_params)
    @patient.role = "patient"

    # Generar contraseña temporal
    temp_password = SecureRandom.hex(8)
    @patient.password = temp_password
    @patient.password_confirmation = temp_password

    if @patient.save
      redirect_to patient_path(@patient), notice: "Paciente creado exitosamente. Contraseña temporal: #{temp_password}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @patient.update(patient_params)
      redirect_to patient_path(@patient), notice: "Paciente actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @patient.destroy
      redirect_to patients_path, notice: "Paciente eliminado exitosamente."
    else
      redirect_to patient_path(@patient), alert: "No se pudo eliminar el paciente."
    end
  end

  private

  def set_patient
    @patient = User.patients.find_by(id: params[:id])
    redirect_to patients_path, alert: "Paciente no encontrado." unless @patient
  end

  def ensure_nutritionist
    unless current_user.nutritionist?
      redirect_to root_path, alert: "Solo los nutricionistas pueden realizar esta acción."
    end
  end

  def patient_params
    params.require(:user).permit(
      :email,
      :first_name,
      :last_name,
      :phone,
      :user_photo,
      profile_attributes: [:id, :weight, :height, :goals, :conditions, :lifestyle]
    )
  end
end
