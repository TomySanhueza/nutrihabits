class PatientsController < ApplicationController
  before_action :authenticate_nutritionist!
  before_action :set_patient, only: [:show, :invite, :resend_invite, :suspend_access, :reactivate_access]

  def index
    patients = current_nutritionist
      .patients
      .includes(:profile, :weight_patients, nutrition_plans: { plans: { meals: :meal_log } })
      .order(updated_at: :desc, id: :desc)

    patients = patients.where(
      "first_name ILIKE :query OR last_name ILIKE :query OR email ILIKE :query",
      query: "%#{params[:search].to_s.strip}%"
    ) if params[:search].present?

    @patients = patients.to_a
    @patient_rows = @patients.map { |patient| build_patient_row(patient) }
    @patient_index_stats = {
      total_patients: @patients.count,
      active_plans: @patient_rows.count { |row| row[:active_plan].present? },
      pending_access: @patients.count { |patient| patient.onboarding_state != "active" },
      patients_without_profile: @patients.count { |patient| patient.profile.blank? }
    }
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
      render :new, status: :unprocessable_content
    end
  end

  def show
    @profile = @patient.profile
    @nutrition_plans = @patient.nutrition_plans.order(start_date: :desc, created_at: :desc)
    @active_plan = @patient.active_nutrition_plan

    patient_histories = @patient.patient_histories
      .includes(:nutrition_plan)
      .order(visit_date: :desc, created_at: :desc)

    @recent_patient_histories = patient_histories.limit(5)
    @weight_entries = build_weight_entries(
      patient_histories: patient_histories,
      weight_patients: @patient.weight_patients.order(date: :desc, created_at: :desc)
    )
    @current_weight = @weight_entries.last&.dig(:weight) || @profile&.weight
    @previous_weight = @weight_entries[-2]&.dig(:weight)
    @weight_change = if @current_weight.present? && @previous_weight.present?
      @current_weight - @previous_weight
    end
    @bmi = calculate_bmi(weight: @current_weight, height_cm: @profile&.height)
    @latest_meal_log_at = @patient.meal_logs_through_plans.maximum(:logged_at)
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

  def build_weight_entries(patient_histories:, weight_patients:)
    entries = patient_histories.filter_map do |history|
      build_weight_entry(
        record: history,
        date: history.visit_date,
        weight: history.weight,
        source: :patient_history,
        priority: 0,
        nutrition_plan: history.nutrition_plan,
        created_at: history.created_at
      )
    end

    entries.concat(weight_patients.filter_map do |weight_patient|
      build_weight_entry(
        record: weight_patient,
        date: weight_patient.date,
        weight: weight_patient.weight,
        source: :weight_patient,
        priority: 1,
        created_at: weight_patient.created_at
      )
    end)

    entries
      .group_by { |entry| entry[:date] }
      .values
      .map { |group| group.min_by { |entry| [ entry[:priority], -(entry[:created_at]&.to_i || 0) ] } }
      .sort_by { |entry| entry[:date] }
  end

  def build_weight_entry(record:, date:, weight:, source:, priority:, nutrition_plan: nil, created_at: nil)
    return if date.blank? || weight.blank?

    {
      record: record,
      date: date,
      weight: weight.to_f,
      source: source,
      priority: priority,
      created_at: created_at || record.created_at,
      nutrition_plan: nutrition_plan
    }
  end

  def calculate_bmi(weight:, height_cm:)
    return if weight.blank? || height_cm.blank?

    height_m = height_cm.to_f / 100.0
    return if height_m <= 0

    weight.to_f / (height_m**2)
  end

  def build_patient_row(patient)
    active_plan = active_plan_for(patient)

    {
      patient: patient,
      profile_complete: patient.profile.present?,
      active_plan: active_plan,
      last_weight: last_weight_for(patient),
      last_activity_at: last_activity_at_for(patient)
    }
  end

  def active_plan_for(patient)
    active_plans_for(patient).max_by do |plan|
      [
        plan.end_date || Date.new(1970, 1, 1),
        plan.updated_at || Time.utc(1970, 1, 1)
      ]
    end
  end

  def active_plans_for(patient)
    patient.nutrition_plans.select do |plan|
      active_date_window?(plan) || plan.status == "active"
    end
  end

  def active_date_window?(plan)
    return false if plan.start_date.blank? || plan.end_date.blank?

    plan.start_date <= Date.current && plan.end_date >= Date.current
  end

  def last_activity_at_for(patient)
    [
      patient.last_seen_at,
      latest_meal_log_at_for(patient),
      latest_weight_logged_at_for(patient),
      patient.nutrition_plans.filter_map(&:updated_at).max,
      patient.invitation_sent_at,
      patient.updated_at
    ].compact.max
  end

  def latest_meal_log_at_for(patient)
    patient.nutrition_plans.flat_map(&:plans).flat_map(&:meals).filter_map do |meal|
      meal.meal_log&.logged_at
    end.max
  end

  def latest_weight_logged_at_for(patient)
    patient.weight_patients.filter_map do |entry|
      entry.date&.in_time_zone&.end_of_day
    end.max
  end

  def last_weight_for(patient)
    entry = patient.weight_patients.max_by do |weight_patient|
      [
        weight_patient.date || Date.new(1970, 1, 1),
        weight_patient.updated_at || Time.utc(1970, 1, 1)
      ]
    end

    entry&.weight || patient.profile&.weight
  end
end
