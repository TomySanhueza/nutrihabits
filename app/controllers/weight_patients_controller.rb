class WeightPatientsController < ApplicationController
  before_action :authenticate_patient!
  before_action :set_weight_patient, only: [:show, :edit, :update, :destroy]

  def index
    @weight_patients = current_patient.weight_patients.order(date: :desc)
  end

  def show
  end

  def new
    @weight_patient = current_patient.weight_patients.build(date: Date.today)
  end

  def create
    @weight_patient = current_patient.weight_patients.build(weight_patient_params)

    if @weight_patient.save
      redirect_to weight_patients_path, notice: 'Peso registrado exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @weight_patient.update(weight_patient_params)
      redirect_to @weight_patient, notice: 'Peso actualizado exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @weight_patient.destroy
    redirect_to weight_patients_path, notice: 'Registro de peso eliminado.'
  end

  private

  def set_weight_patient
    @weight_patient = current_patient.weight_patients.find(params[:id])
  end

  def weight_patient_params
    params.require(:weight_patient).permit(:weight, :date)
  end
end
