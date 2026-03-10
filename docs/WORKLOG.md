# Worklog

## 2026-03-10 (decimosexta sesión — pre-pilot refactors dt-1/dt-2/dt-3)

- Reconciliado el drift documental detectado durante la planificación:
  - `docs/ARCHITECTURE.md` ya no mantiene como deuda activa el `PlansController` resuelto.
  - `docs/IMPLEMENTATION_PLAN.md` y `docs/PROGRESS.md` quedaron alineados respecto a `patients.onboarding_state`.
- Refactorizado `NutritionPlanGeneratorService` para que:
  - reciba `patient:` y `nutritionist:`
  - limpie wrappers markdown antes de `JSON.parse`
  - valide el payload AI
  - persista `NutritionPlan -> Plan -> Meal` dentro de una transacción
  - levante `NutritionPlanGeneratorService::GenerationError` en fallo sin dejar datos parciales
- Adelgazado `NutritionPlansController#create`; ahora delega al servicio y renderiza `new` con `422 Unprocessable Content` si la generación falla.
- Eliminada la FK redundante `profiles.nutritionist_id`:
  - nueva migración con reemplazo del índice `profiles.patient_id` por uno único
  - `Profile` ahora deriva `nutritionist` a través de `patient`
  - `ProfilesController` crea perfiles con `@patient.build_profile`
- Eliminada la columna redundante `meal_logs.meal_type`; `MealLog` ahora delega `meal_type` a `meal`.
- Añadida cobertura:
  - `test/services/nutrition_plan_generator_service_test.rb`
  - error path en `NutritionPlansControllerTest`
  - bloqueo de segundo perfil en `ProfilesControllerTest`
- Validación ejecutada con PostgreSQL real:
  - `bundle exec rails db:migrate`
  - `bundle exec rails test test/services/nutrition_plan_generator_service_test.rb test/controllers/nutrition_plans_controller_test.rb test/controllers/profiles_controller_test.rb test/controllers/meal_logs_controller_test.rb`
  - resultado focalizado: `28 runs, 123 assertions, 0 failures, 0 errors`
  - regresión ampliada final:
    - `bundle exec rails test test/services/nutrition_plan_generator_service_test.rb test/controllers/patients_controller_test.rb test/controllers/profiles_controller_test.rb test/controllers/nutrition_plans_controller_test.rb test/controllers/patient_histories_controller_test.rb test/controllers/nutritionists_controller_test.rb test/controllers/plans_controller_test.rb test/controllers/meals_controller_test.rb test/controllers/meal_logs_controller_test.rb`
    - resultado: `60 runs, 260 assertions, 0 failures, 0 errors`
- Actualizados `docs/ARCHITECTURE.md`, `docs/DOMAIN_MODEL.md`, `docs/AI_AGENTS.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/PROGRESS.md`, `docs/DELIVERY_TRACKER.md`, `docs/WORKLOG.md` y `docs/LESSONS.md` para dejar el repo y la narrativa en el mismo estado, incluyendo los edge cases y correcciones descubiertos durante la ejecución.

## 2026-03-09 (decimoquinta sesión — sprint 1 tasks 05/06 operational revalidation)

- Reejecutada la validación operativa final de Sprint 1 tareas 5 y 6 en un entorno con acceso real a PostgreSQL, sin cambios en código de aplicación.
- Ejecutado `bundle exec rails db:prepare`; completó correctamente.
- Ejecutada la suite focalizada patient-side:
  - `bundle exec rails test test/controllers/meals_controller_test.rb test/controllers/meal_logs_controller_test.rb`
  - resultado: `17 runs, 73 assertions, 0 failures, 0 errors, 0 skips`
- Ejecutada la regresión completa de ownership/autorización de Sprint 1:
  - `bundle exec rails test test/controllers/patients_controller_test.rb test/controllers/profiles_controller_test.rb test/controllers/nutrition_plans_controller_test.rb test/controllers/patient_histories_controller_test.rb test/controllers/nutritionists_controller_test.rb test/controllers/plans_controller_test.rb test/controllers/meals_controller_test.rb test/controllers/meal_logs_controller_test.rb`
  - resultado: `55 runs, 229 assertions, 0 failures, 0 errors, 0 skips`
