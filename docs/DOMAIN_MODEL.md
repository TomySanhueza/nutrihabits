# Domain Model

## Core Entities

### Nutritionist
| Campo | Tipo | Notas |
|-------|------|-------|
| email | string | Devise auth |
| first_name | string | |
| last_name | string | |
| phone | string | |
| encrypted_password | string | Devise |

### Patient
| Campo | Tipo | Notas |
|-------|------|-------|
| email | string | Devise auth |
| first_name | string | |
| last_name | string | |
| phone | string | |
| nutritionist_id | bigint | FK obligatorio |
| onboarding_state | string | draft / invited / active / suspended (default: "draft") |
| invitation_sent_at | datetime | |
| invitation_accepted_at | datetime | |
| access_suspended_at | datetime | |
| last_seen_at | datetime | |

### Profile (one-to-one con Patient)
| Campo | Tipo | Notas |
|-------|------|-------|
| patient_id | bigint | FK |
| nutritionist_id | bigint | FK — denormalización: derivable de patient.nutritionist_id. Riesgo de inconsistencia si paciente cambia de nutricionista. |
| weight | float | kg actual |
| height | float | cm |
| goals | text | objetivos clínicos del paciente (plural) |
| conditions | text | condiciones de salud (texto libre) |
| lifestyle | text | actividad física, hábitos |
| diagnosis | text | diagnóstico nutricional |

### NutritionPlan
| Campo | Tipo | Notas |
|-------|------|-------|
| patient_id | bigint | FK |
| nutritionist_id | bigint | FK |
| status | string | draft / active / completed |
| start_date | date | |
| end_date | date | |
| objective | text | objetivo del plan |
| calories | float | kcal/día totales |
| protein | float | g/día |
| fat | float | g/día |
| carbs | float | g/día |
| meal_distribution | jsonb | Ver esquema abajo |
| ai_rationale | text | explicación generada por LLM |
| notes | text | notas clínicas del nutricionista |

### Plan (ejecución diaria)
| Campo | Tipo | Notas |
|-------|------|-------|
| nutrition_plan_id | bigint | FK |
| date | date | día al que corresponde |
| mood | string | estado de ánimo reportado |
| energy_level | string | nivel de energía |
| activity | string | actividad física del día |
| notes | text | notas del día |

### Meal
| Campo | Tipo | Notas |
|-------|------|-------|
| plan_id | bigint | FK |
| meal_type | string | breakfast / lunch / dinner / snack |
| status | string | pending / logged / skipped |
| ingredients | text | lista con porciones |
| recipe | text | pasos numerados |
| calories | float | kcal planificadas |
| protein | float | g planificados |
| carbs | float | g planificados |
| fat | float | g planificados |

### MealLog
| Campo | Tipo | Notas |
|-------|------|-------|
| meal_id | bigint | FK (one-to-one) |
| photo | Active Storage | imagen subida por paciente |
| analysis_status | string | not_requested / queued / processing / completed / failed (default: "not_requested") |
| analysis_error | text | mensaje de error si failed, truncado a 500 chars |
| logged_at | datetime | cuándo se registró (seteado en controller) |
| meal_type | string | denormalizado de Meal#meal_type — riesgo de inconsistencia |
| ai_calories | float | kcal detectadas por LLM |
| ai_protein | float | g detectados |
| ai_carbs | float | g detectados |
| ai_fat | float | g detectados |
| ai_health_score | float | 1.0-10.0 (tipo float, no integer) |
| ai_feedback | string | <280 chars |
| ai_comparison | jsonb | Ver esquema abajo |

### WeightPatient
| Campo | Tipo | Notas |
|-------|------|-------|
| patient_id | bigint | FK |
| date | date | fecha del registro |
| weight | float | kg |

### Chat + Message
| Campo | Tipo | Notas |
|-------|------|-------|
| Chat#nutritionist_id | bigint | FK |
| Chat#patient_id | bigint | FK |
| Chat#title | string | |
| Chat#last_read_at | datetime | |
| Message#chat_id | bigint | FK |
| Message#content | text | |
| Message#role | string | user / assistant |

### NutritionistAiChat / PatientAiChat
| Campo | Tipo | Notas |
|-------|------|-------|
| *_id | bigint | FK al usuario correspondiente |
| context | jsonb | contexto acumulado del chat |
| Messages#content | text | |
| Messages#role | string | user / assistant |
| Messages#metadata | jsonb | latencia, tokens, errores |

### GroceryList
| Campo | Tipo | Notas |
|-------|------|-------|
| patient_id | bigint | FK |
| nutrition_plan_id | bigint | FK optional |
| date_from | date | inicio del rango |
| date_to | date | fin del rango |
| retailer_slug | string | ej: jumbo-cl, mercadona-es |
| country_code | string | CL / ES |
| currency | string | CLP / EUR |
| generated_by | string | quién generó la lista |
| status | string | pending / generating / ready / failed |
| source_summary | jsonb | Ver esquema abajo |

