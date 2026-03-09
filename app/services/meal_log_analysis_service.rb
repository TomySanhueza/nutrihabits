class MealLogAnalysisService
  require "json"

  def initialize(photo_attachment, meal)
    @photo = photo_attachment
    @meal = meal # El meal específico para ese día y tipo de comida
    @plan = meal.plan # El plan del día
    @nutrition_plan = meal.plan.nutrition_plan # El plan nutricional general
    @chat = RubyLLM.chat(model: 'gpt-4-vision-preview')
  end

  def call
    system_prompt = generate_system_prompt
    @chat.with_instructions(system_prompt)
    analyze
  end

  private

  def analyze
    begin
      # Obtener la URL pública directa de la imagen
      image_url = if Rails.env.production?
        # En producción, usar url directa de Cloudinary
        @photo.url
      else
        # En desarrollo, usar URL de Active Storage
        Rails.application.routes.url_helpers.url_for(@photo)
      end

      message = {
        role: "user",
        content: [
          { type: "text", text: analysis_prompt },
          { type: "image_url", image_url: { url: image_url } }
        ]
      }

      response = @chat.call(messages: [message])
      result = JSON.parse(response.content)

      # Validar que todos los campos requeridos estén presentes
      required_fields = ["ai_calories", "ai_protein", "ai_carbs", "ai_fat", 
                        "ai_health_score", "ai_feedback", "ai_comparison"]
      
      missing_fields = required_fields - result.keys
      if missing_fields.any?
        raise "La respuesta no contiene todos los campos requeridos. Faltan: #{missing_fields.join(', ')}"
      end

      # Asegurarse de que los valores numéricos sean números
      result["ai_calories"] = result["ai_calories"].to_f
      result["ai_protein"] = result["ai_protein"].to_f
      result["ai_carbs"] = result["ai_carbs"].to_f
      result["ai_fat"] = result["ai_fat"].to_f
      result["ai_health_score"] = result["ai_health_score"].to_f

      result
    rescue JSON::ParserError => e
      Rails.logger.error "Error parseando JSON: #{e.message}"
      Rails.logger.error "Contenido recibido: #{response.content}"
      raise "Error al procesar la respuesta de la IA: el formato no es válido"
    rescue StandardError => e
      Rails.logger.error "Error analizando imagen: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise "Error al analizar la imagen: #{e.message}"
    end
  end

  def generate_system_prompt
    <<-PROMPT
      Actúas como un **Nutricionista Clínico Certificado**, con experiencia en nutrición basada en evidencia científica
      (incluyendo guías de la OMS, ADA, ESPEN y consensos internacionales actualizados).
      Tu especialidad es el análisis dietético práctico, el control de peso y la prevención de enfermedades crónicas
      a través de alimentación equilibrada y planes nutricionales personalizados.

      Recibirás una **imagen de una comida registrada por un paciente** en la aplicación Nutrihabits.
      Tu tarea es analizar visualmente la foto y generar un registro nutricional completo y coherente con el plan actual del paciente, considerando:

      - **El plan nutricional activo** asignado por su nutricionista (niveles de calorías, macros y objetivos clínicos).
      - **La comida específica planificada** para ese día y tipo de comida (breakfast/lunch/dinner/snack).
      - **El contenido visual de la imagen** (tipo y proporción de alimentos, métodos de cocción y equilibrio general del plato).

      #{plan_context}
      #{meal_context}

      Debes entregar **una respuesta estructurada en formato JSON válido**, con los siguientes campos exactos:
      {
        "ai_calories": float,
        "ai_protein": float,
        "ai_carbs": float,
        "ai_fat": float,
        "ai_health_score": float,
        "ai_feedback": string,
        "ai_comparison": {
          "macronutrient_comparison": string,
          "ingredient_analysis": string,
          "improvement_suggestion": string
        }
      }
    PROMPT
  end

  def plan_context
    return "El paciente no tiene un plan nutricional activo en este momento." unless @nutrition_plan

    <<-CONTEXT
      **Información del plan nutricional activo:**
      - Objetivo: #{@nutrition_plan.objective}
      - Calorías diarias: #{@nutrition_plan.calories} kcal
      - Proteína diaria total: #{@nutrition_plan.protein}g
      - Carbohidratos diarios totales: #{@nutrition_plan.carbs}g
      - Grasas diarias totales: #{@nutrition_plan.fat}g
      - Notas adicionales del nutricionista: #{@nutrition_plan.notes}
    CONTEXT
  end

  def meal_context
    return "No hay información de la comida planificada para este momento." unless @meal

    <<-CONTEXT
      **Información de la comida planificada:**
      - Tipo de comida: #{meal_type_spanish(@meal.meal_type)}
      - Fecha: #{@plan.date}
      - Calorías planificadas: #{@meal.calories}kcal
      - Proteína planificada: #{@meal.protein}g
      - Carbohidratos planificados: #{@meal.carbs}g
      - Grasas planificadas: #{@meal.fat}g
      - Ingredientes propuestos: #{@meal.ingredients}
      - Receta sugerida: #{@meal.recipe}
      - Estado: #{@meal.status}

      **IMPORTANTE:** Compara la comida de la foto con esta comida planificada específica.
    CONTEXT
  end

  def analysis_prompt
    <<-PROMPT
      Por favor, analiza esta comida considerando:
      
      #{plan_context}
      #{meal_context}

      Genera una respuesta en formato JSON válido según las instrucciones anteriores.
    PROMPT
  end

  def meal_type_spanish(meal_type)
    translations = {
      "breakfast" => "Desayuno",
      "lunch" => "Almuerzo",
      "dinner" => "Cena",
      "snack" => "Colación"
    }
    translations[meal_type] || meal_type
  end
end