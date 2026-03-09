class ProfilesController < ApplicationController
  before_action :authenticate_nutritionist!
  before_action :set_patient

  def new
    # No olvidar crear la instancia @profile dentro de la aciión new y el código del create para guardar e formulario
    @profile = Profile.new
  end

  def create
    @profile = Profile.new(profile_params)
    @profile.patient_id = @patient.id
    @profile.nutritionist_id = current_nutritionist.id
    if @profile.save
      redirect_to patient_path(@patient), notice: 'Perfil creado exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_patient
    @patient = current_nutritionist.patients.find(params[:patient_id])
  end

  def profile_params
    params.require(:profile).permit(:weight, :height, :goals, :conditions, :lifestyle, :diagnosis)
  end
end
