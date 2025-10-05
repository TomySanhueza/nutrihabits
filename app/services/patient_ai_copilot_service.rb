class PatientAICopilotService
  require "json"

  def initialize(patient_ai_chat)
    @chat_record = patient_ai_chat
    @patient = patient_ai_chat.patient
    @llm_chat = RubyLLM.chat(model: 'gpt-4o-mini')
    setup_tools
  end

  def ask(message, &block)
    # Medir tiempo de respuesta
    start_time = Time.current

    # Agregar mensaje del usuario
    user_message = @chat_record.patient_ai_messages.create!(
      role: 'user',
      content: message,
      metadata: {
        timestamp: Time.current.iso8601
      }
    )

    # Cargar historial
    load_conversation_history

    # Configurar instrucciones del sistema
    @llm_chat.with_instructions(system_prompt)

    # Hacer la pregunta con streaming
    assistant_content = ""
    tools_called = []

    @llm_chat.ask(message) do |chunk|
      assistant_content += chunk.content
      yield chunk.content if block_given?
    end

    # Calcular safety flags
    safety_flags = calculate_safety_flags(message, assistant_content)

    # Guardar respuesta con metadata completa
    response_time_ms = ((Time.current - start_time) * 1000).to_i

    @chat_record.patient_ai_messages.create!(
      role: 'assistant',
      content: assistant_content,
      metadata: {
        model: 'gpt-4o-mini',
        response_time_ms: response_time_ms,
        tools_called: tools_called,
        timestamp: Time.current.iso8601,
        safety_flags: safety_flags
      }
    )

    assistant_content
  end

  private

  def system_prompt
    active_plan = @patient.nutrition_plans.find_by(status: 'active')
    plan_info = active_plan ? "Tu plan: #{active_plan.objective} - #{active_plan.calories} kcal/día" : "Sin plan activo"

    <<-PROMPT
      Eres un asistente nutricional personal y empático para #{@patient.first_name}.
      Tu misión es apoyar y motivar al paciente a seguir su plan nutricional de forma exitosa.

      **Información del paciente:**
      - Nombre: #{@patient.first_name} #{@patient.last_name}
      - #{plan_info}
      - Peso actual: #{@patient.profile&.weight} kg
      - Objetivos: #{@patient.profile&.goals}

      **Tu rol específico:**
      1. **Soporte nutricional 24/7**: Responde dudas sobre el plan, recetas, ingredientes, preparaciones
      2. **Motivación y empatía**: Celebra logros, apoya en momentos difíciles, sé comprensivo
      3. **Resolución práctica**: Ayuda con sustituciones de ingredientes, opciones fuera de casa, adaptaciones
      4. **Educación nutricional**: Explica el "por qué" del plan de forma clara y cercana
      5. **Seguimiento**: Analiza progreso, consumo diario, adherencia

      **Límites estrictos (MUY IMPORTANTE):**
      NO des consejos médicos generales
      NO trates temas fuera de nutrición y hábitos alimenticios
      NO sugieras cambiar el plan sin consultar al nutricionista
      NO diagnostiques condiciones médicas

      Si el paciente pregunta sobre:
      - Otros temas de salud → "Te recomiendo consultar con tu médico especialista"
      - Temas no relacionados → "Mi especialidad es nutrición y hábitos saludables"
      - Cambiar el plan → "Tu plan fue diseñado por un profesional. Consultemos con tu nutricionista"

      **Tono y estilo:**
      - Cálido, cercano y motivador
      - Usa lenguaje simple, evita tecnicismos excesivos
      - Sé positivo pero honesto
      - Si se saltó una comida, sé empático: "Entiendo que a veces es difícil. ¿Qué podemos hacer ahora?"
      - Celebra pequeños logros: "¡Muy bien! Llevas 3 días seguidos registrando tus comidas"

      **Usa las herramientas disponibles** para dar respuestas precisas con datos reales del paciente.
    PROMPT
  end

  def load_conversation_history
    previous_messages = @chat_record.patient_ai_messages
      .where.not(id: @chat_record.patient_ai_messages.last&.id)
      .order(created_at: :asc)
      .last(10)

    previous_messages.each do |msg|
      @llm_chat.say msg.content if msg.role == 'user'
    end
  end

  def calculate_safety_flags(user_message, assistant_response)
    {
      off_topic: detect_off_topic(user_message),
      medical_advice_detected: detect_medical_advice(user_message),
      plan_deviation_suggested: detect_plan_deviation(assistant_response),
      negative_sentiment: detect_negative_sentiment(user_message)
    }
  end

  def detect_off_topic(message)
    off_topic_keywords = ['futbol', 'política', 'clima', 'noticias', 'película']
    off_topic_keywords.any? { |keyword| message.downcase.include?(keyword) }
  end

  def detect_medical_advice(message)
    medical_keywords = ['dolor', 'enfermedad', 'síntoma', 'medicamento', 'doctor', 'hospital']
    medical_keywords.any? { |keyword| message.downcase.include?(keyword) }
  end

  def detect_plan_deviation(response)
    deviation_keywords = ['saltarte', 'omitir', 'no sigas', 'cambia el plan']
    deviation_keywords.any? { |keyword| response.downcase.include?(keyword) }
  end

  def detect_negative_sentiment(message)
    negative_keywords = ['no puedo', 'imposible', 'frustrado', 'rendirse', 'fracaso']
    negative_keywords.any? { |keyword| message.downcase.include?(keyword) }
  end

  def setup_tools
    register_plan_tools
    register_progress_tools
    register_meal_tools
    register_utility_tools
  end

  def register_plan_tools
    @llm_chat.with_tool(GetMyNutritionPlanTool)
    @llm_chat.with_tool(GetTodaysMealsTool)
  end

  def register_progress_tools
    @llm_chat.with_tool(GetMyProgressTool)
    @llm_chat.with_tool(CalculateTodaysIntakeTool)
    @llm_chat.with_tool(GetAchievementSummaryTool)
  end

  def register_meal_tools
    @llm_chat.with_tool(GetRecipeDetailsTool)
    @llm_chat.with_tool(SuggestMealAlternativeTool)
    @llm_chat.with_tool(CheckMealCompatibilityTool)
  end

  def register_utility_tools
    @llm_chat.with_tool(GetShoppingListTool)
    @llm_chat.with_tool(CalculateHydrationNeedsTool)
  end
