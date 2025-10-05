class NutritionPlanGeneratorService
  require "json"

  def initialize(profile, start_date, end_date)
    @profile = profile
    @start_date = start_date
    @end_date = end_date
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
          3. Desarrolla un plan con alcance desde la fecha inicial **#{@start_date}** hasta la fecha final **#{@end_date}**, incluyéndolas ambas.
          4. Siempre entregar **dos outputs diferenciados**:
            - Un **plan estructurado en formato JSON válido** con la siguiente plantilla exacta:  
              plan: {
                {
                  "objective": "string (ej: Pérdida de peso, Control glucémico, Ganancia muscular)",
                  "calories": "integer (ej: 1800)",
                  "protein": "float (en gramos/día, ej: 130)",
                  "fat": "float (en gramos/día, ej: 60)",
                  "carbs": "float (en gramos/día, ej: 200)",
                  "meal_distribution": {
                      "YYYY-MM-DD": {
                          "breakfast": { 
                                "ingredients": "Lista clara de los distintos ingredientes del desayuno, separados por comas, indicando sus porciones en medidas sencillas y cotidianas (ej: 200 g, 1 palma de pollo, 1 taza de quinoa, ½ plátano).",
                                "recipe": "Breve receta con pasos enumerados y separados por coma, describiendo cómo preparar o cocinar el desayuno. Cada paso debe incluir un número al inicio (ej: 1. Cocina el pollo, 2. Corta las verduras, 3. Mezcla los ingredientes).",
                                "calorias": "float que representa las calorías totales del desayuno, proporcional a las calorías diarias del plan.",
                                "protein": "float que indica los gramos de proteína presentes en la receta.",
                                "carbs": "float que indica los gramos de carbohidratos presentes en la receta.",
                                "fat": "float que indica los gramos de grasa presentes en la receta."
                          },
                          "lunch": { 
                                "ingredients": "Lista clara de los distintos ingredientes del almuerzo, separados por comas, indicando sus porciones en medidas sencillas y cotidianas (ej: 150 g de pollo, 1 taza de arroz integral, ½ palta, 1 taza de vegetales salteados).",
                                "recipe": "Breve receta con pasos numerados y separados por coma, explicando cómo preparar o cocinar el almuerzo. Cada paso debe comenzar con un número (ej: 1. Cocina el arroz, 2. Saltea los vegetales, 3. Mezcla todo y sirve).",
                                "calorias": "float que representa las calorías totales del almuerzo, proporcional a las calorías diarias del plan.",
                                "protein": "float que indica los gramos de proteína presentes en la receta.",
                                "carbs": "float que indica los gramos de carbohidratos presentes en la receta.",
                                "fat": "float que indica los gramos de grasa presentes en la receta."
                          },
                          "dinner": { 
                                "ingredients": "Lista de los distintos ingredientes de la cena, separados por comas, con sus porciones expresadas en medidas sencillas y visuales (ej: 120 g de pescado, 1 taza de puré de calabaza, 1 taza de brócoli al vapor, 1 cucharadita de aceite de oliva).",
                                "recipe": "Breve receta con pasos numerados y separados por coma, explicando la preparación o cocción de la cena. Cada paso debe comenzar con un número (ej: 1. Cocina el pescado al horno, 2. Prepara el puré de calabaza, 3. Cocina el brócoli al vapor, 4. Sirve y agrega aceite de oliva).",
                                "calorias": "float que representa las calorías totales de la cena, proporcional a las calorías diarias del plan.",
                                "protein": "float que indica los gramos de proteína contenidos en la receta.",
                                "carbs": "float que indica los gramos de carbohidratos contenidos en la receta.",
                                "fat": "float que indica los gramos de grasa contenidos en la receta."
                          },
                          "snacks": { 
                                "ingredients": "Lista de los distintos ingredientes o alimentos que componen el snack, separados por comas, con porciones expresadas en medidas sencillas y visuales (ej: 1 yogur natural, 10 almendras, ½ manzana, 1 cucharadita de semillas de lino).",
                                "recipe": "Breve descripción numerada con los pasos simples para preparar o combinar el snack si aplica. Cada paso debe comenzar con un número (ej: 1. Coloca el yogur en un bol, 2. Agrega las almendras y la manzana en trozos, 3. Espolvorea las semillas de lino por encima).",
                                "calorias": "float que representa las calorías totales del snack, proporcional a las calorías diarias del plan.",
                                "protein": "float que indica los gramos de proteína contenidos en el snack.",
                                "carbs": "float que indica los gramos de carbohidratos contenidos en el snack.",
                                "fat": "float que indica los gramos de grasa contenidos en el snack."
                          }
                      },
                      "YYYY-MM-DD": { ... repetir la misma estructura ... },
                      "YYYY-MM-DD": { ... repetir la misma estructura ... }
                  },
                  "notes": "Recomendaciones generales adaptadas al estilo de vida y condiciones del paciente, en lenguaje sencillo."
                }
              }

        ⚠️ Instrucción clave: Debes **generar automáticamente un bloque de `meal_distribution` para cada día del rango de fechas** entre `#{@start_date}` y `#{@end_date}`, sin omitir días. Cada fecha debe estar en formato `YYYY-MM-DD` y contener desayuno, almuerzo, cena y snack.

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

    PROMPT

    JSON.parse((@chat.ask(system_prompt)).content)
  end
end
