# Decisions

## ADR-001: Closed pilot first

- Status: accepted
- Context: The scope is broad and touches clinical workflows, AI, uploads, and real-time features.
- Decision: Prioritize a closed pilot instead of open self-serve SaaS.
- Consequence: Security, onboarding, observability, and operational reliability take precedence over growth features.

## ADR-002: Canonical domain values in English

- Status: accepted
- Context: Current code mixes Spanish and English values across views, prompts, and persistence.
- Decision: Persist canonical values in English and translate at the UI layer.
- Consequence: Reduces ambiguity in services, jobs, and future integrations.

## ADR-003: Grocery list uses adapter-based catalog providers

- Status: accepted
- Context: The grocery feature needs Chile and Spain support and may rely on different data sources per retailer.
- Decision: Use `SupermarketCatalogProvider` with retailer adapters and cached normalized results.
- Consequence: Scraping or manual feeds stay at the edge of the system instead of polluting the core domain.

## ADR-004: Dual Devise authentication (Nutritionist + Patient como modelos separados)

- Status: accepted
- Context: La plataforma sirve a dos tipos de usuarios con flujos de acceso completamente distintos. Nutritionists se registran; patients son creados por nutritionists (no pueden registrarse). Sus rutas, dashboards y permisos no se solapan.
- Decision: Usar dos modelos Devise separados (`Nutritionist` y `Patient`) con namespaces de ruta propios, en lugar de un modelo `User` con roles.
- Consequence: No hay riesgo de escalada de privilegios entre tipos. Cada modelo puede evolucionar su flujo de auth de forma independiente. Complejidad ligeramente mayor en setup de Devise, pero separación de responsabilidades clara.

## ADR-005: Profile separado de Patient (one-to-one)

- Status: accepted
- Context: El modelo `Patient` es la entidad de autenticación Devise. Los datos clínicos (peso, talla, objetivos, diagnóstico) son datos de salud sensibles con un ciclo de vida distinto al de la cuenta.
- Decision: Tabla `profiles` separada con FK a `patients` (one-to-one), no campos directos en `patients`.
- Consequence: Paciente puede autenticarse sin tener un perfil completo. Datos clínicos pueden editarse sin tocar el modelo de auth. Facilita auditoría separada de datos de salud.

## ADR-006: Jerarquía NutritionPlan → Plan → Meal → MealLog (4 niveles)

- Status: accepted
- Context: Se necesita granularidad por comida individual para análisis de foto (MealLog), tracking diario (Plan), y visión de macro del plan (NutritionPlan).
- Decision: Cuatro entidades con relaciones has_many anidadas.
- Consequence: Queries más complejas (se mitigan con métodos custom en Patient). La granularidad permite análisis detallado por comida y tracking de adherencia día a día, lo cual es core del producto.

## ADR-007: Service Objects para toda la lógica AI (no en modelos ni controllers)

- Status: accepted
- Context: La lógica de LLM es compleja, tiene efectos secundarios externos (llamadas a API), y necesita ser testeable de forma aislada.
- Decision: Todo el trabajo AI vive en `app/services/`. Los controllers solo orquestan; los modelos solo persisten.
- Consequence: Servicios son stateless y mockeables en tests. Jobs pueden reutilizar servicios sin duplicar lógica. Facilita cambiar proveedor LLM sin tocar controllers ni modelos.

## ADR-008: JSONB para datos semi-estructurados (meal_distribution, ai_comparison, context)

- Status: accepted
- Context: Las salidas de LLM evolucionan con los prompts. Forzar schema rígido requeriría migraciones por cada ajuste de prompt. `meal_distribution` varía por número de días del plan.
- Decision: Usar columnas JSONB de PostgreSQL para datos cuya estructura puede cambiar: `meal_distribution`, `ai_comparison`, `context` de chats AI, `metadata` de mensajes AI.
- Consequence: Flexibilidad sin migraciones. Se requiere validación en servicio antes de persistir. Los campos JSONB son auditables pero no autoritativos (los campos tipados son la fuente de verdad cuando ambos existen).

## ADR-009: Background Jobs para análisis de fotos (no síncrono)

- Status: accepted
- Context: GPT-4o Vision tiene latencia de 3-10 segundos. Bloquear el request cycle durante ese tiempo degrada la UX y puede causar timeouts en producción.
- Decision: `MealLogsController#create` encola `MealLogAnalysisJob` inmediatamente después de crear el `MealLog` con `analysis_status: :queued`. El análisis ocurre async.
- Consequence: UX responsiva — el paciente ve el estado `queued` → `processing` → `completed` via polling o Turbo Streams. Requiere queue adapter configurado (Sidekiq o similar) y manejo de errores con retry.

## ADR-010: Adapter pattern para catálogos de supermercados

- Status: accepted
- Context: Cada retailer (Jumbo, Líder, Mercadona, etc.) tiene una fuente de datos distinta: algunos tienen API, otros requieren scraping, otros usan catálogos estáticos CSV/JSON.
- Decision: `SupermarketCatalogProvider` define la interfaz. Cada retailer tiene su adapter en `app/services/supermarket_catalog_providers/`. Catálogos estáticos en `config/grocery_catalogs/`.
- Consequence: Agregar un nuevo retailer = crear un adapter, sin cambios en el dominio ni en `ShoppingListGeneratorService`. Catálogos estáticos permiten funcionar sin APIs externas en el piloto.