### GroceryListItem
| Campo | Tipo | Notas |
|-------|------|-------|
| grocery_list_id | bigint | FK |
| ingredient_name | string | nombre original extraído del texto |
| normalized_name | string | nombre normalizado para matching |
| quantity_value | decimal | cantidad numérica |
| quantity_unit | string | unidad (g, ml, taza, etc.) |
| meal_types | jsonb | array de tipos de comida que usan este ingrediente |
| source_dates | jsonb | array de fechas de las comidas fuente |
| notes | string | notas adicionales |

### GroceryProductMatch
| Campo | Tipo | Notas |
|-------|------|-------|
| grocery_list_item_id | bigint | FK |
| external_id | string | ID del producto en el catálogo del retailer |
| retailer_slug | string | ej: jumbo-cl |
| country_code | string | CL / ES |
| name | string | nombre del producto |
| brand | string | marca |
| package_size | string | tamaño del envase |
| price | decimal | precio |
| currency | string | CLP / EUR |
| availability | boolean | disponible en el catálogo |
| product_url | string | URL del producto |
| rank | integer | posición del match (1 = mejor) |
| metadata | jsonb | datos adicionales del proveedor |

### PatientPrioritySnapshot
| Campo | Tipo | Notas |
|-------|------|-------|
| patient_id | bigint | FK |
| nutritionist_id | bigint | FK |
| score | float | puntuación de prioridad |
| priority_level | string | high / medium / low |
| reasons | jsonb | array de strings con razones |
| recommended_action | string | acción sugerida |
| outreach_draft | text | borrador de mensaje de contacto |
| captured_at | datetime | cuándo se tomó el snapshot |

### UserSupermarketPreference
| Campo | Tipo | Notas |
|-------|------|-------|
| patient_id | bigint | FK unique (one-to-one) |
| country_code | string | CL / ES |
| currency | string | CLP / EUR |
| retailer_slug | string | retailer preferido |
| retailer_name | string | nombre legible del retailer |
| fallback_retailers | jsonb | array de slugs alternativos en orden de preferencia |

### NutritionistAiChat
| Campo | Tipo | Notas |
|-------|------|-------|
| nutritionist_id | bigint | FK |
| context | jsonb | contexto acumulado del chat |
| title | string | título de la sesión |
| model | string | modelo de LLM usado en esta sesión |

---

## Esquemas JSONB Canónicos

### NutritionPlan#meal_distribution
```json
{
  "2025-10-15": {
    "breakfast": {
      "ingredients": "2 huevos, 1 taza leche, 30g avena",
      "recipe": "1. Mezclar... 2. Cocinar...",
      "calorias": 350.0,
      "protein": 18.0,
      "carbs": 42.0,
      "fat": 9.0
    },
    "lunch": { "..." : "..." },
    "dinner": { "..." : "..." },
    "snacks": { "..." : "..." }
  }
}
```

### MealLog#ai_comparison
```json
{
  "macronutrient_comparison": {
    "calories": {"planned": 350, "actual": 420, "diff": "+70"},
    "protein": {"planned": 18, "actual": 15, "diff": "-3"},
    "carbs": {"planned": 42, "actual": 55, "diff": "+13"},
    "fat": {"planned": 9, "actual": 12, "diff": "+3"}
  },
  "ingredient_analysis": "Descripción de diferencias en ingredientes",
  "improvement_suggestion": "Sugerencia concreta para próxima vez"
}
```

### GroceryList#source_summary
```json
{
  "date_range": {"from": "2025-10-15", "to": "2025-10-21"},
  "meal_count": 28,
  "unique_ingredients": 18,
  "retailer": "jumbo-cl"
}
```

---

## Asociaciones Clave

```
Nutritionist
  has_many :patients
  has_many :nutrition_plans (through patients)
  has_many :nutritionist_ai_chats
  has_many :chats

Patient
  belongs_to :nutritionist
  has_one :profile
  has_many :nutrition_plans
  has_many :plans (through nutrition_plans)
  has_many :meals (through plans)
  has_one :user_supermarket_preference
  has_many :grocery_lists
  has_many :patient_priority_snapshots

NutritionPlan → Plan → Meal → MealLog (4 niveles de profundidad)
```

## Métodos Custom Canónicos

**Patient:**
- `meal_logs_through_plans` — `MealLog.joins(meal: { plan: :nutrition_plan }).where(nutrition_plans: { patient_id: id })`
- `available_meals` — `meals.left_joins(:meal_log).where(meal_logs: { id: nil })`
- `active_nutrition_plan(reference_date)` — plan activo por fecha, fallback a status: active

## Reglas de Valores

- Persistir enums y estados en inglés.
- Traducir labels en helpers y vistas (español en UI).
- Campos JSONB son auditables, no autoritativos — la fuente de verdad son los campos tipados.
- Nutritionists solo acceden a sus propios pacientes y datos anidados.
- Patients solo acceden a su propia información personal.
- Los product matches pertenecen a grocery list items, que pertenecen a grocery lists del paciente.

## Entidades Planeadas (aún no implementadas en UI)

- `UserSupermarketPreference` — modelos OK, falta flujo de configuración
- `PatientPrioritySnapshot` — modelo OK, falta persistencia desde PatientRadarService
