# Progress

Complementa DELIVERY_TRACKER.md con porcentaje por sprint y estado actual de trabajo.

**Última actualización:** 2026-03-09 (postgres + focused suite validated)

---

## Estado Actual

### En progreso ahora:
- Auditoría de scoping en controllers de paciente

### Bloqueadores activos:
- No hay bloqueadores de repo para Sprint 1 Task 01/02: la migración 20251010, `db:prepare` y la suite focalizada ya fueron validadas en un entorno con acceso a PostgreSQL
- Restricción residual del sandbox por defecto:
  - sin permisos elevados este entorno aún no puede usar loopback ni el socket Unix local de PostgreSQL
  - para ejecutar `rails test` o `db:*` desde aquí hay que usar una terminal/CI con acceso real a DB o permisos aprobados

---

## Sprints

| Sprint | Nombre | Tareas Done | Total | % | Estado |
|--------|--------|-------------|-------|---|--------|
| 0 | Base and Canon | 4 | 4 | 100% | ✅ done |
| 1 | Security and Ownership | 4 | 6 | 67% | 🔄 in_progress |
| 2 | Nutritionist UX/UI | 1 | 5 | 20% | 🔄 parcial |
| 3 | Patient Access Flow | 0 | 6 | 0% | ⏳ planned |
| 4 | Patient App Hardening | 2 | 5 | 40% | 🔄 parcial |
| 5 | Images and Meal Logs | 2 | 6 | 33% | 🔄 parcial |
| 6 | Core Clinical AI | 1 | 4 | 25% | 🔄 parcial |
| 7 | Copilots and AI Performance | 0 | — | — | ⏳ planned |
| 8 | Differential AI | 1 | — | — | 🔄 (radar service OK) |
| 9 | Food Purchase List | 3 | 7 | 43% | 🔄 parcial |
| 10 | Chat, Hardening, Deploy | 0 | — | — | ⏳ planned |

**Nota:** totales de sprints 7, 8, 10 pendientes de definir en IMPLEMENTATION_PLAN.md.

---

## Componentes por Estado

### ✅ Implementado y funcional
- Autenticación dual Devise (Nutritionist + Patient)
- Modelos core: Patient, Profile, NutritionPlan, Plan, Meal, MealLog, WeightPatient
- Modelos de chat: Chat, Message, NutritionistAiChat, PatientAiChat
- Modelos de grocery: GroceryList, GroceryListItem, GroceryProductMatch (migraciones 20251010 ejecutadas; falta validar flujo end-to-end)
- PatientRadarService (scoring funcional, sin persistencia de snapshots)
- MealLogAnalysisJob (scaffold completo, falta retry config y validación staging)
- ImagePreflightService (scaffold)
- ShoppingListGeneratorService (scaffold)
- Catálogos estáticos: Jumbo-CL, Mercadona-ES
- SupermarketCatalogProvider adapter pattern
- Routes completas (nutritionist + patient namespaces)

### 🔄 Parcialmente implementado
- Scoping de controllers de nutritionist auditado y validado con tests
- `PlansController` legacy inseguro eliminado; cobertura mínima de route regression y ownership agregada
- Dashboard de nutritionist
- Dashboard de paciente
- Vista de paciente (show) con info básica
- UI de meal_logs (lista y creación parcial)
- UI de grocery lists (scaffold)
- Vista patient_radar (existe pero no integrada en dashboard)

### ⏳ Pendiente de implementar
- onboarding_state en Patient (columnas migradas; falta enum + flujo de invitación)
- UI de análisis async con Turbo Streams (estados queued/processing/completed)
- Registro de peso (WeightPatient UI)
- Edición inline de meals generadas
- UserSupermarketPreference UI
- PatientPrioritySnapshot persistencia
- Tests de autorización cross-tenant del lado patient
- Tests de servicios

---

## Historial de Sprint Closures

| Sprint | Fecha de Cierre | Notas |
|--------|----------------|-------|
| Sprint 0 | 2026-03-09 | Canon docs, skills, subagent routing, .env.example |

---

## Próximas Prioridades

1. Completar auditoría de scoping en controllers de paciente (Sprint 1)
2. Expandir tests de autorización cross-tenant al lado paciente
3. Continuar con dashboard y flujos de nutritionist sobre el schema ya alineado
4. Integrar Patient Radar en dashboard nutritionist
5. Configurar retry en MealLogAnalysisJob y validar en staging
