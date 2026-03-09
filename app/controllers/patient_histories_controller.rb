class PatientHistoriesController < ApplicationController
  before_action :authenticate_nutritionist!
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
    @patient_history = @patient.patient_histories.build
    @patient_history.assign_attributes(scoped_patient_history_params)
    @patient_history.nutritionist = current_nutritionist

    if @patient_history.errors.empty? && @patient_history.save
      redirect_to patient_patient_history_path(@patient, @patient_history), notice: 'Registro de control creado exitosamente.'
    else
      @nutrition_plans = @patient.nutrition_plans.where(status: 'active')
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @nutrition_plans = @patient.nutrition_plans
  end

  def update
    @patient_history.assign_attributes(scoped_patient_history_params)

    if @patient_history.errors.empty? && @patient_history.save
      redirect_to patient_patient_history_path(@patient, @patient_history), notice: 'Registro de control actualizado exitosamente.'
    else
      @nutrition_plans = @patient.nutrition_plans
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @patient_history.destroy
    redirect_to patient_patient_histories_path(@patient), notice: 'Registro de control eliminado exitosamente.'
  end

  private

  def set_patient
    @patient = current_nutritionist.patients.find(params[:patient_id])
  end

  def set_patient_history
    @patient_history = @patient.patient_histories.find(params[:id])
  end

  def patient_history_params
    params.require(:patient_history).permit(:visit_date, :notes, :weight, :metrics, :nutrition_plan_id)
  end

  def scoped_patient_history_params
    attrs = patient_history_params.to_h.symbolize_keys
    nutrition_plan_id = attrs.delete(:nutrition_plan_id)

    return attrs if nutrition_plan_id.blank?

    nutrition_plan = @patient.nutrition_plans.find_by(id: nutrition_plan_id)

    if nutrition_plan
      attrs[:nutrition_plan] = nutrition_plan
    else
      @patient_history.errors.add(:nutrition_plan, "must belong to the selected patient")
    end

    attrs
  end
end