- Confirmado de nuevo que:
  - `current_patient` no puede leer ni mutar meals o meal_logs de otro paciente
  - los nested mismatches `meal_id`/`meal_log.id` responden `404`
  - la cobertura cross-tenant de nutritionist sigue verde
  - `/plans/:id` sigue sin exposición pública
- Actualizados `docs/DELIVERY_TRACKER.md`, `docs/WORKLOG.md` y `docs/PROGRESS.md` para dejar evidencia fresca del rerun.

## 2026-03-09 (decimocuarta sesión — serial test runner default)

- Aplicada la solución permanente al residual del runner PostgreSQL/paralelización en `test/test_helper.rb`:
  - ejecución serial por defecto
  - paralelización solo vía `PARALLELIZE_TESTS=1`
  - `PARALLEL_WORKERS` y `PARALLEL_THRESHOLD` quedan disponibles como override explícito
- La motivación fue operativa, no funcional: evitar el segfault observado de `pg` cuando Rails paralelizaba automáticamente suites grandes con PostgreSQL real.
- Validación ejecutada con acceso real a PostgreSQL sobre la misma corrida conjunta que antes disparaba el crash:
  - `bundle exec rails test test/controllers/patients_controller_test.rb test/controllers/profiles_controller_test.rb test/controllers/nutrition_plans_controller_test.rb test/controllers/patient_histories_controller_test.rb test/controllers/nutritionists_controller_test.rb test/controllers/plans_controller_test.rb test/controllers/meals_controller_test.rb test/controllers/meal_logs_controller_test.rb`
  - resultado: `55 runs, 229 assertions, 0 failures, 0 errors, 0 skips`
- Validación final ampliada del stack actual, ya incluyendo `test/controllers/devise_responder_status_test.rb`:
  - `bundle exec rails test test/controllers/devise_responder_status_test.rb test/controllers/patients_controller_test.rb test/controllers/profiles_controller_test.rb test/controllers/nutrition_plans_controller_test.rb test/controllers/patient_histories_controller_test.rb test/controllers/nutritionists_controller_test.rb test/controllers/plans_controller_test.rb test/controllers/meals_controller_test.rb test/controllers/meal_logs_controller_test.rb`
  - resultado: `58 runs, 241 assertions, 0 failures, 0 errors, 0 skips`
- Actualizados `docs/DELIVERY_TRACKER.md`, `docs/WORKLOG.md`, `docs/PROGRESS.md` y `docs/LESSONS.md` para reflejar que el workaround manual ya fue reemplazado por un default estable en el repo.

## 2026-03-09 (decimotercera sesión — rack 3 unprocessable-content cleanup)

- Migrados todos los renders residuales de `:unprocessable_entity` a `:unprocessable_content` en controllers request-level de nutritionist y patient (`PatientsController`, `ProfilesController`, `NutritionPlansController`, `PatientHistoriesController`, `MealsController`, `MealLogsController`, `WeightPatientsController`, `GroceryListsController`).
- Migradas las assertions de tests afectadas para esperar `:unprocessable_content` en vez de `:unprocessable_entity`.
- Corregido el punto global que seguía emitiendo el warning: `config/initializers/devise.rb` ahora usa `config.responder.error_status = :unprocessable_content`.
- Añadida cobertura dedicada en `test/controllers/devise_responder_status_test.rb` para:
  - `POST /patients/sign_in` inválido
  - `POST /nutritionists/sign_in` inválido
  - `POST /nutritionists` inválido
  Todas las respuestas ahora quedan verificadas con `422 Unprocessable Content`.
- Auditoría posterior al cambio:
  - `rg -uuu -n ":unprocessable_entity|unprocessable_entity" app config test lib` => 0 hits
  - sintaxis Ruby validada en controllers modificados clave
- Primer intento de validación conjunta sobre 55 tests disparó paralelización y expuso un problema del runner/stack:
  - `bundle exec rails test ...` => `pg` segfault al abrir workers en paralelo
  - workaround operativo adoptado: ejecutar las suites en grupos por debajo del threshold de paralelización
