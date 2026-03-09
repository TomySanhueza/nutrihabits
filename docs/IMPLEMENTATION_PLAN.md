# Implementation Plan

Desglose técnico de sprints activos y próximos. Complementa ROADMAP.md (alto nivel) y DELIVERY_TRACKER.md (estado) con tareas concretas y dependencias.

**Regla:** actualizar este archivo cuando una tarea se completa o se descubren nuevas dependencias.

---

## Próximo a Implementar

**Sprint 2 — Nutritionist UX/UI** es el foco inmediato. Sprint 1 quedó validado con cobertura request-level en controllers de nutritionist y patient, además de regresión sobre PostgreSQL real.

---

## Sprint 0 — Base and Canon

**Goal:** Repo bootstraps cleanly y documentación canónica existe.

| # | Tarea | Archivos | Estado | Notas |
|---|-------|----------|--------|-------|
| 1 | Documentación canónica (AGENTS.md, docs/*) | `docs/`, `AGENTS.md`, `CLAUDE.md` | ✅ done | |
| 2 | Skills locales para agentes | `.codex/skills/` | ✅ done | |
| 3 | Subagent routing docs | `docs/subagents/`, `docs/SUBAGENT_ROUTING.md` | ✅ done | |
| 4 | `.env.example` | `.env.example` | ✅ done | |

**Criterio de done:** ✅ docs canónicas existen y están alineadas con CLAUDE.md

---

## Sprint 1 — Security and Ownership

**Goal:** No cross-tenant data access.

| # | Tarea | Archivos a modificar | Precondición | Estado |
|---|-------|---------------------|--------------|--------|
| 1 | **URGENTE: eliminar `PlansController` legacy inseguro** y consolidar el acceso en `NutritionPlansController` | `app/controllers/plans_controller.rb`, `app/views/plans/show.html.erb`, `config/routes.rb`, `test/controllers/plans_controller_test.rb`, `test/controllers/nutrition_plans_controller_test.rb` | ninguna | ✅ done |
| 2 | Auditar scoping en todos los controllers de nutritionist | `patients_controller.rb`, `nutrition_plans_controller.rb`, `profiles_controller.rb`, `patient_histories_controller.rb` | ninguna | ✅ done |
| 3 | Auditar scoping en controllers de paciente | `meal_logs_controller.rb`, `meals_controller.rb` | ninguna | ✅ done |
| 4 | Validar que `current_nutritionist.patients.find` se use en todos los lookups | todos los controllers de nutritionist | tarea 2 | ✅ done |
| 5 | Validar que `current_patient` no puede acceder meals de otro patient | `MealLogsController`, rutas | tarea 3 | ✅ done |
| 6 | Tests de autorización cross-tenant | `test/controllers/` | tareas 2-5 | ✅ done |

**Criterio de done:** ningún request de nutritionist A puede leer datos de pacientes de nutritionist B; ningún paciente puede leer datos de otro paciente. El legado inseguro de `PlansController` fue eliminado y la superficie soportada queda en `NutritionPlansController`.

## Deuda Técnica — Refactors Pendientes (no bloqueantes para piloto)

| # | Deuda | Archivo | Impacto | Prioridad |
|---|-------|---------|---------|-----------|
| DT-1 | Mover creación de Plans/Meals a `NutritionPlanGeneratorService` + transaction | `nutrition_plans_controller.rb`, `nutrition_plan_generator_service.rb` | Riesgo de plan incompleto si LLM response es parcial | Media |
| DT-2 | Eliminar `Profile#belongs_to :nutritionist` (FK derivable) | `profile.rb`, migración | Riesgo de inconsistencia si paciente cambia de nutricionista | Media |
| DT-3 | Eliminar `MealLog#meal_type` o añadir validación de consistencia | `meal_log.rb`, migración | Datos duplicados sin garantía de coherencia | Baja |

---

## Sprint 2 — Nutritionist UX/UI

**Goal:** Flujos de nutritionist funcionan con datos reales.

| # | Tarea | Archivos | Precondición | Estado |
|---|-------|----------|--------------|--------|
| 1 | Dashboard del nutritionist con resumen de pacientes | `app/views/nutritionists/`, controller | Sprint 1 done | ⏳ pendiente |
| 2 | Vista de paciente con historial de planes y pesos | `app/views/patients/show.html.erb` | ninguna | 🔄 parcial |
| 3 | Patient Radar integrado en dashboard nutritionist | `app/views/nutritionists/`, `PatientRadarService` | servicio OK | 🔄 servicio OK, falta integración dashboard |
| 4 | Generación de plan via formulario (UI completa) | `app/views/nutrition_plans/` | Sprint 1 | ⏳ pendiente |
| 5 | Edición manual de meals generadas | `app/views/meals/`, nested forms | tarea 4 | ⏳ pendiente |

**Criterio de done:** nutritionist puede ver pacientes, generar plan, ver radar, todo con datos reales.

---

## Sprint 3 — Patient Access Flow

**Goal:** Invitación y activación estables.

| # | Tarea | Archivos | Precondición | Estado |
|---|-------|----------|--------------|--------|
| 1 | Migración: agregar `onboarding_state`, `invitation_*_at` a patients | `db/migrate/` | ninguna | ⏳ pendiente (campos definidos en plan pero migración no ejecutada) |
| 2 | Patient#onboarding_state enum en modelo | `app/models/patient.rb` | migración 1 | ⏳ pendiente |
| 3 | Acción de invitación en PatientsController | `app/controllers/patients_controller.rb` | tarea 2 | ⏳ pendiente |
| 4 | Email de invitación (Devise invitation o custom mailer) | `app/mailers/` | tarea 3 | ⏳ pendiente |
| 5 | Endpoint de aceptación de invitación | routes + controller | tarea 4 | ⏳ pendiente |
| 6 | Actualizar PatientRadarService para usar onboarding_state | `app/services/patient_radar_service.rb` | tarea 2 | ⏳ pendiente |

**Criterio de done:** nutritionist invita paciente → paciente recibe email → paciente activa cuenta → onboarding_state: active.

---

## Sprint 4 — Patient App Hardening

**Goal:** App del paciente coherente end-to-end.

| # | Tarea | Archivos | Precondición | Estado |
|---|-------|----------|--------------|--------|
| 1 | Dashboard del paciente con plan activo | `app/views/pats/dashboard/show.html.erb` | Sprint 3 | 🔄 parcial |
| 2 | Vista de meals del día actual | `app/views/meals/` | ninguna | ⏳ pendiente |
| 3 | Flujo de registro de comida (sin foto) | `app/controllers/meal_logs_controller.rb` | ninguna | 🔄 parcial |
| 4 | Historial de meal_logs del paciente | `app/views/meal_logs/index.html.erb` | ninguna | 🔄 parcial |
| 5 | Registro de peso | `app/controllers/weight_patients_controller.rb` | ninguna | ⏳ pendiente |

**Criterio de done:** paciente puede ver su plan, registrar comidas, registrar peso; flujo coherente sin errores.

---

## Sprint 5 — Images and Meal Logs

**Goal:** Uploads y análisis son production-safe.

| # | Tarea | Archivos | Precondición | Estado |
|---|-------|----------|--------------|--------|
| 1 | ImagePreflightService completo | `app/services/image_preflight_service.rb` | ninguna | 🔄 scaffold OK |
| 2 | Integrar preflight en MealLogsController antes de upload | `app/controllers/meal_logs_controller.rb` | tarea 1 | ⏳ pendiente |
| 3 | MealLogAnalysisJob con retry configurado | `app/jobs/meal_log_analysis_job.rb` | ninguna | 🔄 scaffold OK, falta retry config |
| 4 | UI de estado de análisis (queued/processing/completed/failed) | `app/views/meal_logs/` | ninguna | ⏳ pendiente |
| 5 | Turbo Stream o polling para actualizar analysis_status | vistas + controller | tarea 4 | ⏳ pendiente |
| 6 | Validar pipeline completo en staging | — | tareas 1-5 | ⏳ pendiente |

**Criterio de done:** foto subida → preflight OK → job encolado → análisis async → resultado visible para paciente.

---

## Sprint 6 — Core Clinical AI

**Goal:** Planes generados de forma confiable y editables.

| # | Tarea | Archivos | Precondición | Estado |
|---|-------|----------|--------------|--------|
| 1 | NutritionPlanGeneratorService robusto (manejo de errores, retry) | `app/services/nutrition_plan_generator_service.rb` | ninguna | 🔄 funcional, falta hardening |
| 2 | UI de generación con loading state | `app/views/nutrition_plans/` | ninguna | ⏳ pendiente |
| 3 | Edición inline de meals generadas | forms anidados | ninguna | ⏳ pendiente |
| 4 | PatientHistory integrado en contexto del generador | `app/models/patient_history.rb`, servicio | ninguna | ⏳ pendiente |

**Criterio de done:** nutritionist genera plan, puede editarlo, plan activo visible para paciente.

---

## Sprint 9 — Food Purchase List (Grocery)

**Goal:** Lista de compras usable para Chile y España.

| # | Tarea | Archivos | Precondición | Estado |
|---|-------|----------|--------------|--------|
| 1 | Ejecutar migraciones pendientes de grocery domain | `db/migrate/20251010*` | Rails boot OK | 🔄 parcial (migraciones 20251010 validadas y `schema.rb` alineado; falta validar flujo grocery end-to-end) |
| 2 | Validar modelos GroceryList, GroceryListItem, GroceryProductMatch | `app/models/grocery_*.rb` | migración 1 | 🔄 modelos OK |
| 3 | ShoppingListGeneratorService completo | `app/services/shopping_list_generator_service.rb` | tarea 2 | 🔄 scaffold OK |
| 4 | UI de lista de compras para paciente | `app/views/grocery_lists/` | tarea 3 | 🔄 scaffold OK |
| 5 | Catálogos estáticos validados (Jumbo-CL, Mercadona-ES) | `config/grocery_catalogs/` | ninguna | 🔄 archivos existen |
| 6 | UserSupermarketPreference UI (preferencia de retailer) | `app/models/user_supermarket_preference.rb` | ninguna | ⏳ pendiente |
| 7 | Tests de ShoppingListGeneratorService | `test/services/` | tareas 3-5 | ⏳ pendiente |

**Criterio de done:** paciente selecciona retailer, genera lista, ve productos sugeridos con precios.

---

## Notas de Dependencias Globales

- **Ruby 3.3.5 + Bundler 2.7.1** requeridos para `bin/rails`. El toolchain quedó validado; usar terminal/CI con acceso real a PostgreSQL para tareas DB.
- **Sidekiq + Redis** requeridos antes de Sprint 5 (jobs de análisis de foto).
- **Cloudinary credentials** en `bin/rails credentials:edit` antes de Sprint 5 (uploads en producción).
- **OPENAI_API_KEY** requerido para Sprints 5 y 6.
