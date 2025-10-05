class PatientHistoriesController < ApplicationController
  before_action :set_patient
  before_action :set_patient_history, only: [:show, :edit, :update, :destroy]

  def index
    @patient_histories = @patient.patient_histories.order(visit_date: :desc)
  end

  def show
  end

  def new
    @patient_history = @patient.patient_histories.build
    @nutrition_plans = @patient.nutrition_plans.where(status: 'active')
  end

  def create
    @patient_history = @patient.patient_histories.build(patient_history_params)
    @patient_history.nutritionist = current_nutritionist

    if @patient_history.save
      redirect_to patient_patient_history_path(@patient, @patient_history), notice: 'Registro de control creado exitosamente.'
    else
      @nutrition_plans = @patient.nutrition_plans.where(status: 'active')
      render :new
    end
  end

  def edit
    @nutrition_plans = @patient.nutrition_plans
  end

  def update
    if @patient_history.update(patient_history_params)
      redirect_to patient_patient_history_path(@patient, @patient_history), notice: 'Registro de control actualizado exitosamente.'
    else
      @nutrition_plans = @patient.nutrition_plans
      render :edit
    end
  end

  def destroy
    @patient_history.destroy
    redirect_to patient_patient_histories_path(@patient), notice: 'Registro de control eliminado exitosamente.'
  end

  private

  def set_patient
    @patient = Patient.find(params[:patient_id])
  end

  def set_patient_history
    @patient_history = @patient.patient_histories.find(params[:id])
  end

  def patient_history_params
    params.require(:patient_history).permit(:visit_date, :notes, :weight, :metrics, :nutrition_plan_id)
  end
end
