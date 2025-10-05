module PatientMetrics
  class GoalCalculator
    def initialize(patient_id)
      @patient = Patient.find(patient_id)
      @profile = @patient.profile
    end

    def daily_caloric_needs
      return { message: "Perfil incompleto - se requiere peso, altura y datos adicionales" } unless @profile&.weight && @profile&.height

      # Calcular TMB (Tasa Metabólica Basal) usando ecuación de Mifflin-St Jeor
      # Asumimos género masculino por defecto (ajustar si tienes campo de género)
      tmb = 10 * @profile.weight + 6.25 * @profile.height - 5 * 30 + 5 # 30 años asumidos

      # Factor de actividad basado en lifestyle
      activity_factor = get_activity_factor(@profile.lifestyle)
      total_daily_energy = (tmb * activity_factor).round(0)

      {
        tmb: tmb.round(0),
        activity_factor: activity_factor,
        activity_level: get_activity_level(@profile.lifestyle),
        total_daily_energy: total_daily_energy,
        recommendation: caloric_recommendation(total_daily_energy)
      }
    end

    def macro_distribution(total_calories, objective)
      # Distribuciones estándar según objetivo
      distributions = {
        "pérdida de peso" => { protein: 30, carbs: 35, fat: 35 },
        "mantenimiento" => { protein: 25, carbs: 45, fat: 30 },
        "ganancia muscular" => { protein: 30, carbs: 45, fat: 25 },
        "control glucémico" => { protein: 25, carbs: 40, fat: 35 }
      }

      dist = distributions[objective.downcase] || distributions["mantenimiento"]

      protein_cals = total_calories * (dist[:protein] / 100.0)
      carbs_cals = total_calories * (dist[:carbs] / 100.0)
      fat_cals = total_calories * (dist[:fat] / 100.0)

      {
        total_calories: total_calories,
        objective: objective,
        distribution_percentages: dist,
        grams: {
          protein: (protein_cals / 4).round(1),  # 4 kcal/g
          carbs: (carbs_cals / 4).round(1),      # 4 kcal/g
          fat: (fat_cals / 9).round(1)           # 9 kcal/g
        },
        calories_per_macro: {
          protein: protein_cals.round(0),
          carbs: carbs_cals.round(0),
          fat: fat_cals.round(0)
        }
      }
    end

    def estimate_time_to_goal(target_weight)
      current_weight = @profile&.weight
      return { message: "No se puede calcular sin peso actual" } unless current_weight

      weight_difference = target_weight - current_weight

      # Pérdida/ganancia saludable: 0.5-1 kg por semana
      safe_rate_per_week = weight_difference > 0 ? 0.5 : -0.75

      weeks_needed = (weight_difference / safe_rate_per_week).abs.round(0)
      months_needed = (weeks_needed / 4.33).round(1)

      {
        current_weight: current_weight,
        target_weight: target_weight,
        total_change_needed: weight_difference.round(1),
        direction: weight_difference > 0 ? "ganancia" : "pérdida",
        safe_rate_per_week: safe_rate_per_week.abs,
        estimated_weeks: weeks_needed,
        estimated_months: months_needed,
        estimated_date: Date.today + weeks_needed.weeks
      }
    end

    private

    def get_activity_factor(lifestyle)
      case lifestyle&.downcase
      when /sedentario|inactivo/
        1.2
      when /ligera|leve/
        1.375
      when /moderada/
        1.55
      when /activ[ao]|intensa/
        1.725
      when /muy activ[ao]|extrema/
        1.9
      else
        1.375 # Default: actividad ligera
      end
    end

    def get_activity_level(lifestyle)
      case lifestyle&.downcase
      when /sedentario|inactivo/ then "Sedentario"
      when /ligera|leve/ then "Actividad ligera"
      when /moderada/ then "Actividad moderada"
      when /activ[ao]|intensa/ then "Actividad intensa"
      when /muy activ[ao]|extrema/ then "Muy activo"
      else "Actividad ligera"
      end
    end

    def caloric_recommendation(tdee)
      {
        weight_loss: (tdee - 500).round(0),
        maintenance: tdee,
        muscle_gain: (tdee + 300).round(0)
      }
    end
  end
end