- Validación final ejecutada con acceso real a PostgreSQL y sin warnings deprecados de Rack 3:
  - `bundle exec rails test test/controllers/devise_responder_status_test.rb` => `3 runs, 12 assertions, 0 failures, 0 errors`
  - `bundle exec rails test test/controllers/devise_responder_status_test.rb test/controllers/patients_controller_test.rb test/controllers/profiles_controller_test.rb test/controllers/nutrition_plans_controller_test.rb test/controllers/patient_histories_controller_test.rb test/controllers/meals_controller_test.rb test/controllers/meal_logs_controller_test.rb` => `53 runs, 212 assertions, 0 failures, 0 errors`
  - `bundle exec rails test test/controllers/patients_controller_test.rb test/controllers/profiles_controller_test.rb test/controllers/nutrition_plans_controller_test.rb test/controllers/patient_histories_controller_test.rb test/controllers/nutritionists_controller_test.rb test/controllers/plans_controller_test.rb` => `38 runs, 156 assertions, 0 failures, 0 errors`
  - `bundle exec rails test test/controllers/meals_controller_test.rb test/controllers/meal_logs_controller_test.rb` => `17 runs, 73 assertions, 0 failures, 0 errors`
- Actualizados `docs/DELIVERY_TRACKER.md`, `docs/WORKLOG.md`, `docs/PROGRESS.md` y `docs/LESSONS.md` para dejar el cleanup resuelto y documentar el segfault de `pg` en validaciones paralelas.

## 2026-03-09 (duodécima sesión — sprint 1 task 03 patient controller scoping)

- Creada la rama `codex/sprint-01-task-03-patient-controller-scoping` desde `main` para aislar la auditoría del lado patient.
- Actualizado el contrato de rutas patient:
  - añadido `GET /meal_logs` como historial global autenticado
  - removido `GET /meals/:meal_id/meal_logs` para evitar el blind spot de index nested sin scoping por `meal_id`
- Endurecido `MealLogsController`:
  - `show` y `destroy` ahora cargan primero `@meal` vía `current_patient.meals.find(params[:meal_id])`
  - `set_meal_log` se resuelve desde `@meal.meal_log` y rechaza con `404` cualquier mismatch entre `meal_id` y `meal_log.id`
- Reauditado `MealsController`; el scoping existente con `current_patient.meals.find` y `current_patient.plans.find` se mantuvo porque ya cerraba los lookups críticos del CRUD.
- Ampliados fixtures patient-side:
  - nuevas meals propias/ajenas en `test/fixtures/meals.yml`
  - nuevo `test/fixtures/meal_logs.yml`
  - fixture mínimo de upload en `test/fixtures/files/meal-photo.jpg`
- Reemplazado el scaffold vacío de `MealLogsControllerTest` y añadido `MealsControllerTest` con cobertura request-level para:
  - listados scoped al paciente autenticado
  - `404` sobre meals/logs ajenos
  - edge case de nested-route mismatch (`/meals/:other_owned_meal_id/meal_logs/:owned_log_id`)
  - `create` con foto, `create` sin foto y enqueue de `MealLogAnalysisJob`
- Detectado y confirmado que el gotcha previo de Devise/Warden tras una `404` también aplica al bloque `authenticate :patient`; las pruebas quedaron estabilizadas dejando una sola request protegida fallida por ejemplo.
- Validación ejecutada con acceso real a PostgreSQL:
  - `bundle exec rails test test/controllers/meals_controller_test.rb test/controllers/meal_logs_controller_test.rb` => `17 runs, 73 assertions, 0 failures, 0 errors`
  - `bundle exec rails test test/controllers/patients_controller_test.rb test/controllers/profiles_controller_test.rb test/controllers/nutrition_plans_controller_test.rb test/controllers/patient_histories_controller_test.rb test/controllers/meals_controller_test.rb test/controllers/meal_logs_controller_test.rb` => `50 runs, 200 assertions, 0 failures, 0 errors`
- Actualizados `docs/IMPLEMENTATION_PLAN.md`, `docs/PROGRESS.md`, `docs/DELIVERY_TRACKER.md` y `docs/LESSONS.md` para dejar Sprint 1 cerrado y mover el foco de ejecución a Sprint 2.

## 2026-03-09 (undécima sesión — sprint 1 task 04 lookup validation)

