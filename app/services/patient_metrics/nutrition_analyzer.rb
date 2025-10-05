module PatientMetrics
  class NutritionAnalyzer
    def initialize(patient_id)
      @patient = Patient.find(patient_id)
    end

    def plan_adherence(nutrition_plan_id)
      plan = NutritionPlan.find(nutrition_plan_id)
      total_meals = plan.plans.joins(:meals).count
      completed_meals = plan.plans.joins(:meals).where(meals: { status: 'completed' }).count

      return { message: "No hay comidas registradas en este plan" } if total_meals.zero?

      adherence_percentage = (completed_meals.to_f / total_meals * 100).round(2)

      {
        nutrition_plan_id: nutrition_plan_id,
        total_meals: total_meals,
        completed_meals: completed_meals,
        pending_meals: total_meals - completed_meals,
        adherence_percentage: adherence_percentage,
        status: adherence_status(adherence_percentage)
      }
    end

    def macro_compliance(nutrition_plan_id, days = 7)
      plan = NutritionPlan.find(nutrition_plan_id)

      # Obtener meal_logs recientes con sus macros
      meal_logs = MealLog.joins(meal: { plan: :nutrition_plan })
        .where(nutrition_plans: { id: nutrition_plan_id })
        .where('meal_logs.logged_at >= ?', days.days.ago)

      return { message: "No hay registros de comidas en los últimos #{days} días" } if meal_logs.empty?

      avg_calories = meal_logs.average(:ai_calories).to_f.round(1)
      avg_protein = meal_logs.average(:ai_protein).to_f.round(1)
      avg_carbs = meal_logs.average(:ai_carbs).to_f.round(1)
      avg_fat = meal_logs.average(:ai_fat).to_f.round(1)

      {
        period_days: days,
        plan_targets: {
          calories: plan.calories,
          protein: plan.protein,
          carbs: plan.carbs,
          fat: plan.fat
        },
        actual_averages: {
          calories: avg_calories,
          protein: avg_protein,
          carbs: avg_carbs,
          fat: avg_fat
        },
        compliance: {
          calories: calculate_compliance_percentage(avg_calories, plan.calories),
          protein: calculate_compliance_percentage(avg_protein, plan.protein),
          carbs: calculate_compliance_percentage(avg_carbs, plan.carbs),
          fat: calculate_compliance_percentage(avg_fat, plan.fat)
        }
      }
    end

    def average_daily_intake(days = 7)
      meal_logs = @patient.meal_logs_through_plans
        .where('logged_at >= ?', days.days.ago)

      return { message: "No hay registros de comidas en los últimos #{days} días" } if meal_logs.empty?

      {
        period_days: days,
        total_logs: meal_logs.count,
        daily_average: {
          calories: meal_logs.average(:ai_calories).to_f.round(1),
          protein: meal_logs.average(:ai_protein).to_f.round(1),
          carbs: meal_logs.average(:ai_carbs).to_f.round(1),
          fat: meal_logs.average(:ai_fat).to_f.round(1)
        },
        health_score_average: meal_logs.average(:ai_health_score).to_f.round(2)
      }
    end

    def health_scores_trend(days = 30)
      scores = @patient.meal_logs_through_plans
        .where('logged_at >= ?', days.days.ago)
        .order(logged_at: :asc)
        .pluck(:logged_at, :ai_health_score)

      return { message: "No hay registros suficientes" } if scores.empty?

      {
        period_days: days,
        data_points: scores.map { |date, score| { date: date, score: score } },
        average_score: (scores.sum { |_, score| score } / scores.size.to_f).round(2),
        trend: calculate_health_trend(scores)
      }
    end

    private

    def adherence_status(percentage)
      case percentage
      when 0..50 then "Baja adherencia - requiere intervención"
      when 50..70 then "Adherencia moderada - necesita apoyo"
      when 70..85 then "Buena adherencia"
      else "Excelente adherencia"
      end
    end

    def calculate_compliance_percentage(actual, target)
      return 0 if target.nil? || target.zero?
      ((actual / target) * 100).round(1)
    end

    def calculate_health_trend(scores)
      return "sin datos" if scores.size < 2

      first_half = scores.first(scores.size / 2).map(&:last).sum / (scores.size / 2).to_f
      second_half = scores.last(scores.size / 2).map(&:last).sum / (scores.size / 2).to_f

      if second_half > first_half + 0.5
        "mejorando"
      elsif second_half < first_half - 0.5
        "empeorando"
      else
        "estable"
      end
    end
  end
end
