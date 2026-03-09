# Data Flows

Flujos de datos operacionales del sistema. Complementa ARCHITECTURE.md con secuencias paso a paso.

---

## 1. Análisis de Foto de Comida (async)

```
Patient (browser)
  │
  ├─► POST /meals/:id/meal_logs  { photo: file }
  │
  ▼
MealLogsController#create
  ├─ Crea MealLog { analysis_status: :queued }
  ├─ Active Storage → Cloudinary (foto guardada)
  ├─ MealLogAnalysisJob.perform_later(meal_log.id)
  └─► render / redirect con estado "queued"

  [Turbo Stream o polling actualiza UI]

MealLogAnalysisJob (worker process)
  ├─ MealLog.find(id)
  ├─ meal_log.update!(analysis_status: :processing)
  ├─ MealLogAnalysisService.new(photo_attachment, meal).call
  │     ├─ Obtiene URL de Cloudinary: photo.blob.url
  │     ├─ Construye prompt con contexto del Meal y NutritionPlan
  │     ├─ RubyLLM.chat(model: 'gpt-4o') con imagen + texto
  │     ├─ Strip markdown de respuesta
  │     └─► JSON.parse → hash con ai_* fields
  ├─ [éxito] meal_log.update!(ai_calories:, ..., analysis_status: :completed)
  └─ [error] meal_log.update!(analysis_status: :failed, analysis_error: msg)

Patient (browser)
  └─► Ve resultado de análisis (health_score, feedback, comparison)
```

**Estados posibles que ve el paciente:**
- `not_requested` — sin foto subida
- `queued` — foto recibida, esperando análisis
- `processing` — análisis en curso
- `completed` — resultados disponibles
- `failed` — error, puede resubir foto

---

## 2. Generación de Plan Nutricional (síncrono)

```
Nutritionist (browser)
  │
  ├─► POST /patients/:patient_id/nutrition_plans  { start_date:, end_date: }
  │
  ▼
NutritionPlansController#create
  ├─ Carga patient con scoped access (nutritionist.patients.find)
  ├─ Carga profile del patient
  ├─ NutritionPlanGeneratorService.new(profile, start_date, end_date).call
  │     ├─ Consulta planes previos del paciente (historial)
  │     ├─ Consulta PatientHistory más reciente
  │     ├─ Construye system prompt (WHO/ADA/ESPEN guidelines)
  │     ├─ RubyLLM.chat → respuesta JSON
  │     ├─ Strip markdown → JSON.parse
  │     └─► hash con plan + meal_distribution
  ├─ ActiveRecord::Base.transaction do
  │     ├─ Crea NutritionPlan con atributos + meal_distribution JSONB
  │     ├─ Para cada fecha en rango: crea Plan
  │     └─ Para cada comida del día: crea Meal
  └─► redirect_to nutrition_plan_path (show del plan)

Nutritionist (browser)
  └─► Ve el plan generado con todos los días y comidas
```

**En error de LLM:** excepción propagada al controller → flash error, sin plan creado.

---

## 3. Generación de Lista de Compras

```
Patient (browser)
  │
  ├─► POST /grocery_lists/generate  { retailer_slug:, date_from:, date_to: }
  │
  ▼
GroceryListsController#create (o similar)
  ├─ Crea GroceryList { status: :generating, patient:, retailer_slug:, date_range: }
  ├─ Encola job de generación (o llama servicio en proceso)
  └─► render estado "generating"

ShoppingListGeneratorService
  ├─ Obtiene meals del active_nutrition_plan en el rango de fechas
  ├─ Extrae y normaliza ingredientes únicos de cada Meal#ingredients
  ├─ Para cada ingrediente:
  │     ├─ SupermarketCatalogProvider.search(ingredient, retailer_slug)
  │     ├─ Retorna array de productos del catálogo
  │     └─ Crea GroceryProductMatch por producto
  ├─ Crea GroceryListItem por ingrediente normalizado
  ├─ Actualiza GroceryList#source_summary JSONB
  └─ grocery_list.update!(status: :ready)

Patient (browser)
  └─► Ve lista de compras con productos sugeridos por categoría
```