- Creada la rama `codex/sprint-01-task-04-nutritionist-lookup-validation` para aislar la ejecución de Sprint 1 Task 04.
- Ejecutada la auditoría estática de ownership en controllers de nutritionist:
  - `rg -n "current_nutritionist\\.patients\\.find" app/controllers` => 4 hits válidos (`PatientsController`, `ProfilesController`, `NutritionPlansController`, `PatientHistoriesController`)
  - `rg -n "Patient\\.(find|find_by)\\(" ...controllers de nutritionist...` => 0 hits
- Expandida la cobertura request-level:
  - `PatientsControllerTest`: listados scoped al nutritionist autenticado
  - `ProfilesControllerTest`: side effects explícitamente bloqueados sobre paciente ajeno
  - `NutritionPlansControllerTest`: create/update/destroy cross-tenant y nested mismatch
  - `PatientHistoriesControllerTest`: index/new/edit/update/destroy cross-tenant y nested mismatch
  - `NutritionistsControllerTest`: dashboard y patient_radar solo muestran colecciones del nutritionist autenticado
- Detectado y resuelto un gotcha de test con Devise/Warden: después de una request que devuelve `404` bajo rutas protegidas por `authenticate :nutritionist`, la siguiente request del mismo ejemplo podía redirigir a sign-in; las pruebas se estabilizaron reautenticando antes de la siguiente request protegida y la lección quedó documentada en `docs/LESSONS.md`.
- Ejecutado `bundle exec rails db:prepare` con acceso real a PostgreSQL; completó correctamente.
- Ejecutada la suite focalizada:
  - `bundle exec rails test test/controllers/patients_controller_test.rb test/controllers/profiles_controller_test.rb test/controllers/nutrition_plans_controller_test.rb test/controllers/patient_histories_controller_test.rb test/controllers/nutritionists_controller_test.rb test/controllers/plans_controller_test.rb`
  - resultado final: `38 runs, 156 assertions, 0 failures, 0 errors`
- Actualizados `docs/IMPLEMENTATION_PLAN.md`, `docs/PROGRESS.md`, `docs/DELIVERY_TRACKER.md` y `docs/LESSONS.md`; reconciliado Sprint 1 a `3/6` tareas `done` (50%) porque el conteo previo estaba inflado respecto al estado real de las tareas.

## 2026-03-09 (décima sesión — validación final con PostgreSQL real)

- Ejecutado `bundle exec rails db:prepare` con acceso real a PostgreSQL; completó correctamente.
- Ejecutada la suite focalizada:
  - `bundle exec rails test test/controllers/patients_controller_test.rb test/controllers/profiles_controller_test.rb test/controllers/nutrition_plans_controller_test.rb test/controllers/patient_histories_controller_test.rb test/controllers/plans_controller_test.rb`
  - resultado: `24 runs, 73 assertions, 0 failures, 0 errors`
- Cerrado el bloqueo de repo para PostgreSQL/Bundler: el residual actual es solo la limitación del sandbox por defecto cuando no tiene permisos elevados.
- Actualizados `docs/LESSONS.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/PROGRESS.md` y `docs/DELIVERY_TRACKER.md` para reflejar que Sprint 1 Task 01/02 ya quedó validado con base real.

## 2026-03-09 (novena sesión — schema repair y cierre de Sprint 1 Task 02)

