module NutritionPlansHelper
  def meal_type_icon(meal_type)
    case meal_type&.downcase
    when 'breakfast', 'desayuno'
      '🌅'
    when 'lunch', 'almuerzo', 'comida'
      '🍽️'
    when 'dinner', 'cena'
      '🌙'
    when 'snack', 'snacks', 'colación', 'merienda'
      '🍎'
    else
      '🍴'
    end
  end

  def meal_type_name(meal_type)
    case meal_type&.downcase
    when 'breakfast'
      'Desayuno'
    when 'lunch'
      'Almuerzo'
    when 'dinner'
      'Cena'
    when 'snack', 'snacks'
      'Snack'
    else
      meal_type&.capitalize || 'Comida'
    end
  end

  def meal_status_name(status)
    case status&.downcase
    when 'pending', 'pendiente'
      'Pendiente'
    when 'logged'
      'Registrada'
    when 'completed', 'completado', 'completada'
      'Completada'
    when 'skipped', 'omitida'
      'Omitida'
    else
      'Pendiente'
    end
  end

  def meal_status_modifier(status)
    case status&.downcase
    when "logged", "completed", "completado", "completada"
      "success"
    when "skipped", "omitida"
      "danger"
    else
      "warning"
    end
  end

  def nutrition_plan_macro_summary(plan)
    parts = []
    parts << "#{number_with_precision(plan.protein, precision: 0, strip_insignificant_zeros: true)} g P" if plan.protein.present?
    parts << "#{number_with_precision(plan.carbs, precision: 0, strip_insignificant_zeros: true)} g C" if plan.carbs.present?
    parts << "#{number_with_precision(plan.fat, precision: 0, strip_insignificant_zeros: true)} g G" if plan.fat.present?
    parts.join(" · ").presence || "Macros sin definir"
  end
end
