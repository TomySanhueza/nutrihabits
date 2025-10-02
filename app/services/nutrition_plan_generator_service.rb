class NutritionPlanGeneratorService
  def initialize(patient)
    @patient = patient
    @profile = patient.profile
    @patient_histories = patient.patient_histories.order(visit_date: :desc).limit(3)
  end

  def generate
    return { error: "No se encontró perfil del paciente" } unless @profile

    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_prompt }
        ],
        temperature: 0.7,
        response_format: { type: "json_object" }
      }
    )

    parse_response(response)
  rescue StandardError => e
    Rails.logger.error("NutritionPlanGeneratorService error: #{e.full_message}")
    { error: "Error al generar plan: #{e.message}" }
  end

  private

  def system_prompt
    <<~PROMPT
      Actúa como un Nutricionista Clínico Certificado, con experiencia en nutrición basada en evidencia científica (incluyendo guías de la OMS, ADA, ESPEN y consensos internacionales actualizados). Tu especialidad es la alimentación saludable, el manejo de la obesidad, el control de enfermedades crónicas y la prevención a través de planes nutricionales personalizados.
      Recibirás la información de un paciente (datos de perfil e historial registrado por su nutricionista tratante).
      A partir de estos datos deberás generar un plan nutricional seguro, realista y adaptado a las necesidades del paciente.
      Debes responder exclusivamente con un objeto JSON válido con esta estructura exacta:

      {
        "objective": "descripción del objetivo nutricional",
        "calories": número de calorías diarias recomendadas,
        "protein": gramos de proteína diarios,
        "fat": gramos de grasas diarias,
        "carbs": gramos de carbohidratos diarios,
        "meal_distribution": {
          "breakfast": { "calories": número, "description": "descripción" },
          "lunch": { "calories": número, "description": "descripción" },
          "dinner": { "calories": número, "description": "descripción" },
          "snacks": { "calories": número, "description": "descripción" }
        },
        "notes": "recomendaciones adicionales y consideraciones especiales"
      }
    PROMPT
  end

  def user_prompt
    prompt = <<~PROMPT
      Con la información proporcionada a continuación, genera un plan nutricional personalizado, seguro y basado en evidencia científica actualizada.
      El plan debe priorizar la prevención y el manejo de riesgos clínicos relevantes (obesidad, sobrepeso, diabetes, hipertensión u otras condiciones registradas).
      Considera también el estilo de vida y los objetivos declarados por el paciente.

      DATOS PERSONALES:
      - Nombre: #{@patient.first_name} #{@patient.last_name}
      - Peso: #{@profile.weight} kg
      - Altura: #{@profile.height} cm
      - IMC: #{calculate_bmi}
    PROMPT

    if @profile.goals.present?
      prompt += "\nOBJETIVOS:\n#{@profile.goals}\n"
    end

    if @profile.conditions.present?
      prompt += "\nCONDICIONES MÉDICAS:\n#{@profile.conditions}\n"
    end

    if @profile.lifestyle.present?
      prompt += "\nESTILO DE VIDA:\n#{@profile.lifestyle}\n"
    end

    if @patient_histories.any?
      prompt += "\nHISTORIAL RECIENTE:\n"
      @patient_histories.each do |history|
        prompt += "- #{history.visit_date}: Peso #{history.weight}kg. #{history.notes}\n"
      end
    end

    prompt += <<~PROMPT
      Genera un plan nutricional estructurado según la plantilla solicitada en el system prompt.
      - Usa cantidades numéricas claras en calorías y macronutrientes.
      - Ajusta las recomendaciones a las condiciones clínicas y estilo de vida del paciente.
      - El lenguaje de las descripciones debe ser claro, breve y práctico (pensado para que un paciente pueda entenderlo).
    PROMPT

    prompt
  end

  def calculate_bmi
    return "N/A" unless @profile.weight && @profile.height

    height_m = @profile.height / 100.0
    bmi = @profile.weight / (height_m ** 2)
    bmi.round(1)
  end

  def parse_response(response)
    content = response.dig("choices", 0, "message", "content")
    return { error: "No se recibió respuesta de la IA" } unless content

    parsed = JSON.parse(content)

    # Normalizar valores numéricos
    calories = normalize_number(parsed["calories"])
    protein = normalize_number(parsed["protein"])
    fat = normalize_number(parsed["fat"])
    carbs = normalize_number(parsed["carbs"])

    {
      objective: parsed["objective"]&.to_s,
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      meal_distribution: parsed["meal_distribution"] || {},
      notes: parsed["notes"]&.to_s
    }
  rescue JSON::ParserError => e
    { error: "Error al parsear respuesta: #{e.message}" }
  end

  def normalize_number(value)
    return nil if value.nil?

    # Si es string, extraer el número
    if value.is_a?(String)
      # Extraer primer número encontrado en el string
      match = value.match(/\d+\.?\d*/)
      return match ? match[0].to_f : nil
    end

    value.to_f
  end
end
