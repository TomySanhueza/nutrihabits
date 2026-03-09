class PatientRadarService
  Entry = Struct.new(:patient, :score, :priority_level, :reasons, :recommended_action, keyword_init: true)

  def initialize(nutritionist)
    @nutritionist = nutritionist
  end

  def call
    @nutritionist.patients.map do |patient|
      build_entry(patient)
    end.sort_by { |entry| -entry.score }
  end

  private

  def build_entry(patient)
    reasons = []
    score = 0

    unless patient.active_nutrition_plan
      reasons << "Sin plan nutricional activo"
      score += 35
    end

    if patient.weight_patients.where("date >= ?", 7.days.ago.to_date).none?
      reasons << "Sin registro de peso en 7 días"
      score += 20
    end

    if patient.meal_logs_through_plans.where("logged_at >= ?", 3.days.ago).none?
      reasons << "Sin comidas registradas en 3 días"
      score += 25
    end

    if patient.onboarding_state != "active"
      reasons << "Acceso a la app no activado"
      score += 20
    end

    Entry.new(
      patient: patient,
      score: score,
      priority_level: priority_level_for(score),
      reasons: reasons,
      recommended_action: recommended_action_for(score, reasons)
    )
  end

  def priority_level_for(score)
    return "high" if score >= 50
    return "medium" if score >= 25

    "low"
  end

  def recommended_action_for(score, reasons)
    return "Enviar seguimiento y revisar adherencia del paciente." if score >= 50
    return "Revisar registros recientes y plan activo." if reasons.any?

    "Mantener seguimiento habitual."
  end
end
