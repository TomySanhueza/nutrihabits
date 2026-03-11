class NutritionistsController < ApplicationController
  before_action :authenticate_nutritionist!

  PATIENT_SUMMARY_LIMIT = 5
  ATTENTION_LIMIT = 3
  RECENT_PLAN_LIMIT = 5
  DASHBOARD_EPOCH = Time.utc(1970, 1, 1)

  def dashboard
    patients = dashboard_patients
    summaries = patients.map { |patient| build_patient_summary(patient) }

    @dashboard_stats = build_dashboard_stats(patients)
    @patient_summaries = sort_patient_summaries(summaries).first(PATIENT_SUMMARY_LIMIT)
    @recent_nutrition_plans = current_nutritionist
      .nutrition_plans
      .includes(:patient)
      .order(start_date: :desc, updated_at: :desc)
      .limit(RECENT_PLAN_LIMIT)

    @dashboard_attention = {
      pending_access_patients: summaries.select { |summary| summary[:onboarding_state] != "active" }.first(ATTENTION_LIMIT),
      patients_without_active_plan: summaries.select { |summary| summary[:active_plan].nil? }.first(ATTENTION_LIMIT),
      patients_without_profile: summaries.reject { |summary| summary[:profile_complete] }.first(ATTENTION_LIMIT)
    }
  end

  def patient_radar
    @radar_entries = PatientRadarService.new(current_nutritionist).call
  end

  private

  def dashboard_patients
    current_nutritionist
      .patients
      .includes(:profile, :weight_patients, nutrition_plans: { plans: { meals: :meal_log } })
      .order(updated_at: :desc, id: :desc)
      .to_a
  end

  def build_dashboard_stats(patients)
    {
      total_patients: patients.count,
      active_plans: patients.sum { |patient| active_plans_for(patient).count },
      patients_without_active_plan: patients.count { |patient| active_plans_for(patient).empty? },
      pending_access: patients.count { |patient| patient.onboarding_state != "active" }
    }
  end

  def build_patient_summary(patient)
    active_plan = active_plan_for(patient)
    primary_cta = primary_cta_for(patient, active_plan)

    {
      patient: patient,
      active_plan: active_plan,
      profile_complete: patient.profile.present?,
      onboarding_state: patient.onboarding_state,
      last_activity_at: last_activity_at_for(patient),
      last_weight: last_weight_for(patient),
      primary_cta_label: primary_cta[:label],
      primary_cta_path: primary_cta[:path],
      secondary_cta_path: patient_path(patient)
    }
  end

  def sort_patient_summaries(summaries)
    summaries.sort_by do |summary|
      [
        -patient_summary_priority(summary),
        -(summary[:last_activity_at]&.to_i || 0),
        -summary[:patient].id
      ]
    end
  end

  def patient_summary_priority(summary)
    priority = 0
    priority += 3 unless summary[:profile_complete]
    priority += 2 if summary[:onboarding_state] != "active"
    priority += 1 if summary[:active_plan].nil?
    priority
  end

  def active_plan_for(patient)
    active_plans_for(patient).max_by do |plan|
      [
        plan.end_date || Date.new(1970, 1, 1),
        plan.updated_at || DASHBOARD_EPOCH
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
    latest_weight_entry = patient.weight_patients.max_by do |entry|
      [
        entry.date || Date.new(1970, 1, 1),
        entry.updated_at || DASHBOARD_EPOCH
      ]
    end

    latest_weight_entry&.weight || patient.profile&.weight
  end

  def primary_cta_for(patient, active_plan)
    if patient.profile.blank?
      { label: "Completar perfil", path: new_patient_profile_path(patient) }
    elsif active_plan.nil?
      { label: "Preparar plan", path: new_patient_nutrition_plan_path(patient) }
    elsif patient.nutrition_plans.any?
      { label: "Ver planes", path: patient_nutrition_plans_path(patient) }
    else
      { label: "Ver paciente", path: patient_path(patient) }
    end
  end
end
