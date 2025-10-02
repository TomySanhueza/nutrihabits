class ProfilesController < ApplicationController
  before_action :set_profile, only: [:show, :edit, :update]

  def show; 
  end
  def edit;
  end

  def update
    if @profile.update(profile_params)
      redirect_to profile_path, notice: "Perfil actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    # Carga el perfil del usuario logueado
    @profile = current_user.profile || current_user.create_profile
  end

  def profile_params
    params.require(:profile).permit(:weight, :height, :goals, :conditions, :lifestyle)
  end
end