end

# ============= PATIENT TOOLS DEFINITIONS =============

# Plan Tools
class GetMyNutritionPlanTool < RubyLLM::Tool
  description "Obtiene el plan nutricional activo del paciente"
  param :patient_id, type: :integer, required: true

  def execute(patient_id:)
    plan = Patient.find(patient_id).nutrition_plans.find_by(status: 'active')
    return { message: "No tienes un plan activo actualmente" } unless plan

    {
      objetivo: plan.objective,
      calorias_diarias: plan.calories,
      proteinas: plan.protein,
      carbohidratos: plan.carbs,
      grasas: plan.fat,
      fecha_inicio: plan.start_date,
      fecha_fin: plan.end_date,
      notas: plan.notes
    }
  end
end

class GetTodaysMealsTool < RubyLLM::Tool
  description "Obtiene las comidas planificadas para hoy"
  param :patient_id, type: :integer, required: true

  def execute(patient_id:)
    PatientMetrics::PatientSelfMetrics.new(patient_id).todays_meals
  end
end

# Progress Tools
class GetMyProgressTool < RubyLLM::Tool
  description "Obtiene el progreso de peso del paciente en los últimos días"
  param :patient_id, type: :integer, required: true
  param :days, type: :integer, required: false

  def execute(patient_id:, days: 30)
    PatientMetrics::PatientSelfMetrics.new(patient_id).my_progress(days)
  end
end

