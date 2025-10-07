class PatientsController < ApplicationController

  def index
    @patients = current_nutritionist.patients
  end
  def new
    @patient = Patient.new
  end

  def create
    @patient = Patient.new(patient_params)
    @patient.nutritionist_id = current_nutritionist.id 
    if @patient.save
      #sign_in(@patient)
      redirect_to @patient, notice: 'Cuenta creada exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show 
    @patient = Patient.find(params[:id])
    @profile = Profile.new
  end

  private

  def patient_params
    params.require(:patient).permit(:email, :password, :first_name, :last_name, :phone)
  end
end
