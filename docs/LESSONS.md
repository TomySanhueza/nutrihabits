# Lessons Learned

Registro de errores, soluciones y patrones encontrados durante el desarrollo. Cada entrada tiene causa raíz y solución adoptada para no repetir el mismo error.

---

## Errores Recurrentes

### 2026-03-09 — JSON::ParserError en respuesta de LLM

**Contexto:** `NutritionPlanGeneratorService` y `MealLogAnalysisService`
**Error:** `JSON::ParserError` al ejecutar `JSON.parse(response)`
**Causa:** GPT-4o y otros modelos envuelven la respuesta JSON en bloques markdown:
```
```json
{ "plan": { ... } }
```
```
**Solución adoptada:**
```ruby
cleaned = response.gsub(/```json\n?/, '').gsub(/```\n?/, '').strip
JSON.parse(cleaned)
```
**Aplica a:** Todos los servicios AI del proyecto. Esta limpieza debe ser el primer paso antes de cualquier `JSON.parse` de respuesta LLM.
**ADR relacionado:** ADR-008 (JSONB para datos semi-estructurados)

---

### 2026-03-09 — Active Storage URL para LLM (Cloudinary)

**Contexto:** `MealLogAnalysisService` con GPT-4o Vision
**Error:** El LLM no puede acceder a la imagen o retorna error de URL inválida
**Causa:** Usar `rails_blob_url(photo)` genera URLs que requieren autenticación de Rails; el LLM necesita una URL pública directa de Cloudinary
**Solución adoptada:** Usar `photo.blob.url` que retorna la URL pública de Cloudinary directamente
**Nota:** En test environment con disco local, `blob.url` puede no retornar una URL accesible externamente — mockear el servicio en tests

---

### 2026-03-09 — Entorno local bloqueado (Ruby/Bundler mismatch)

**Contexto:** Setup de desarrollo
**Error:** `bin/rails` no ejecuta; Bundler/Ruby version mismatch
**Causa:** El repo requiere Ruby 3.3.5 y Bundler 2.7.1. El entorno del agente no tiene esa versión instalada
**Solución:** Usar `rbenv` o `rvm` para instalar Ruby 3.3.5; verificar con `ruby -v` antes de `bundle install`
**Impacto:** Todas las migraciones pendientes y validaciones de flujo end-to-end requieren el entorno correcto

---

## Patrones que Fallaron

### IDs crudos en Service Objects

**Contexto:** Primeras iteraciones de servicios
**Problema:** Pasar `patient_id` en lugar del objeto `patient` al servicio requiere una query adicional dentro del servicio y hace más difícil el testing (hay que crear el registro en DB)
**Patrón correcto:** Siempre pasar objetos de dominio completos:
```ruby
# MAL
NutritionPlanGeneratorService.new(patient_id: 123, ...)
# BIEN
NutritionPlanGeneratorService.new(patient.profile, start_date, end_date)
```

---

### Estado mutable en Service Objects

**Contexto:** Servicios con variables de instancia que se reutilizan
**Problema:** Si el mismo objeto servicio se llama dos veces, el estado de la primera llamada contamina la segunda
**Patrón correcto:** Servicios stateless — toda la información en `initialize`, ningún estado mutable entre llamadas. Si se necesita re-ejecutar, crear una nueva instancia.

---

## Gotchas del Stack

### Rails + Devise dual auth

- Los helpers `current_nutritionist` y `current_patient` son independientes — en un controller de nutritionist, `current_patient` retorna `nil` (no hay sesión de paciente activa)
- Los filtros `authenticate :nutritionist` y `authenticate :patient` son exclusivos — no mezclar en el mismo controller
- El sign_out de un tipo no afecta al otro: `sign_out :nutritionist` no cierra sesión del paciente

### Active Job + Sidekiq

- En development, Active Job usa `:async` adapter por defecto (jobs corren en el mismo proceso, en threads). Para simular comportamiento real, configurar `:sidekiq` también en development con Redis local.
- Si un job falla en development con `:async`, el error puede perderse silenciosamente. Revisar logs de Rails.
- Los argumentos de jobs deben ser serializables (ID de ActiveRecord, primitivos). **No pasar objetos ActiveRecord** directamente — usar el ID y recargar en el job.

### Ruby LLM (ruby_llm gem)

- La gem configura el cliente en `config/initializers/ruby_llm.rb` con `OPENAI_API_KEY`
- Para modelos con visión (GPT-4o): especificar `model: 'gpt-4o'` explícitamente en `RubyLLM.chat(model: 'gpt-4o')`
- Las respuestas pueden incluir texto explicativo antes o después del JSON — el strip de markdown resuelve el caso más común, pero puede haber texto adicional. Considerar buscar el primer `{` si el strip falla.

### PostgreSQL + JSONB

- Los campos JSONB retornan `Hash` en Ruby cuando se leen — no es necesario `JSON.parse`
- Al escribir: asignar directamente el Hash de Ruby; Rails serializa automáticamente
- Para queries en JSONB: usar `->` (retorna JSON) o `->>` (retorna texto) en SQL, o `jsonb_path_query` para rutas complejas
- Las migraciones de JSONB: `add_column :table, :field, :jsonb, default: {}` o `default: []` según el caso

### Cloudinary + Active Storage

- La URL de Cloudinary cambia con transformaciones: `photo.variant(resize_to_limit: [800, 800]).url` genera una URL diferente
- Para el LLM: usar la URL original sin transformaciones (`photo.blob.url`)
- El tiempo de disponibilidad de la URL puede tener delay tras el upload (Cloudinary procesa async). Si el LLM recibe 404, considerar un pequeño retry.

### Nested Resources y Scoping

- Al usar `resources :nutrition_plans` anidado dentro de `resources :patients`, el controller recibe `params[:patient_id]`
- Siempre hacer lookup del paciente a través del nutritionist actual:
  ```ruby
  @patient = current_nutritionist.patients.find(params[:patient_id])
  # NO: Patient.find(params[:patient_id])
  ```
- Si se omite el scoping, cualquier nutritionist puede acceder a pacientes de otro nutritionist si conoce el ID

---

## Problemas Encontrados en Code Review

### 2026-03-09 — PlansController sin autenticación
**Contexto:** `app/controllers/plans_controller.rb`
**Error:** `Plan.find(params[:id])` sin ningún `before_action :authenticate_*!`
**Causa:** Controller creado sin auth guard, posiblemente solo para debug/scaffold
**Solución requerida:** Añadir auth o eliminar el controller si no está en uso activo
**Impacto:** Cualquier request no autenticado puede leer planes de cualquier paciente

### 2026-03-09 — Lógica de negocio en NutritionPlansController#create
**Contexto:** Creación de Plans y Meals desde meal_distribution
**Error:** 20+ líneas de iteración y creación de registros en el controller, sin transaction block
**Causa:** La migración del JSON → registros se hizo directamente en el controller al implementar
**Solución requerida:** Mover a `NutritionPlanGeneratorService` envuelto en `ActiveRecord::Base.transaction`
**Riesgo:** Falla parcial deja NutritionPlan creado pero sin todas sus meals

### 2026-03-09 — schema.rb desactualizado (versión 20251006 vs migraciones hasta 20251010)
**Contexto:** Setup de entorno
**Error:** `db:schema:load` no incluye dominio de grocery ni campos operacionales de Patient/MealLog
**Causa:** Migraciones 20251010* fueron creadas pero schema.rb no fue regenerado
**Solución:** Siempre usar `bin/rails db:migrate` en este proyecto hasta hacer `db:schema:dump` con todas las migraciones aplicadas

### 2026-03-09 — meal_distribution cambió de tipo dos veces
**Contexto:** Column type de NutritionPlan#meal_distribution
**Historia:** jsonb (20251003) → text (20251004) → jsonb (20251010)
**Causa:** Cambio de estrategia de storage durante desarrollo temprano
**Solución:** La migración 20251010101000 lo restaura a jsonb. Documentar que el tipo final es jsonb.
**Impacto en documentación:** No usar `meal_distribution` como string; es jsonb en el estado final correcto

## Lecciones de Arquitectura

### Cuándo usar background job vs proceso síncrono

- **Síncrono:** latencia < 500ms, usuario espera el resultado, no hay riesgo de timeout del servidor
- **Job:** latencia > 1s, operación puede fallar y necesita retry, el usuario puede continuar sin el resultado inmediato
- **Regla para este proyecto:** toda llamada a LLM con imagen → job. Generación de plan (texto) → síncrono por ahora (< 5s en práctica), considerar job si supera 3s consistentemente en producción.

### JSONB vs columnas tipadas

- Usar columnas tipadas cuando: el dato es frecuentemente consultado/filtrado, tiene tipos específicos, o es fuente de verdad
- Usar JSONB cuando: el schema puede cambiar con el prompt, el dato es un "blob" de contexto, no se filtra por campos internos
- En este proyecto: `meal_distribution`, `ai_comparison`, `context` de chats → JSONB correcto. `calories`, `protein`, `carbs`, `fat` (números frecuentemente mostrados) → columnas tipadas correctas.
