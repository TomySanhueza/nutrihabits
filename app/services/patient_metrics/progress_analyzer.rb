module PatientMetrics
  class ProgressAnalyzer
    def initialize(patient_id)
      @patient = Patient.find(patient_id)
    end

    def weight_evolution(days = 30)
      weights = @patient.weight_patients
        .where('date >= ?', days.days.ago)
        .order(date: :asc)
        .pluck(:date, :weight)

      return { message: "No hay registros de peso en los últimos #{days} días" } if weights.empty?

      {
        period_days: days,
        data_points: weights.map { |date, weight| { date: date, weight: weight } },
        start_weight: weights.first[1],
        current_weight: weights.last[1],
        total_change: (weights.last[1] - weights.first[1]).round(2),
        trend: calculate_trend(weights)
      }
    end

    def weight_loss_rate(period_days = 30)
      evolution = weight_evolution(period_days)
      return evolution if evolution[:message] # No hay datos

      total_change = evolution[:total_change]
      rate_per_week = (total_change / period_days * 7).round(2)

      {
        period_days: period_days,
        total_change_kg: total_change,
        rate_per_week_kg: rate_per_week,
        rate_per_month_kg: (rate_per_week * 4.33).round(2),
        status: weight_change_status(rate_per_week)
      }
    end

    def calculate_bmi_change(days = 30)
      weights = weight_evolution(days)
      return weights if weights[:message]

      profile = @patient.profile
      return { message: "No se puede calcular IMC sin altura" } unless profile&.height

      height_m = profile.height / 100.0
      start_bmi = weights[:start_weight] / (height_m ** 2)
      current_bmi = weights[:current_weight] / (height_m ** 2)

      {
        start_bmi: start_bmi.round(2),
        current_bmi: current_bmi.round(2),
        bmi_change: (current_bmi - start_bmi).round(2),
        period_days: days
      }
    end

    private

    def calculate_trend(weights)
      return "estable" if weights.size < 2

      changes = weights.each_cons(2).map { |a, b| b[1] - a[1] }
      avg_change = changes.sum / changes.size

      if avg_change < -0.1
        "descendente"
      elsif avg_change > 0.1
        "ascendente"
      else
        "estable"
      end
    end

    def weight_change_status(rate_per_week)
      case rate_per_week
      when -Float::INFINITY..-1.0
        "Pérdida acelerada (revisar)"
      when -1.0..-0.3
        "Pérdida saludable"
      when -0.3..0.3
        "Mantenimiento"
      when 0.3..1.0
        "Ganancia controlada"
      else
        "Ganancia acelerada (revisar)"
      end
    end
  end
end
