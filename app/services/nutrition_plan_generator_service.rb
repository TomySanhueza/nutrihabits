class NutritionPlanGeneratorService
  class GenerationError < StandardError; end

  def initialize(patient:, nutritionist:, start_date:, end_date:, chat: RubyLLM.chat)
    @patient = patient
    @nutritionist = nutritionist
    @profile = patient.profile
    @start_date = start_date
    @end_date = end_date
    @chat = chat
  end

  def call
    raise GenerationError, "Patient profile is required" unless @profile

    payload = parse_payload(@chat.ask(build_prompt).content)
    persist_plan!(payload)
  rescue GenerationError
    raise
  rescue JSON::ParserError, ActiveRecord::RecordInvalid, KeyError, Date::Error => error
    raise GenerationError, error.message
  rescue StandardError => error
    raise GenerationError, error.message
  end

  private

  def build_prompt
    <<~PROMPT
      Actuas como un Nutricionista Clinico Certificado, con experiencia en nutricion basada en evidencia cientifica
      (incluyendo guias de la OMS, ADA, ESPEN y consensos internacionales actualizados).
      Tu especialidad es la alimentacion saludable, el manejo de la obesidad, el control de enfermedades cronicas
      y la prevencion a traves de planes nutricionales personalizados.

      Recibiras informacion estructurada desde la base de datos del sistema, proveniente de estas fuentes:
      - Paciente: #{patient_summary}
      - Profile: datos basicos del paciente (#{@profile.weight}, #{@profile.height}, #{@profile.goals}, #{@profile.conditions}, #{@profile.lifestyle}, #{@profile.diagnosis}).
      - Nutrition Plans (historial): #{previous_plans_summary}
      - Patient Histories: #{patient_histories_summary}

      Tu tarea:
        1. Generar un plan nutricional seguro y realista si el paciente es nuevo (sin planes previos).
        2. Ajustar o actualizar el plan si existen registros previos, considerando evolucion y adherencia.
        3. Desarrolla un plan con alcance desde la fecha inicial #{@start_date} hasta la fecha final #{@end_date}, incluyendolas ambas.
        4. Siempre entregar dos outputs diferenciados:
          - Un plan estructurado en formato JSON valido con esta estructura:
          {
            "plan": {
              "objective": "string",
              "calories": 1800.0,
              "protein": 130.0,
              "fat": 60.0,
              "carbs": 200.0,
              "meal_distribution": {
                "YYYY-MM-DD": {
                  "breakfast": {
                    "ingredients": "string",
                    "recipe": "string",
                    "calorias": 400.0,
                    "protein": 20.0,
                    "carbs": 50.0,
                    "fat": 10.0
                  },
                  "lunch": { "...": "..." },
                  "dinner": { "...": "..." },
                  "snacks": { "...": "..." }
                }
              },
              "notes": "string"
            },
            "criteria_explanation": "string"
          }

      Atencion: debes generar automaticamente un bloque de meal_distribution para cada dia del rango de fechas, sin omitir dias.
      Cada fecha debe estar en formato YYYY-MM-DD y contener desayuno, almuerzo, cena y snack cuando corresponda.

      Reglas:
      - Usa cantidades claras y realistas en calorias y macros.
      - Prioriza prevencion y control de riesgos clinicos.
      - El plan debe ser comprensible para el paciente.
      - criteria_explanation debe ser breve pero profesional.
    PROMPT
  end

  def patient_summary
    [@patient.first_name, @patient.last_name].compact.join(" ").strip.presence || @patient.email
  end

  def previous_plans_summary
    plans = @patient.nutrition_plans.order(start_date: :desc).limit(3)
    return "Sin planes previos" if plans.empty?

    plans.map do |plan|
      [
        "objective=#{plan.objective}",
        "dates=#{plan.start_date}-#{plan.end_date}",
        "status=#{plan.status}",
        "calories=#{plan.calories}"
      ].join(", ")
    end.join(" | ")
  end

  def patient_histories_summary
    histories = @patient.patient_histories.order(created_at: :desc).limit(3)
    return "Sin historial clinico registrado" if histories.empty?

    histories.map do |history|
      [
        history.visit_date,
        history.notes,
        history.metrics
      ].compact.join(" | ")
    end.join(" | ")
  end

  def parse_payload(raw_content)
    cleaned_content = raw_content.to_s.gsub(/```json\s*/i, "").gsub(/```\s*/i, "").strip
    payload = JSON.parse(cleaned_content)

    validate_payload!(payload)
    payload
  end

  def validate_payload!(payload)
    plan_data = payload.fetch("plan")
    meal_distribution = plan_data.fetch("meal_distribution")
    raise GenerationError, "meal_distribution must be a Hash" unless meal_distribution.is_a?(Hash)

    expected_dates = (@start_date..@end_date).map(&:to_s)
    missing_dates = expected_dates - meal_distribution.keys
    raise GenerationError, "meal_distribution is missing dates: #{missing_dates.join(', ')}" if missing_dates.any?

    meal_distribution.each do |date_str, daily_meals|
      Date.iso8601(date_str)
      raise GenerationError, "daily meals must be a Hash for #{date_str}" unless daily_meals.is_a?(Hash)

      daily_meals.each do |meal_type, meal_data|
        raise GenerationError, "meal data must be a Hash for #{date_str}/#{meal_type}" unless meal_data.is_a?(Hash)

        %w[ingredients recipe calorias protein carbs fat].each do |field|
          raise GenerationError, "missing #{field} for #{date_str}/#{meal_type}" if meal_data[field].blank?
        end
      end
    end
  end

  def persist_plan!(payload)
    plan_data = payload.fetch("plan")
    meal_distribution = plan_data.fetch("meal_distribution")

    NutritionPlan.transaction do
      nutrition_plan = @patient.nutrition_plans.create!(
        objective: plan_data.fetch("objective"),
        calories: plan_data.fetch("calories"),
        protein: plan_data.fetch("protein"),
        fat: plan_data.fetch("fat"),
        carbs: plan_data.fetch("carbs"),
        meal_distribution: meal_distribution,
        notes: plan_data["notes"],
        ai_rationale: payload["criteria_explanation"],
        nutritionist: @nutritionist,
        status: "active",
        start_date: @start_date,
        end_date: @end_date
      )

      meal_distribution.each do |date_str, daily_meals|
        plan = nutrition_plan.plans.create!(date: Date.iso8601(date_str))

        daily_meals.each do |meal_type, meal_data|
          plan.meals.create!(
            meal_type: normalize_meal_type(meal_type),
            ingredients: meal_data.fetch("ingredients"),
            recipe: meal_data.fetch("recipe"),
            calories: meal_data.fetch("calorias"),
            protein: meal_data.fetch("protein"),
            carbs: meal_data.fetch("carbs"),
            fat: meal_data.fetch("fat"),
            status: "pending"
          )
        end
      end

      nutrition_plan
    end
  end

  def normalize_meal_type(value)
    value.to_s.strip.downcase.singularize
  end
end
