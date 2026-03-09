class PatientsController < ApplicationController
  before_action :authenticate_nutritionist!
  before_action :set_patient, only: [:show, :invite, :resend_invite, :suspend_access, :reactivate_access]

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
    @profile = Profile.new
  end

  def invite
    @patient.update(onboarding_state: "invited", invitation_sent_at: Time.current)
    redirect_to patient_path(@patient), notice: "Invitación preparada para #{ @patient.email }."
  end

  def resend_invite
    @patient.update(invitation_sent_at: Time.current)
    redirect_to patient_path(@patient), notice: "Invitación reenviada."
  end

  def suspend_access
    @patient.update(onboarding_state: "suspended", access_suspended_at: Time.current)
    redirect_to patient_path(@patient), notice: "Acceso suspendido."
  end

  def reactivate_access
    @patient.update(onboarding_state: "active", access_suspended_at: nil)
    redirect_to patient_path(@patient), notice: "Acceso reactivado."
  end


  private

  def set_patient
    @patient = current_nutritionist.patients.find(params[:id])
  end

  def patient_params
    params.require(:patient).permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone)
  end
end