---

## 4. Onboarding de Paciente (invite → active)

```
Nutritionist (browser)
  │
  ├─► POST /patients  { name:, email:, ... }
  │
  ▼
PatientsController#create
  ├─ Crea Patient { onboarding_state: :draft }
  └─► redirect_to patient_path (show)

Nutritionist (browser)
  ├─► POST /patients/:id/invite  (acción de invitación)
  │
  ▼
PatientsController#invite (o similar)
  ├─ patient.update!(onboarding_state: :invited, invitation_sent_at: Time.current)
  └─ Envía email de invitación con link de activación (Devise o custom)

Patient (email link)
  ├─► GET /patients/accept_invitation?token=...
  │
  ▼
  ├─ Valida token
  ├─ patient.update!(onboarding_state: :active, invitation_accepted_at: Time.current)
  └─► redirect al dashboard del paciente (login automático)

[Suspensión]
Nutritionist ├─► PATCH /patients/:id/suspend
             ├─ patient.update!(onboarding_state: :suspended, access_suspended_at: Time.current)
             └─ Sesión del paciente invalidada
```

**Nota:** El flujo de invitación está planificado (sprint 3). Los campos existen en el modelo.

---

## 5. Patient Radar

```
Nutritionist (browser)
  │
  ├─► GET /nutritionists/patient_radar
  │
  ▼
NutritionistsController#patient_radar
  ├─ PatientRadarService.new(current_nutritionist).call
  │     ├─ Para cada patient del nutritionist:
  │     │     ├─ Evalúa active_nutrition_plan → sin plan: +35
  │     │     ├─ Evalúa weight_patients últimos 7d → sin peso: +20
  │     │     ├─ Evalúa meal_logs_through_plans últimos 3d → sin logs: +25
  │     │     └─ Evalúa onboarding_state != "active" → no activo: +20
  │     ├─ Construye Entry struct por paciente
  │     └─► Array de Entry ordenado por score desc (mayor riesgo primero)
  └─► render patient_radar con @entries

Nutritionist (browser)
  └─► Ve tabla con badges high/medium/low y acciones recomendadas

[Opcional — no implementado aún]
  ├─ Persiste snapshot en PatientPrioritySnapshot si score cambió
  └─ Dashboard muestra tendencia de prioridad
```

---

## 6. Análisis AI Chat (Nutritionist Copilot / Patient Copilot)

```
User (browser)
  │
  ├─► POST /nutritionist_ai_chats/:id/messages  { content: "..." }
  │
  ▼
MessagesController (AI)
  ├─ Carga NutritionistAiChat con contexto JSONB
  ├─ Añade mensaje del usuario al historial
  ├─ RubyLLM.chat con system prompt + historial + contexto del paciente
  ├─ Crea NutritionistAiMessage { role: :assistant, content: response }
  ├─ Actualiza context JSONB si hay nueva información relevante
  └─► Turbo Stream con el mensaje de respuesta

[Igual para PatientAiChat pero con contexto del propio paciente]
```

---

## Notas Generales

- **Active Storage URLs:** siempre usar `blob.url` (no `rails_blob_url`) para obtener URL de Cloudinary directa para el LLM.
- **Transacciones:** la generación de planes usa `ActiveRecord::Base.transaction` para atomicidad — si falla creación de cualquier Meal, rollback completo.
- **JSONB:** los campos JSONB (`meal_distribution`, `ai_comparison`, `context`) son escritos por servicios y leídos por vistas — nunca modificados directamente en controllers.
- **Turbo Streams:** los estados de `analysis_status` y `grocery_list.status` son los triggers para actualizaciones de UI sin polling activo cuando Turbo/Action Cable está activo.