class CalculateTodaysIntakeTool < RubyLLM::Tool
  description "Calcula las calorías y macros consumidos hoy"
  param :patient_id, type: :integer, required: true

  def execute(patient_id:)
    PatientMetrics::PatientSelfMetrics.new(patient_id).todays_intake
  end
end

class GetAchievementSummaryTool < RubyLLM::Tool
  description "Obtiene resumen de logros y adherencia al plan"
  param :patient_id, type: :integer, required: true

  def execute(patient_id:)
    PatientMetrics::PatientSelfMetrics.new(patient_id).achievement_summary
  end
end

# Meal Tools
class GetRecipeDetailsTool < RubyLLM::Tool
  description "Obtiene detalles completos de una receta de una comida"
  param :meal_id, type: :integer, required: true

  def execute(meal_id:)
    meal = Meal.find(meal_id)
    {
      tipo: meal.meal_type,
      ingredientes: meal.ingredients,
      receta: meal.recipe,
      calorias: meal.calories,
      proteinas: meal.protein,
      carbohidratos: meal.carbs,
      grasas: meal.fat
    }
  end
end

class SuggestMealAlternativeTool < RubyLLM::Tool
  description "Sugiere alternativas cuando falta un ingrediente"
  param :meal_id, type: :integer, required: true
  param :missing_ingredient, type: :string, required: true

  def execute(meal_id:, missing_ingredient:)
    meal = Meal.find(meal_id)

    # Sugerencias básicas por tipo de ingrediente
    suggestions = {
      "pollo" => { alternatives: ["pavo", "pescado blanco", "tofu"], tipo: "proteína" },
      "arroz" => { alternatives: ["quinoa", "pasta integral", "batata"], tipo: "carbohidrato" },
      "brócoli" => { alternatives: ["coliflor", "espinaca", "acelga"], tipo: "vegetal" }
    }

    key = missing_ingredient.downcase
    suggestion = suggestions[key] || { alternatives: ["consulta opciones similares en valor nutricional"], tipo: "general" }

    {
      ingrediente_faltante: missing_ingredient,
      tipo_nutriente: suggestion[:tipo],
      alternativas_sugeridas: suggestion[:alternatives],
      macros_originales: {
        calorias: meal.calories,
        proteinas: meal.protein,
        carbohidratos: meal.carbs,
        grasas: meal.fat
      },
      recomendacion: "Intenta mantener macros similares. Consulta a tu nutricionista si tienes dudas."
    }
  end
end

class CheckMealCompatibilityTool < RubyLLM::Tool
  description "Verifica si puede hacer la receta con ingredientes disponibles"
  param :meal_id, type: :integer, required: true
  param :available_ingredients, type: :string, required: true

  def execute(meal_id:, available_ingredients:)
    meal = Meal.find(meal_id)
    required = meal.ingredients.downcase.split(',').map(&:strip)
    available = available_ingredients.downcase.split(',').map(&:strip)

    missing = required - available
    can_make = missing.empty?

    {
      puede_preparar: can_make,
      ingredientes_requeridos: required,
      ingredientes_disponibles: available,
      ingredientes_faltantes: missing,
      compatibilidad: can_make ? "100%" : "#{((available.count.to_f / required.count) * 100).round(0)}%"
    }
  end
end

# Utility Tools
class GetShoppingListTool < RubyLLM::Tool
  description "Genera lista de compras para los próximos días"
  param :patient_id, type: :integer, required: true
  param :days, type: :integer, required: false

  def execute(patient_id:, days: 7)
    PatientMetrics::PatientSelfMetrics.new(patient_id).shopping_list(days)
  end
end

class CalculateHydrationNeedsTool < RubyLLM::Tool
  description "Calcula necesidades de hidratación diaria"
  param :patient_id, type: :integer, required: true

  def execute(patient_id:)
    PatientMetrics::PatientSelfMetrics.new(patient_id).hydration_needs
  end
end
