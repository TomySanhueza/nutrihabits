class NutritionistAICopilotService
  require "json"

  def initialize(nutritionist_ai_chat)
    @chat_record = nutritionist_ai_chat
    @nutritionist = nutritionist_ai_chat.nutritionist
    @llm_chat = RubyLLM.chat(model: 'gpt-4o-mini')
    setup_tools
  end

  def ask(message, &block)
    start_time = Time.current
    tools_called = []

    # Agregar mensaje del usuario al historial
    user_message = @chat_record.nutritionist_ai_messages.create!(
      role: 'user',
      content: message,
      metadata: {
        timestamp: start_time.iso8601,
        role: 'user'
      }
    )

    # Cargar historial de conversación
    load_conversation_history

    # Configurar instrucciones del sistema
    @llm_chat.with_instructions(system_prompt)

    # Hacer la pregunta al LLM con streaming
    assistant_content = ""

    # Hook para rastrear herramientas utilizadas
    @llm_chat.on_tool_call do |tool_name, tool_args|
      tools_called << {
        name: tool_name,
        arguments: tool_args,
        timestamp: Time.current.iso8601
      }
    end

    @llm_chat.ask(message) do |chunk|
      assistant_content += chunk.content
      yield chunk.content if block_given?
    end

    # Calcular tiempo de respuesta
    end_time = Time.current
    response_time_ms = ((end_time - start_time) * 1000).round(2)

    # Calcular safety flags
    safety_flags = calculate_safety_flags(message, assistant_content)

    # Guardar respuesta del asistente con metadata completa
    @chat_record.nutritionist_ai_messages.create!(
      role: 'assistant',
      content: assistant_content,
      metadata: {
        model: 'gpt-4o-mini',
        response_time_ms: response_time_ms,
        tools_called: tools_called.map { |t| t[:name] },
        tools_details: tools_called,
        timestamp: end_time.iso8601,
        safety_flags: safety_flags,
        message_length: assistant_content.length,
        user_message_length: message.length
      }
    )

    assistant_content
  end

  private

  def system_prompt
    <<-PROMPT
      Eres un asistente experto en nutrición clínica que apoya a nutricionistas profesionales.
      Tu rol es ayudar al Dr./Dra. #{@nutritionist.first_name} #{@nutritionist.last_name} con sus pacientes.

      **Tienes acceso completo a:**
      - Información de todos los pacientes del nutricionista (#{@nutritionist.patients.count} pacientes)
      - Perfiles de salud, historial médico, condiciones
      - Planes nutricionales activos e históricos
      - Registros de comidas y análisis nutricional
      - Evolución de peso y métricas antropométricas

      **Tus capacidades:**
      - Calcular indicadores (IMC, peso ideal, TMB, etc.)
      - Analizar progreso y adherencia a planes
      - Comparar consumo real vs planificado
      - Identificar patrones y tendencias
      - Sugerir ajustes basados en evidencia científica

      **Pautas de respuesta:**
      - Usa terminología profesional pero clara
      - Cita fuentes científicas cuando sea relevante
      - Sé específico con datos numéricos
      - Ofrece recomendaciones prácticas
      - Si el nutricionista pregunta por un paciente específico, usa las herramientas para obtener datos en tiempo real
      - Siempre menciona si detectas algo que requiera atención clínica

      **Importante:**
      - No tomes decisiones clínicas, solo apoya con información y análisis
      - Si no tienes datos suficientes, indícalo claramente
      - Prioriza la seguridad del paciente en todas tus respuestas
    PROMPT
  end

  def load_conversation_history
    # Cargar mensajes previos de la conversación
    previous_messages = @chat_record.nutritionist_ai_messages
      .where.not(id: @chat_record.nutritionist_ai_messages.last&.id) # Excluir el último (ya agregado)
      .order(created_at: :asc)
      .last(10) # Últimos 10 mensajes para contexto

    previous_messages.each do |msg|
      if msg.role == 'user'
        @llm_chat.say msg.content
      else
        # Para mensajes del asistente, necesitamos simular que ya fueron respondidos
        # ruby_llm maneja esto internamente
      end
    end
  end

  def setup_tools
    # Registrar todas las herramientas disponibles
    register_anthropometric_tools
    register_progress_tools
    register_nutrition_tools
    register_goal_tools
    register_data_retrieval_tools
  end

  def register_anthropometric_tools
    @llm_chat.with_tool(CalculateBMITool)
    @llm_chat.with_tool(CalculateIdealWeightTool)
  end

  def register_progress_tools
    @llm_chat.with_tool(GetWeightEvolutionTool)
    @llm_chat.with_tool(CalculateWeightLossRateTool)
  end

  def register_nutrition_tools
    @llm_chat.with_tool(GetPlanAdherenceTool)
    @llm_chat.with_tool(GetMacroComplianceTool)
    @llm_chat.with_tool(GetAverageDailyIntakeTool)
  end

  def register_goal_tools
    @llm_chat.with_tool(CalculateDailyCaloricNeedsTool)
    @llm_chat.with_tool(CalculateMacroDistributionTool)
    @llm_chat.with_tool(EstimateTimeToGoalTool)
  end

  def register_data_retrieval_tools
    @llm_chat.with_tool(GetPatientProfileTool)
    @llm_chat.with_tool(ListAllPatientsTool)
    @llm_chat.with_tool(GetActiveNutritionPlanTool)
  end

  def calculate_safety_flags(user_message, assistant_response)
    {
      potentially_harmful_advice: detect_harmful_advice(assistant_response),
      data_privacy_concern: detect_privacy_concern(user_message, assistant_response),
      excessive_tool_usage: detect_excessive_tools,
      response_quality_low: detect_low_quality_response(assistant_response)
    }
  end

  def detect_harmful_advice(response)
    harmful_patterns = [
      /dieta (muy )?restrictiv[ao]/i,
      /ayun[oa] prolongad[oa]/i,
      /eliminación completa de/i,
      /menos de \d{3,4} calor[ií]as/i,
      /suspender medicación/i,
      /reemplazar tratamiento/i
    ]
    harmful_patterns.any? { |pattern| response.match?(pattern) }
  end

  def detect_privacy_concern(user_msg, assistant_msg)
    # Detectar si se mencionan datos sensibles sin contexto apropiado
    privacy_patterns = [
      /n[úu]mero de documento/i,
      /dirección exacta/i,
      /tel[ée]fono personal/i,
      /historia cl[ií]nica completa/i
    ]
    (user_msg + assistant_msg).match?(Regexp.union(privacy_patterns))
  end

  def detect_excessive_tools
    # Si se llamaron más de 8 herramientas en una sola respuesta, puede ser señal de problema
    @tools_called_count ||= 0
    @tools_called_count > 8
  end

  def detect_low_quality_response(response)
    # Respuestas muy cortas o genéricas
    response.length < 50 || response.match?(/^(s[ií]|no|ok|entendido)\.?$/i)
  end
end

# ============= TOOLS DEFINITIONS =============

# Anthropometric Tools
class CalculateBMITool < RubyLLM::Tool
  description "Calcula el Índice de Masa Corporal (IMC) de un paciente"
  param :patient_id, type: :integer, required: true

  def execute(patient_id:)
    PatientMetrics::AnthropometricCalculator.new(patient_id).bmi
  end
end

class CalculateIdealWeightTool < RubyLLM::Tool
  description "Calcula el peso ideal de un paciente según fórmula de Devine"
  param :patient_id, type: :integer, required: true

  def execute(patient_id:)
    PatientMetrics::AnthropometricCalculator.new(patient_id).ideal_weight
  end
end

# Progress Tools
class GetWeightEvolutionTool < RubyLLM::Tool
  description "Obtiene la evolución del peso de un paciente en un período de días"
  param :patient_id, type: :integer, required: true
  param :days, type: :integer, required: false

  def execute(patient_id:, days: 30)
    PatientMetrics::ProgressAnalyzer.new(patient_id).weight_evolution(days)
  end
end

class CalculateWeightLossRateTool < RubyLLM::Tool
  description "Calcula la tasa de pérdida/ganancia de peso por semana"
  param :patient_id, type: :integer, required: true
  param :period_days, type: :integer, required: false

  def execute(patient_id:, period_days: 30)
    PatientMetrics::ProgressAnalyzer.new(patient_id).weight_loss_rate(period_days)
  end
end

# Nutrition Tools
class GetPlanAdherenceTool < RubyLLM::Tool
  description "Calcula el porcentaje de adherencia a un plan nutricional"
  param :nutrition_plan_id, type: :integer, required: true

  def execute(nutrition_plan_id:)
    PatientMetrics::NutritionAnalyzer.new(NutritionPlan.find(nutrition_plan_id).patient_id).plan_adherence(nutrition_plan_id)
  end
end

class GetMacroComplianceTool < RubyLLM::Tool
  description "Compara el consumo real de macronutrientes vs el plan"
  param :nutrition_plan_id, type: :integer, required: true
  param :days, type: :integer, required: false

  def execute(nutrition_plan_id:, days: 7)
    PatientMetrics::NutritionAnalyzer.new(NutritionPlan.find(nutrition_plan_id).patient_id).macro_compliance(nutrition_plan_id, days)
  end
end

class GetAverageDailyIntakeTool < RubyLLM::Tool
  description "Obtiene el promedio de ingesta diaria de un paciente"
  param :patient_id, type: :integer, required: true
  param :days, type: :integer, required: false

  def execute(patient_id:, days: 7)
    PatientMetrics::NutritionAnalyzer.new(patient_id).average_daily_intake(days)
  end
end

# Goal Tools
class CalculateDailyCaloricNeedsTool < RubyLLM::Tool
  description "Calcula las necesidades calóricas diarias (TMB + gasto energético)"
  param :patient_id, type: :integer, required: true

  def execute(patient_id:)
    PatientMetrics::GoalCalculator.new(patient_id).daily_caloric_needs
  end
end

class CalculateMacroDistributionTool < RubyLLM::Tool
  description "Calcula la distribución de macronutrientes según objetivo"
  param :total_calories, type: :integer, required: true
  param :objective, type: :string, required: true

  def execute(total_calories:, objective:)
    PatientMetrics::GoalCalculator.new(nil).macro_distribution(total_calories, objective)
  end
end

class EstimateTimeToGoalTool < RubyLLM::Tool
  description "Estima el tiempo necesario para alcanzar un peso objetivo"
  param :patient_id, type: :integer, required: true
  param :target_weight, type: :number, required: true

  def execute(patient_id:, target_weight:)
    PatientMetrics::GoalCalculator.new(patient_id).estimate_time_to_goal(target_weight)
  end
end

# Data Retrieval Tools
class GetPatientProfileTool < RubyLLM::Tool
  description "Obtiene el perfil completo de un paciente"
  param :patient_id, type: :integer, required: true

  def execute(patient_id:)
    patient = Patient.find(patient_id)
    {
      id: patient.id,
      nombre: "#{patient.first_name} #{patient.last_name}",
      email: patient.email,
      perfil: patient.profile ? {
        peso: patient.profile.weight,
        altura: patient.profile.height,
        objetivos: patient.profile.goals,
        condiciones: patient.profile.conditions,
        estilo_vida: patient.profile.lifestyle,
        diagnostico: patient.profile.diagnosis
      } : nil
    }
  end
end

class ListAllPatientsTool < RubyLLM::Tool
  description "Lista todos los pacientes del nutricionista"
  param :nutritionist_id, type: :integer, required: true

  def execute(nutritionist_id:)
    patients = Nutritionist.find(nutritionist_id).patients
    {
      total: patients.count,
      pacientes: patients.map do |p|
        {
          id: p.id,
          nombre: "#{p.first_name} #{p.last_name}",
          email: p.email,
          tiene_plan_activo: p.nutrition_plans.where(status: 'active').exists?
        }
      end
    }
  end
end

class GetActiveNutritionPlanTool < RubyLLM::Tool
  description "Obtiene el plan nutricional activo de un paciente"
  param :patient_id, type: :integer, required: true

  def execute(patient_id:)
    plan = Patient.find(patient_id).nutrition_plans.find_by(status: 'active')
    return { message: "No hay plan activo" } unless plan

    {
      id: plan.id,
      objetivo: plan.objective,
      calorias: plan.calories,
      proteinas: plan.protein,
      carbohidratos: plan.carbs,
      grasas: plan.fat,
      fecha_inicio: plan.start_date,
      fecha_fin: plan.end_date,
      notas: plan.notes
    }
  end
end