- Creada la rama `codex/sprint-01-task-02-test-db-schema-repair` sobre el trabajo ya existente de Task 02 para aislar la remediación operativa.
- Añadida en `docs/LESSONS.md` la lección explícita del bloqueo de `rails test` por acceso a PostgreSQL y `schema.rb` atrasado, incluyendo la causa adicional detectada en `meal_distribution`.
- Confirmado con acceso a DB que el bloqueo ya no era solo el sandbox: la migración `20251010101000_restore_meal_distribution_and_add_grocery_domains.rb` fallaba porque había filas de `nutrition_plans.meal_distribution` serializadas con formato hash de Ruby (`=>`) en lugar de JSON válido.
- Endurecida la migración `20251010101000` para normalizar `meal_distribution` a JSON antes de convertir la columna a `jsonb`; tras eso `bundle exec rails db:migrate` completó correctamente.
- Ejecutado `bundle exec rails db:schema:dump`; `db/schema.rb` quedó en versión `2025_10_10_101000` con `patients.onboarding_state`, `meal_logs.analysis_status`, `nutrition_plans.meal_distribution: jsonb` y tablas grocery/radar.
- La base de test estaba inconsistente (`PG::DuplicateColumn` en `nutritionist_ai_chats` durante `RAILS_ENV=test db:prepare`); se resolvió recreándola desde cero con `env RAILS_ENV=test bundle exec rails db:drop db:create db:schema:load`.
- Ajustadas las pruebas de integración para validar `404` manejado por Rails en lugar de excepciones propagadas, corregido el smoke test legado de `/plans/:id`, aislado el delete de `NutritionPlan` de fixtures con FK activas y reemplazado el stub del generador por un override controlado del constructor.
- Verificaciones ejecutadas con éxito:
  - `bundle exec rails runner "puts ActiveRecord::Base.connection.migration_context.current_version"` => `20251010101000`
  - `bundle exec rails runner "puts Patient.column_names.grep(/onboarding|invitation|access/).inspect"` => columnas operacionales presentes
  - `bundle exec rails runner "puts NutritionPlan.columns_hash['meal_distribution'].sql_type"` => `jsonb`
  - `bundle exec rails test test/controllers/patients_controller_test.rb test/controllers/profiles_controller_test.rb test/controllers/nutrition_plans_controller_test.rb test/controllers/patient_histories_controller_test.rb test/controllers/plans_controller_test.rb` => `24 runs, 73 assertions, 0 failures, 0 errors`
- Residual menor detectado: Rails/Rack 3 emite warnings por `:unprocessable_entity`; no bloquea la suite, pero conviene migrar a `:unprocessable_content` en una pasada separada.

## 2026-03-09 (octava sesión — postgresql connectivity hardening)

- Confirmado por diagnóstico por capas que PostgreSQL sí estaba escuchando en `127.0.0.1:5432`, pero el sandbox no podía alcanzarlo ni por socket Unix ni por TCP loopback.
- Actualizado `config/database.yml` para que development/test usen TCP por defecto mediante `PGHOST`/`PGPORT` y credenciales opcionales por entorno.
- Actualizado `.env.example` para reflejar `DATABASE_URL` en `127.0.0.1:5432` y variables `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`.
- Enriquecidos `docs/DEPLOYMENT.md` y `docs/LESSONS.md` con diagnóstico operativo, comandos de verificación y la distinción entre fallo del repo y restricción del sandbox.
- Actualizados `docs/DELIVERY_TRACKER.md` y `docs/PROGRESS.md` para reflejar que el siguiente paso ya no es arreglar Bundler sino validar PostgreSQL en un entorno con acceso real a DB.

## 2026-03-09 (séptima sesión — bundler corregido, nuevo bloqueo DB)

- Aplicado fix global en `~/.zprofile` para cargar `rbenv` también en shells login no interactivas.
- Verificación posterior al fix:
  - `ruby -v` => `3.3.5`
  - `which ruby` => `~/.rbenv/shims/ruby`
  - `which bundle` => `~/.rbenv/shims/bundle`
  - `bundle -v` => `2.7.1`
  - `bundle exec rails about` ejecuta correctamente
- Reintentada la suite focalizada de Sprint 1 Task 01; el bloqueo cambió de Bundler a acceso a PostgreSQL:
  - `connection to server on socket "/tmp/.s.PGSQL.5432" failed: Operation not permitted`
- Actualizados `docs/LESSONS.md` y `docs/DELIVERY_TRACKER.md` para reflejar que el problema de Bundler quedó resuelto y que el siguiente bloqueo real es el acceso al socket local de PostgreSQL desde el sandbox.

## 2026-03-09 (sexta sesión — bundler/rbenv activación global)

- Confirmado que el bloqueo de `bundle exec ...` no era ausencia real de Bundler: `rbenv` ya tenía Ruby `3.3.5` y Bundler `2.7.1` instalados.
- Aislada la causa raíz operativa:
  - `ruby -v` resolvía a `2.6.10` del sistema.
  - `bundle` resolvía a `/usr/bin/bundle`.
  - `rbenv exec ruby -v` y `rbenv exec bundle _2.7.1_ -v` funcionaban correctamente.
