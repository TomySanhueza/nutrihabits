class NutritionPlanGeneratorService
  require "json"

  def initialize(profile)
    @profile = profile
    @chat = RubyLLM.chat
  end
  
  def call
    system_prompt = <<-PROMPT
        Actúas como un Nutricionista Clínico Certificado, con experiencia en nutrición basada en evidencia científica
        (incluyendo guías de la OMS, ADA, ESPEN y consensos internacionales actualizados). 
        Tu especialidad es la alimentación saludable, el manejo de la obesidad, el control de enfermedades crónicas
        y la prevención a través de planes nutricionales personalizados.
      
        Recibirás información estructurada desde la base de datos del sistema, proveniente de estas fuentes:
        - Profile: datos básicos del paciente (#{@profile.weight},#{@profile.height},#{@profile.goals},#{@profile.conditions},#{@profile.lifestyle},#{@profile.diagnosis}).
        - Nutrition Plans (historial): planes nutricionales previos, incluyendo calorías, macros, objetivos, fechas y nivel de adherencia.
        - Patient Histories: registros de evolución en visitas anteriores (notas, métricas, peso, progresión clínica).
      
        Tu tarea:
          1. Generar un plan nutricional seguro y realista si el paciente es nuevo (sin planes previos).
          2. Ajustar o actualizar el plan si existen registros previos, considerando evolución y adherencia.
          3. Siempre entregar **dos outputs diferenciados**:
            - Un **plan estructurado en formato JSON válido** con la siguiente plantilla exacta:  
      
        {
          "objective": "string (ej: Pérdida de peso, Control glucémico, Ganancia muscular)",
          "calories": "integer (ej: 1800)",
          "protein": "float (en gramos/día, ej: 130)",
          "fat": "float (en gramos/día, ej: 60)",
          "carbs": "float (en gramos/día, ej: 200)",
          "meal_distribution": {
            "breakfast": ["variedad de desayunos completos prácticos para 7 días, cada uno con porciones sencillas e identificados por día"],
            "lunch": ["variedad de almuerzos completos prácticos para 7 días, cada uno con porciones sencillas e identificados por día"],
            "dinner": ["variedad de cenas completas prácticas para 7 días, cada una con porciones sencillas e identificados por día"],
            "snacks": ["variedad de snacks saludables para 7 días e identificados por día"]
          },
          "notes": "Recomendaciones generales adaptadas al estilo de vida y condiciones del paciente, en lenguaje sencillo."
        }
      
          - Un **texto explicativo separado** en formato string, llamado `criteria_explanation`, que detalle los criterios profesionales y científicos aplicados al plan, incluyendo:
            - Por qué se eligieron esas calorías y macronutrientes.
            - Cómo el plan responde a las condiciones clínicas del paciente.
            - Ajustes hechos respecto a planes anteriores.
            - Evidencia científica o guías clínicas consideradas.
      
        El output final debe ser con esta estructura:
      
        {
          "plan": { ...estructura anterior... },
          "criteria_explanation": "texto explicativo con la lógica profesional y científica del plan"
        }
      
        Reglas:
        - Usa cantidades claras y realistas en calorías y macros.
        - Prioriza prevención y control de riesgos clínicos.
        - El plan debe ser comprensible para el paciente.
        - El campo `criteria_explanation` está dirigido al nutricionista, debe ser breve pero profesional.
        
        Crea el plan personalizado para este paciente.
    PROMPT

    JSON.parse((@chat.ask(system_prompt)).content)
  end
end
