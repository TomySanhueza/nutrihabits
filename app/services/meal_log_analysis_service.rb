class MealLogAnalysisService
  require "json"

  def initialize(image_data, meal)
    @image_data = image_data
    @meal = meal # El meal específico para ese día y tipo de comida
    @plan = meal.plan # El plan del día
    @nutrition_plan = meal.plan.nutrition_plan # El plan nutricional general
    @chat = RubyLLM.chat
  end

  def call
    system_prompt = <<-PROMPT
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
          "ai_calories": "float — calorías totales estimadas de la comida (ej: 520)",
          "ai_protein": "float — gramos de proteína estimados",
          "ai_carbs": "float — gramos de carbohidratos estimados",
          "ai_fat": "float — gramos de grasa estimados",
          "ai_health_score": "float — puntuación de salud de la comida en escala 1 al 10, considerando el plan nutricional, balance de macronutrientes, calidad alimentaria, coherencia con los objetivos del paciente Y comparación con la comida específica planificada para este momento del día",
          "ai_feedback": "string — comentario breve, empático y motivador (<280 caracteres). Refuerza los aciertos, señala oportunidades de mejora de forma amable y ofrece una recomendación práctica que impulse la adherencia sin generar culpa.",
          "ai_comparison": {
            "macronutrient_comparison": "string — Comparación detallada de macronutrientes vs. la comida planificada (ej: 'Calorías: +120 kcal sobre el plan, Proteínas: -10 g, Carbohidratos: +25 g, Grasas: dentro del rango.')",
            "ingredient_analysis": "string — Análisis cualitativo de ingredientes utilizados vs. los planificados, destacando el equilibrio y calidad (ej: 'Buen equilibrio entre fuentes naturales 🌿. Usaste ingredientes frescos y simples, aunque podrías sumar algo de color con vegetales o legumbres 💚.')",
            "improvement_suggestion": "string — Sugerencia práctica y constructiva para mejorar en la próxima comida (ej: 'Vas muy bien 🙌. Para el próximo plato, intenta incluir una porción de proteína magra o verduras al vapor — pequeños ajustes que suman mucho 💪.')"
          }
        }

        ---

        ### 📊 Criterios profesionales para calcular `ai_health_score` (escala 1 al 10):

        **Debes evaluar combinando estos aspectos:**
        1. **Calidad nutricional general** (proteínas magras, carbohidratos complejos, grasas saludables, vegetales/frutas, métodos de cocción)
        2. **Alineación con objetivos del plan nutricional** (objetivos clínicos, notas del nutricionista)
        3. **Coherencia con totales diarios** (calorías, proteínas, carbos, grasas del día completo)
        4. **Precisión vs. comida planificada** (qué tan cerca está de la comida específica propuesta para este momento)

        | Rango | Interpretación | Criterios |
        |-------|----------------|-----------|
        | **9–10 (Excelente)** | Comida equilibrada y de alta calidad nutricional, perfectamente alineada al plan. | Incluye proteínas magras, carbohidratos complejos, grasas saludables, vegetales o frutas, porciones adecuadas y métodos de cocción saludables. Dentro del rango calórico y de macros del meal planificado (±10%). |
        | **7–8 (Buena)** | Saludable y cercana al objetivo del plan. | Pequeños desajustes calóricos o de macros (±20%), o leve falta de variedad, pero mantiene equilibrio general y sigue la esencia del meal planificado. |
        | **5–6 (Moderada)** | Plato funcional pero parcialmente desbalanceado. | Exceso o déficit de un macronutriente (±30-40%), o desviación moderada de ingredientes planificados. Requiere ajustes. |
        | **3–4 (Baja adherencia)** | Bajo equilibrio nutricional o cocción poco saludable. | Alto en grasas saturadas, azúcares o ultraprocesados. Baja presencia de vegetales o proteínas. Muy diferente al meal planificado. |
        | **1–2 (Crítica)** | Valor nutricional muy bajo. | Comida ultraprocesada, alta en sodio, azúcar o grasas saturadas. No alineada al plan y con baja densidad nutricional. Completamente opuesta al meal planificado. |

        ---

        ### 💬 Guía para el tono del campo `ai_feedback`:
        - Empático, cercano y sin juicios ("vas por buen camino", "esto también cuenta").
        - Refuerza lo positivo primero ("Buena fuente de energía 👏").
        - Luego sugiere mejoras simples ("Podrías sumar algo de proteína o color vegetal 🌿").
        - Cierra con una frase motivadora o de apoyo ("Recuerda que el equilibrio se construye paso a paso 💪").
        - Evita lenguaje de culpa o perfeccionismo.

        ---

        ### 📘 Ejemplo de salida esperada:
        {
          "ai_calories": 610.0,
          "ai_protein": 22.0,
          "ai_carbs": 85.0,
          "ai_fat": 16.0,
          "ai_health_score": 7.8,
          "ai_feedback": "Buena fuente de energía 👌 y porción equilibrada de carbohidratos. Agregar una proteína magra o vegetales le daría más saciedad y balance 🌿. Vas muy bien, ¡cada elección cuenta! 💪",
          "ai_comparison": {
            "macronutrient_comparison": "Calorías: +120 kcal sobre el plan, Proteínas: -10 g, Carbohidratos: +25 g, Grasas: dentro del rango.",
            "ingredient_analysis": "Buen equilibrio entre fuentes naturales 🌿. Usaste ingredientes frescos y simples, aunque podrías sumar algo de color con vegetales o legumbres 💚.",
            "improvement_suggestion": "Vas muy bien 🙌. Para el próximo plato, intenta incluir una porción de proteína magra o verduras al vapor — pequeños ajustes que suman mucho 💪."
          }
        }
    PROMPT

    JSON.parse((@chat.ask(system_prompt, image: @image_data)).content)
  end

  private

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

      **Comida específica planificada para este momento:**
      - Tipo de comida: #{meal_type_spanish(@meal.meal_type)}
      - Fecha: #{@plan.date}
      - Calorías planificadas: #{@meal.calories}kcal
      - Proteína planificada: #{@meal.protein}g
      - Carbohidratos planificados: #{@meal.carbs}g
      - Grasas planificadas: #{@meal.fat}g
      - Ingredientes propuestos: #{@meal.ingredients}
      - Receta sugerida: #{@meal.recipe}
      - Estado: #{@meal.status}

      **IMPORTANTE:** Debes comparar la comida de la foto con esta comida planificada específica para generar el campo `ai_comparison`.
    CONTEXT
  end

  def meal_type_spanish(meal_type)
    {
      "breakfast" => "Desayuno",
      "lunch" => "Almuerzo",
      "dinner" => "Cena",
      "snack" => "Colación"
    }[meal_type] || meal_type
  end
end