- Confirmado que `.zshrc` cargaba `rbenv`, pero `.zprofile` no; esto dejaba shells login no interactivas sin activación correcta.
- Actualizados `docs/LESSONS.md`, `docs/DEPLOYMENT.md` y `docs/DELIVERY_TRACKER.md` con el diagnóstico real, fallback temporal y criterio de verificación.

## 2026-03-09 (quinta sesión — sprint 1 task 02 scoping)

- Creada la rama `codex/sprint-01-task-02-nutritionist-controller-scoping` desde `main` para aislar la auditoría de ownership en controllers de nutritionist.
- Endurecido `NutritionPlansController`: todas las acciones nested ahora cargan `@patient` vía `current_nutritionist.patients.find(params[:patient_id])` y resuelven el plan con `@patient.nutrition_plans.find(params[:id])`, cerrando el hueco de inconsistencia entre `patient_id` y `nutrition_plan.id`.
- Endurecido `PatientHistoriesController`: `nutrition_plan_id` ya no se acepta ciegamente desde params; se re-scopea contra `@patient.nutrition_plans` y se rechaza con `unprocessable_entity` si intenta enlazar un plan de otro paciente.
- Reemplazados tests scaffold vacíos por integration tests con autenticación Devise para `PatientsController`, `ProfilesController`, `NutritionPlansController` y nuevo `PatientHistoriesControllerTest`.
- Añadidas fixtures mínimas reales para `nutritionists`, `patients`, `profiles`, `nutrition_plans`, `plans`, `meals` y `patient_histories`, con dos nutritionists y pacientes separados para validar cross-tenant access y nested-route mismatch.
- Actualizado `test/test_helper.rb` para habilitar `Devise::Test::IntegrationHelpers` en integration tests.
- Actualizados `docs/DELIVERY_TRACKER.md` y `docs/IMPLEMENTATION_PLAN.md` para reflejar que la tarea pasó de implementación parcial a revisión con bloqueo residual de validación local.
- Verificación pendiente: no se pudo ejecutar la suite focalizada de Rails en este sandbox porque el entorno no tiene acceso operativo al socket local de PostgreSQL; además, si el entorno de pruebas usa `db/schema.rb`, puede requerir migrar primero porque el schema sigue desactualizado respecto a `patients.onboarding_state`.

## 2026-03-09 (cuarta sesión — sprint 1 task 01)

- Eliminado `PlansController` legacy inseguro junto con su vista placeholder `app/views/plans/show.html.erb`.
- Removida la referencia comentada a `GET /plans/:id` en `config/routes.rb` para evitar reactivación accidental del endpoint.
- Añadida cobertura mínima de seguridad:
  - `test/controllers/plans_controller_test.rb` ahora verifica que `/plans/:id` no está expuesto.
  - `test/controllers/nutrition_plans_controller_test.rb` ahora cubre acceso válido del nutritionist dueño y bloqueo cross-tenant vía `ActiveRecord::RecordNotFound`.
- Registrada la decisión arquitectónica en `docs/DECISIONS.md`: el detalle soportado de planes vive en `NutritionPlansController`; cualquier detalle diario futuro para paciente será un endpoint nuevo y scoped.
- Actualizados `docs/IMPLEMENTATION_PLAN.md` y `docs/DELIVERY_TRACKER.md` para marcar Sprint 1 Task 01 como resuelta.

## 2026-03-09 (tercera sesión — code review arquitectónico)

