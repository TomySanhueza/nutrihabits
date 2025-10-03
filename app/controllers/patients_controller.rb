class PatientsController < ApplicationController

  def index

  end
  def new
    @patient = Patient.new
  end

  def create
    @patient = Patient.new(patient_params)
    @patient.nutritionist_id = current_nutritionist.id 
    if @patient.save
      #sign_in(@patient)
      redirect_to nutritionist_dashboard_path, notice: 'Cuenta creada exitosamente.'
    else
      render :new
    end
  end

  def show 
    
  end

  private

  def patient_params
    params.require(:patient).permit(:email, :password, :first_name, :last_name, :phone)
  end
end
