module NutritionistsHelper
  def nutritionist_backoffice_initials(user)
    [
      user.first_name&.first,
      user.last_name&.first
    ].compact.join.upcase.presence || "NH"
  end

  def nutritionist_backoffice_date_range(start_date, end_date)
    if start_date.present? && end_date.present?
      "#{l(start_date, format: :short)} - #{l(end_date, format: :short)}"
    elsif start_date.present?
      "Desde #{l(start_date, format: :short)}"
    elsif end_date.present?
      "Hasta #{l(end_date, format: :short)}"
    else
      "Sin vigencia definida"
    end
  end

  def nutritionist_backoffice_badge_class(tone)
    "nh-badge nh-badge--#{tone}"
  end

  def nutritionist_dashboard_access_label(onboarding_state)
    case onboarding_state
    when "active"
      "App activa"
    when "invited"
      "Invitacion enviada"
    when "suspended"
      "Acceso suspendido"
    else
      "Acceso pendiente"
    end
  end

  def nutritionist_dashboard_access_tone(onboarding_state)
    case onboarding_state
    when "active"
      "success"
    when "invited"
      "warning"
    when "suspended"
      "danger"
    else
      "muted"
    end
  end

  def nutritionist_dashboard_activity_label(last_activity_at)
    return "Sin actividad reciente" if last_activity_at.blank?

    "Última actividad #{time_ago_in_words(last_activity_at)}"
  end

  def nutritionist_dashboard_plan_label(plan)
    return "Sin plan activo" if plan.blank?

    case plan.status
    when "completed"
      "Plan completado"
    when "draft"
      "Plan en borrador"
    else
      "Plan activo"
    end
  end

  def nutritionist_dashboard_plan_tone(plan)
    return "muted" if plan.blank?

    case plan.status
    when "completed"
      "muted"
    when "draft"
      "warning"
    else
      "success"
    end
  end

  def nutritionist_dashboard_attention_copy(group_key)
    case group_key
    when :pending_access_patients
      "Pacientes con acceso pendiente"
    when :patients_without_active_plan
      "Pacientes sin plan activo"
    when :patients_without_profile
      "Pacientes sin perfil completo"
    else
      group_key.to_s.humanize
    end
  end

  def nutritionist_dashboard_empty_attention_copy(group_key)
    case group_key
    when :pending_access_patients
      "No hay accesos pendientes."
    when :patients_without_active_plan
      "Todos los pacientes visibles tienen plan activo."
    when :patients_without_profile
      "No hay perfiles pendientes en los pacientes visibles."
    else
      "Sin elementos pendientes."
    end
  end
end
