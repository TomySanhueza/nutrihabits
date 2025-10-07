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
    when 'completed', 'completado', 'completada'
      'Completada'
    when 'skipped', 'omitida'
      'Omitida'
    else
      'Pendiente'
    end
  end
end
