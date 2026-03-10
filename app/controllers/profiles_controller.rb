class ProfilesController < ApplicationController
  before_action :authenticate_nutritionist!
  before_action :set_patient

  def new
    # No olvidar crear la instancia @profile dentro de la aciión new y el código del create para guardar e formulario
    @profile = Profile.new
  end

  def create
    if @patient.profile.present?
      @profile = Profile.new(profile_params)
      @profile.errors.add(:base, "El paciente ya tiene un perfil.")
      render :new, status: :unprocessable_content
      return
    end

    @profile = @patient.build_profile(profile_params)
    if @profile.save
      redirect_to patient_path(@patient), notice: 'Perfil creado exitosamente.'
    else
      render :new, status: :unprocessable_content
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
