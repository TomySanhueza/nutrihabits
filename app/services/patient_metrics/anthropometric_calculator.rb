module PatientMetrics
  class AnthropometricCalculator
    def initialize(patient_id)
      @patient = Patient.find(patient_id)
      @profile = @patient.profile
    end

    def bmi
      return nil unless @profile&.weight && @profile&.height

      height_m = @profile.height / 100.0
      bmi_value = @profile.weight / (height_m ** 2)

      {
        value: bmi_value.round(2),
        category: bmi_category(bmi_value),
        interpretation: bmi_interpretation(bmi_value)
      }
    end

    def ideal_weight
      return nil unless @profile&.height

      # Fórmula de Devine (peso ideal en kg)
      height_cm = @profile.height
      base_weight = height_cm > 152 ? 50 : 45.5
      ideal = base_weight + 0.91 * (height_cm - 152.4)

      {
        value: ideal.round(1),
        formula: "Fórmula de Devine",
        current_weight: @profile.weight,
        difference: (@profile.weight - ideal).round(1)
      }
    end

    private

    def bmi_category(bmi)
      case bmi
      when 0..18.5 then "Bajo peso"
      when 18.5..24.9 then "Peso normal"
      when 25.0..29.9 then "Sobrepeso"
      when 30.0..34.9 then "Obesidad grado I"
      when 35.0..39.9 then "Obesidad grado II"
      else "Obesidad grado III"
      end
    end

    def bmi_interpretation(bmi)
      case bmi
      when 0..18.5 then "Por debajo del rango saludable"
      when 18.5..24.9 then "Dentro del rango saludable"
      when 25.0..29.9 then "Por encima del rango saludable"
      else "Riesgo elevado para la salud"
      end
    end
  end
end
