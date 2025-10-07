class PatientsController < ApplicationController
  #before_action :authenticate_patient!
  def index
    @patients = current_nutritionist.patients
  end
  def new
    @patient = Patient.new
  end

  def create
    @patient = Patient.new(patient_params)
    @patient.nutritionist_id = current_nutritionist.id
    @patient.password_confirmation = @patient.password

    if @patient.save
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
    params.require(:patient).permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone)
  end
end