- Revisión completa del código (models, controllers, services, jobs, migrations, schema, routes) contra la documentación creada.
- **Hallazgo crítico:** `PlansController` sin autenticación — `Plan.find(params[:id])` expuesto a cualquier request no autenticado. Registrado en IMPLEMENTATION_PLAN como DT-1 prioridad crítica.
- **Hallazgo importante:** Lógica de creación de Plans/Meals (20+ líneas) en `NutritionPlansController#create` sin transaction block — viola ADR-007 y crea riesgo de planes incompletos. Registrado como DT-2.
- **Hallazgo importante:** `Profile#belongs_to :nutritionist` es FK derivable que puede quedar inconsistente. Registrado como DT-3.
- **Hallazgo importante:** `schema.rb` en versión 20251006 no incluye migraciones 20251010 (grocery domain, operational states). `db:schema:load` está roto para nuevos entornos. Registrado como DT-4.
- Corregidos errores factuales en DOMAIN_MODEL.md: campos de Nutritionist/Patient (first_name/last_name/phone, no name), Profile (goals no goal, tiene nutritionist_id), GroceryListItem (normalized_name, quantity_value/unit, meal_types jsonb, source_dates jsonb — no category/quantity), GroceryProductMatch (external_id, brand, package_size, availability boolean, rank, metadata jsonb — no match_score), PatientPrioritySnapshot (outreach_draft), GroceryList (generated_by), MealLog (ai_health_score es float no integer; meal_type denormalizado), NutritionistAiChat (model field).
- Añadidas deudas técnicas a ARCHITECTURE.md y LESSONS.md.
- Actualizado IMPLEMENTATION_PLAN.md con tarea 🔴 urgente para PlansController y tabla de deuda técnica.

## 2026-03-09 (segunda sesión)

- Enriquecimiento completo de documentación arquitectónica.
- `docs/DOMAIN_MODEL.md`: agregadas tablas de campos por entidad, tipos, esquemas JSONB canónicos (meal_distribution, ai_comparison, source_summary), métodos custom y reglas de valores.
- `docs/ARCHITECTURE.md`: agregado diagrama de capas, flujos de datos críticos (análisis foto, generación plan, lista compras, onboarding, radar), máquinas de estado (Patient, MealLog, GroceryList, NutritionPlan), patrón de service objects, patrón adapter, namespaces de rutas.
- `docs/AI_AGENTS.md`: agregados contratos completos por servicio (NutritionPlanGeneratorService, MealLogAnalysisService, PatientRadarService, ShoppingListGeneratorService), esquemas de input/output JSON, criterios de ai_health_score, reglas de parsing y confiabilidad.
- `docs/DECISIONS.md`: agregados ADR-004 a ADR-010 cubriendo dual Devise auth, Profile separado, jerarquía 4-niveles, service objects, JSONB, background jobs, y adapter pattern.
- `docs/DEPLOYMENT.md`: agregada tabla de variables de entorno, configuración de queue adapter, queues definidas, estrategia de retry, configuración de Active Storage, y proceso de deploy.
- `docs/DATA_FLOWS.md` (nuevo): flujos de secuencia detallados para análisis de foto, generación de plan, lista de compras, onboarding de paciente, patient radar, y AI chat.
- `docs/IMPLEMENTATION_PLAN.md` (nuevo): desglose técnico por sprint (0-9 y 10) con tareas, archivos, precondiciones y criterios de done.
- `docs/PROGRESS.md` (nuevo): estado actual por sprint con porcentajes, componentes por estado, historial de closures y próximas prioridades.
- `docs/LESSONS.md` (nuevo): errores recurrentes con causa y solución, patrones que fallaron, gotchas del stack (Devise, Active Job, ruby_llm, JSONB, Cloudinary, nested resources), lecciones de arquitectura.

## 2026-03-09

- Started sprint 0 execution.
- Added canonical agent guidance and delivery-control documents.
- Created roadmap and tracker structure for continuous progress updates.
- Added repository-local skills for Rails core, UX/UI, AI contracts, grocery intelligence, production debugging, and testing.
- Added subagent role docs and routing guidance.
- Added `.env.example` and aligned `CLAUDE.md` with the canonical docs.
- Implemented the first grocery-list vertical slice: routes, models, migrations, provider architecture, static retailer catalogs for Chile and Spain, service layer, and patient-facing UI.
- Added patient radar baseline service and nutritionist-facing view.
- Added image preflight service and asynchronous meal-log analysis job scaffold.
- Hardened several nutritionist/patient controller scopes around authenticated ownership.
- Performed static syntax checks on key new Ruby files and YAML catalog files.
- Full Rails validation is still blocked locally because the repository expects Ruby 3.3.5 and Bundler 2.7.1 while this environment cannot boot `bin/rails`.
