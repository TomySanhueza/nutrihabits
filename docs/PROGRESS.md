# Progress

Complementa DELIVERY_TRACKER.md con porcentaje por sprint y estado actual de trabajo.

**Última actualización:** 2026-03-09

---

## Estado Actual

### En progreso ahora:
- Mejora de documentación de arquitectura (este conjunto de archivos)

### Bloqueadores activos:
- Rails boot local bloqueado: entorno requiere Ruby 3.3.5 + Bundler 2.7.1
  - Impacta: ejecución de migraciones pendientes (grocery domain, onboarding_state)
  - Impacta: validación end-to-end de flujos async (MealLogAnalysisJob)

---

## Sprints

| Sprint | Nombre | Tareas Done | Total | % | Estado |
|--------|--------|-------------|-------|---|--------|
| 0 | Base and Canon | 4 | 4 | 100% | ✅ done |
| 1 | Security and Ownership | 2 | 5 | 40% | 🔄 in_progress |
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
- Modelos de grocery: GroceryList, GroceryListItem, GroceryProductMatch (migraciones pendientes de ejecutar)
- PatientRadarService (scoring funcional, sin persistencia de snapshots)
- MealLogAnalysisJob (scaffold completo, falta retry config y validación staging)
- ImagePreflightService (scaffold)
- ShoppingListGeneratorService (scaffold)
- Catálogos estáticos: Jumbo-CL, Mercadona-ES
- SupermarketCatalogProvider adapter pattern
- Routes completas (nutritionist + patient namespaces)

### 🔄 Parcialmente implementado
- Scoping de controllers (auditoría en progreso)
- Dashboard de nutritionist
- Dashboard de paciente
- Vista de paciente (show) con info básica
- UI de meal_logs (lista y creación parcial)
- UI de grocery lists (scaffold)
- Vista patient_radar (existe pero no integrada en dashboard)

### ⏳ Pendiente de implementar
- onboarding_state en Patient (migración + enum + flujo de invitación)
- UI de análisis async con Turbo Streams (estados queued/processing/completed)
- Registro de peso (WeightPatient UI)
- Edición inline de meals generadas
- UserSupermarketPreference UI
- PatientPrioritySnapshot persistencia
- Tests de autorización cross-tenant
- Tests de servicios

---

## Historial de Sprint Closures

| Sprint | Fecha de Cierre | Notas |
|--------|----------------|-------|
| Sprint 0 | 2026-03-09 | Canon docs, skills, subagent routing, .env.example |

---

## Próximas Prioridades

1. Resolver entorno local (Ruby/Bundler) para poder ejecutar `bin/rails` y validar migraciones
2. Completar auditoría de scoping (Sprint 1) — crítico para seguridad del piloto
3. Ejecutar migraciones pendientes de grocery domain (20251010*)
4. Integrar Patient Radar en dashboard nutritionist
5. Configurar retry en MealLogAnalysisJob y validar en staging
