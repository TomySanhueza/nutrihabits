class ProfilesController < ApplicationController
  def new
    # No olvidar crear la instancia @profile dentro de la aciión new y el código del create para guardar e formulario
    @profile = Profile.new
    @patient = Patient.find(params[:patient_id])
  end

  def create
    @patient = Patient.find(params[:patient_id])
    @profile = Profile.new(profile_params)
    @profile.patient_id = @patient.id
    @profile.nutritionist_id = current_nutritionist.id
    if @profile.save
      redirect_to patient_path(@patient), notice: 'Perfil creado exitosamente.'
    else
      render :new
    end
  end

  private

  def profile_params
    params.require(:profile).permit(:weight, :height, :goals, :conditions, :lifestyle, :diagnosis)
  end
end

