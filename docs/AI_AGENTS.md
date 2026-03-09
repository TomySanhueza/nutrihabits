# AI Agents

## Role Split

- **Nutritionist copilot:** drafting clínico, explicación de planes, sugerencias de outreach, visión de portafolio de pacientes.
- **Patient copilot:** explicación de plan, sugerencias de meal swap, apoyo de adherencia, ayuda con lista de compras.

## Hard Rules

- No diagnóstico más allá del dominio nutricional permitido.
- No activación autónoma de planes ni mensajería a pacientes.
- Todos los drafts de outreach quedan editables por el nutricionista.
- El contexto de un paciente nunca debe filtrar a otro usuario.

---

## Contratos por Servicio AI

### NutritionPlanGeneratorService

**Modelo:** configurado en `config/initializers/ruby_llm.rb` (default GPT-4o o similar)
**Inicialización:** `RubyLLM.chat`
**Idioma del prompt:** español
**Input context:**
- `profile` (objeto completo: peso, talla, objetivos, condiciones, diagnóstico, lifestyle)
- `start_date`, `end_date`
- Historial de planes anteriores del paciente
- Datos clínicos del `PatientHistory` más reciente

**Guidelines referenciadas en system prompt:** WHO, ADA, ESPEN

**Output JSON esperado:**
```json
{
  "plan": {
    "objective": "string",
    "calories": 2000.0,
    "protein": 120.0,
    "fat": 65.0,
    "carbs": 250.0,
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
        "lunch": { "..." : "..." },
        "dinner": { "..." : "..." },
        "snacks": { "..." : "..." }
      }
    },
    "notes": "string"
  },
  "criteria_explanation": "string"
}
```

**Manejo de respuesta:**
```ruby
response.gsub(/```json\n?/, '').gsub(/```\n?/, '').strip
JSON.parse(cleaned_response)
```

**Creación en DB:** `NutritionPlan` + `Plan`s + `Meal`s en una transacción.

---

### MealLogAnalysisService

**Modelo:** GPT-4o (visión obligatoria — no usar modelos sin capacidad de imagen)
**Inicialización:** `RubyLLM.chat(model: 'gpt-4o')`
**Idioma del prompt:** español

**Input:**
- `photo_attachment` — Active Storage attachment; URL obtenida via `photo.blob.url` (Cloudinary)
- `meal` — objeto `Meal` con sus atributos (ingredientes, calorías, macros planificados)
- Contexto del `NutritionPlan` y `Plan` padre

**Output JSON esperado:**
```json
{
  "ai_calories": 420.0,
  "ai_protein": 15.0,
  "ai_carbs": 55.0,
  "ai_fat": 12.0,
  "ai_health_score": 7,
  "ai_feedback": "string <280 chars",
  "ai_comparison": {
    "macronutrient_comparison": {
      "calories": {"planned": 350, "actual": 420, "diff": "+70"},
      "protein": {"planned": 18, "actual": 15, "diff": "-3"},
      "carbs": {"planned": 42, "actual": 55, "diff": "+13"},
      "fat": {"planned": 9, "actual": 12, "diff": "+3"}
    },
    "ingredient_analysis": "string",
    "improvement_suggestion": "string"
  }
}
```

**Criterios de ai_health_score (1-10):**
- Variedad de alimentos
- Calidad nutricional general
- Adherencia al plan planificado
- Tamaño de porción
- Nivel de procesamiento del alimento

**Manejo de respuesta:** igual que NutritionPlanGeneratorService (strip markdown antes de parse).

---

### PatientRadarService (no LLM — scoring local)

**Sin llamada a LLM.** Scoring puramente determinístico.

**Scoring:**
| Condición | Puntos |
|-----------|--------|
| Sin plan nutricional activo | +35 |
| Sin registro de peso en 7 días | +20 |
| Sin meal_logs en 3 días | +25 |
| onboarding_state != "active" | +20 |

**Thresholds:**
- `high`: score ≥ 50
- `medium`: score ≥ 25
- `low`: score < 25

**Output:** array de `PatientRadarService::Entry` structs ordenado por score desc

```ruby
Entry = Struct.new(:patient, :score, :priority_level, :reasons, :recommended_action, keyword_init: true)
```

---

### ShoppingListGeneratorService

**Sin LLM.** Agrega ingredientes del plan activo del paciente para un rango de fechas.

**Input:** paciente, rango de fechas, `retailer_slug`
**Proceso:**
1. Obtiene meals del plan activo en el rango
2. Normaliza y deduplica ingredientes
3. Para cada ingrediente: `SupermarketCatalogProvider.search(ingredient, retailer_slug)`
4. Crea `GroceryListItem`s y `GroceryProductMatch`es
5. Actualiza `GroceryList#status: :ready`

---

### MealSwapSuggestionService (planeado, no implementado)

- Sugiere alternativas para una comida del plan
- Input: meal, preferencias del paciente, historial de logs
- Output: lista de alternativas con macros similares

---

## Reglas de Parsing y Confiabilidad

1. **Siempre** strip de bloques markdown (`\`\`\`json ... \`\`\``) antes de `JSON.parse`
2. Si `JSON.parse` falla → log error + `raise` → Job captura y pone `analysis_status: :failed`
3. **Nunca** guardar respuesta cruda del LLM en DB sin parsear
4. Timeout de LLM: manejar `Timeout::Error` en jobs con retry
5. Máximo 3 intentos de retry por job (configurar en adapter de cola)
6. `analysis_error` almacena el mensaje truncado a 500 chars para diagnóstico

## Performance Strategy

- Trabajo AI lento → background jobs (latencia GPT-4o Vision: 3-10s inaceptable en request cycle)
- UI responsiva con estados pendientes y actualizaciones parciales via Turbo Streams
- Metadata estructurada persistida para retries, resúmenes y revisión de latencia
- Contexto de chats AI persistido como JSONB para continuidad entre sesiones
