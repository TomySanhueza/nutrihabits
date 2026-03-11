module PatientsHelper
  def patient_initials(patient)
    [
      patient.first_name&.first,
      patient.last_name&.first
    ].compact.join.upcase.presence || "PT"
  end

  def onboarding_state_name(state)
    case state.to_s
    when "draft"
      "Borrador"
    when "invited"
      "Invitado"
    when "active"
      "Activo"
    when "suspended"
      "Suspendido"
    else
      "Sin estado"
    end
  end

  def onboarding_state_badge_modifier(state)
    case state.to_s
    when "active"
      "success"
    when "invited"
      "warning"
    when "suspended"
      "danger"
    else
      "neutral"
    end
  end

  def nutrition_plan_status_name(status)
    case status.to_s
    when "draft"
      "Borrador"
    when "active"
      "Activo"
    when "completed"
      "Completado"
    else
      "Sin estado"
    end
  end

  def nutrition_plan_status_badge_modifier(status)
    case status.to_s
    when "active"
      "success"
    when "completed"
      "neutral"
    when "draft"
      "warning"
    else
      "neutral"
    end
  end

  def plan_presence_badge_modifier(active_plan)
    active_plan.present? ? "success" : "neutral"
  end

  def patient_primary_action(patient:, profile:, active_plan:)
    if profile.blank?
      { label: "Completar perfil", path: new_patient_profile_path(patient), method: nil }
    elsif active_plan.present?
      { label: "Ver plan activo", path: patient_nutrition_plan_path(patient, active_plan), method: nil }
    else
      { label: "Preparar plan", path: new_patient_nutrition_plan_path(patient), method: nil }
    end
  end

  def patient_access_action(patient)
    case patient.onboarding_state
    when "draft"
      { label: "Invitar a la app", path: invite_patient_path(patient), method: :post }
    when "invited"
      { label: "Reenviar invitación", path: resend_invite_patient_path(patient), method: :post }
    when "suspended"
      { label: "Reactivar acceso", path: reactivate_access_patient_path(patient), method: :post }
    else
      { label: "Suspender acceso", path: suspend_access_patient_path(patient), method: :post }
    end
  end

  def patient_last_seen_label(timestamp)
    return "Sin actividad reciente" if timestamp.blank?

    "Última actividad #{time_ago_in_words(timestamp)}"
  end

  def patient_profile_status(profile)
    profile.present? ? "Perfil completo" : "Perfil pendiente"
  end

  def formatted_weight(value, precision: 1)
    return "Sin dato" if value.blank?

    "#{number_with_precision(value, precision: precision, strip_insignificant_zeros: true)} kg"
  end

  def formatted_weight_change(change)
    return "Sin comparacion" if change.nil?

    prefix = change.positive? ? "+" : ""
    "#{prefix}#{number_with_precision(change, precision: 1, strip_insignificant_zeros: true)} kg"
  end

  def weight_change_caption(current_weight, previous_weight)
    return "Sin comparacion disponible" if current_weight.blank? || previous_weight.blank?

    "Comparado con #{formatted_weight(previous_weight)}"
  end

  def weight_trend_modifier(change)
    return "neutral" if change.nil? || change.zero?
    return "down" if change.negative?

    "up"
  end

  def formatted_bmi(value)
    return "Sin dato" if value.blank?

    number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
  end

  def formatted_quantity(value, unit:, precision: 0)
    return "Sin dato" if value.blank?

    "#{number_with_precision(value, precision: precision, strip_insignificant_zeros: true)} #{unit}"
  end

  def weight_entry_source_name(entry)
    case entry[:source].to_sym
    when :patient_history
      "Control clínico"
    when :weight_patient
      "Registro paciente"
    else
      "Registro"
    end
  end

  def weight_chart_points(entries, width:, height:, padding:)
    return [] if entries.blank?

    plot_width = width - (padding * 2)
    plot_height = height - (padding * 2)
    weights = entries.map { |entry| entry[:weight].to_f }
    min_weight = weights.min
    max_weight = weights.max
    weight_range = max_weight - min_weight

    entries.each_with_index.map do |entry, index|
      x = if entries.one?
        width / 2.0
      else
        padding + (plot_width * index.to_f / (entries.length - 1))
      end

      normalized = if weight_range.zero?
        0.5
      else
        (entry[:weight].to_f - min_weight) / weight_range.to_f
      end

      y = height - padding - (normalized * plot_height)

      { x: x.round(2), y: y.round(2), entry: entry }
    end
  end

  def weight_chart_line_path(points)
    return "" if points.blank?

    (
      ["M #{points.first[:x]},#{points.first[:y]}"] +
      points.drop(1).map { |point| "L #{point[:x]},#{point[:y]}" }
    ).join(" ")
  end

  def weight_chart_area_path(points, height:, padding:)
    return "" if points.blank?

    baseline = height - padding
    segments = points.map { |point| "L #{point[:x]},#{point[:y]}" }.join(" ")

    "M #{points.first[:x]},#{baseline} #{segments} L #{points.last[:x]},#{baseline} Z"
  end
end
