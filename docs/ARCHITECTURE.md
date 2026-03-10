# Architecture

## Runtime Shape

- Rails 7.1 monolith
- Devise dual auth: `Nutritionist` and `Patient` (modelos separados, no roles en User)
- Active Storage con Cloudinary (dev y prod), disco local (test)
- Hotwire (Turbo + Stimulus) para interactividad frontend
- PostgreSQL como base de datos principal
- Background jobs para trabajo AI y de proveedores externos
- Bootstrap 5.3 para UI

## Diagrama de Capas

```
Request
  → Controller
      → Service Object        → Model → DB
      → Background Job        → Service Object → Model → DB
      → AI Service (LLM/Vision) → JSON parsing → Model → DB

Active Storage: foto subida → Cloudinary → URL disponible para LLM
```

## Flujos de Datos Críticos

### Análisis de Foto de Comida (async)

1. Patient `POST /meals/:id/meal_logs` con foto adjunta
2. `MealLogsController#create`:
   - Crea `MealLog` con `analysis_status: :queued`
   - Guarda foto via Active Storage → Cloudinary
   - Encola `MealLogAnalysisJob.perform_later(meal_log.id)`
   - Responde con redirect o Turbo Stream al estado `queued`
3. `MealLogAnalysisJob#perform`:
   - Actualiza `analysis_status: :processing`
   - Llama `MealLogAnalysisService.new(photo, meal).call`
   - En éxito: actualiza campos `ai_*` + `analysis_status: :completed`
   - En error: `analysis_status: :failed` + `analysis_error: e.message`
4. Vista: polling o Turbo Stream refleja el estado final

### Generación de Plan Nutricional (síncrono)

1. Nutritionist `POST /patients/:id/nutrition_plans`
2. `NutritionPlansController#create`:
   - Llama `NutritionPlanGeneratorService.new(profile, start_date, end_date).call`
3. Servicio:
   - Construye prompt con perfil, historial previo y rangos de fecha
   - LLM genera JSON → strip markdown → `JSON.parse`
   - Crea `NutritionPlan` + `Plan`s + `Meal`s en una transacción
4. Redirect a `show` del plan generado

### Generación de Lista de Compras

1. Patient `POST /grocery_lists/generate`
2. `GroceryListsController` crea `GroceryList` con `status: :generating`
3. Job encola `ShoppingListGeneratorService`:
   - Agrega ingredientes únicos del plan activo en el rango de fechas
   - Para cada ingrediente: `SupermarketCatalogProvider.search(ingredient, retailer_slug)` → `GroceryProductMatch`es
   - Actualiza `GroceryList#status: :ready`
4. Vista refleja el estado con Turbo Stream

### Onboarding de Paciente

1. Nutritionist crea paciente → `onboarding_state: :draft`
2. Nutritionist envía invitación → `onboarding_state: :invited`, `invitation_sent_at: now`
3. Patient acepta → `onboarding_state: :active`, `invitation_accepted_at: now`
4. Si se suspende → `onboarding_state: :suspended`, `access_suspended_at: now`

### Patient Radar

1. Nutritionist visita `/nutritionists/patient_radar`
2. `NutritionistsController#patient_radar` llama `PatientRadarService.new(current_nutritionist).call`
3. Servicio evalúa cada paciente: `no_plan (+35)`, `no_weight_7d (+20)`, `no_meal_logs_3d (+25)`, `not_active (+20)`
4. Retorna array de `Entry` structs ordenado por score desc
5. Vista muestra prioridad con badge de color (high/medium/low)
6. Snapshot puede persistirse en `PatientPrioritySnapshot` (opcional, no implementado aún)

## Máquinas de Estado

### Patient#onboarding_state
```
draft → (invite sent) → invited → (accepted) → active → (suspended) → suspended
                                                       ↑                    |
                                                       └────────────────────┘ (reactivar)
```

### MealLog#analysis_status
```
not_requested → queued → processing → completed
                                    ↘ failed (retry posible reencolando job)
```

### GroceryList#status
```
pending → generating → ready
                     ↘ failed
```

### NutritionPlan#status (implícito)
```
draft → active → completed
```

## Patrón de Service Objects

- **Input:** objetos de dominio completos (no IDs crudos)
- **Output:** resultado directo o excepción (el caller decide cómo manejarlo)
- **Estado:** stateless — ningún estado de instancia persiste entre llamadas
- **Jobs:** envuelven servicios para manejo async; capturan excepciones y actualizan `status: :failed`
- **Ubicación:** `app/services/`

```ruby
# Ejemplo canónico
class SomeService
  def initialize(domain_object, options = {})
    @obj = domain_object
  end

  def call
    # lógica
    # raise en error
  end
end
```

## Deudas Técnicas Conocidas

- Refactors DT-1, DT-2 y DT-3 cerrados el 2026-03-10:
  - `NutritionPlanGeneratorService` ahora parsea y persiste `NutritionPlan -> Plan -> Meal` dentro de una transacción.
  - `Profile` deriva `nutritionist` a través de `patient`; la FK redundante fue eliminada.
  - `MealLog` ya no persiste `meal_type`; lo resuelve desde `meal`.

## Patrón de Adapter (Catálogos)

- `SupermarketCatalogProvider` define la interfaz pública
- Cada retailer implementa su propio adapter en `app/services/supermarket_catalog_providers/`
- Catálogos estáticos en `config/grocery_catalogs/`
- Agregar nuevo retailer = nuevo adapter, sin cambios en dominio

## Domain Spine

```
NutritionPlan (plan + metadata)
  └── Plan (ejecución diaria)
        └── Meal (unidad de comida planificada)
              └── MealLog (evidencia real + análisis AI)

Chat / Message (mensajería humana nutritionist ↔ patient)
NutritionistAiChat / PatientAiChat (copilots con contexto persistido)
GroceryList → GroceryListItem → GroceryProductMatch
PatientPrioritySnapshot (snapshot de radar)
```

## Integration Boundaries

- Proveedores LLM: solo accesibles a través de service classes (`app/services/`)
- Catálogos de supermercados: solo a través de `SupermarketCatalogProvider`
- Imágenes: siempre via Active Storage; URL de Cloudinary para LLM
- UI en tiempo real: Turbo Streams / Action Cable únicamente
- Auth: Devise con namespaces separados; ningún controller mezcla ambos tipos

## Namespaces de Rutas

```ruby
# Nutritionistas
authenticate :nutritionist do
  resources :patients do
    resources :nutrition_plans
    resources :profiles
    resources :patient_histories
  end
  get '/nutritionists/patient_radar', to: 'nutritionists#patient_radar'
end

# Pacientes
authenticate :patient do
  namespace :pats do
    resource :dashboard, only: :show
  end
  resources :meals do
    resources :meal_logs
  end
  resources :grocery_lists
end
```
