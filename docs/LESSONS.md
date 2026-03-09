# Lessons Learned

Registro de errores, soluciones y patrones encontrados durante el desarrollo. Cada entrada tiene causa raíz y solución adoptada para no repetir el mismo error.

---

## Errores Recurrentes

### 2026-03-09 — Devise integration tests tras una `404` pueden perder sesión efectiva

**Contexto:** request specs de ownership para controllers de nutritionist y patient bajo rutas declaradas con `authenticate`
**Error:** una segunda request protegida dentro del mismo test podía responder `302` a la pantalla de sign-in aunque la primera request del ejemplo ya hubiese estado autenticada y hubiese devuelto `404`
**Causa:** en esta configuración de integración, encadenar múltiples requests fallidas bajo el bloque `authenticate` no siempre preserva el estado efectivo de Warden/Devise entre requests del mismo ejemplo
**Solución adoptada:** en pruebas de acceso rechazado, usar una sola request protegida por ejemplo o volver a ejecutar `sign_in` antes de la siguiente request protegida
**Lección:** cuando se validan `404` de ownership con Devise integration helpers, no asumir que una sola autenticación al inicio del test alcanza para múltiples requests rechazadas encadenadas

---

### 2026-03-09 — Warnings de Rack 3 por `:unprocessable_entity`

**Contexto:** suites request-level de Sprint 1 en controllers nutritionist y patient
**Error:** Rails/Rack 3 emiten warnings deprecando `:unprocessable_entity` en favor de `:unprocessable_content`
**Causa:** varios controllers legacy siguen renderizando con `status: :unprocessable_entity`
**Solución adoptada:** migrar todos los renders y assertions afectados a `:unprocessable_content`, corregir también `config.responder.error_status` de Devise y añadir tests de auth inválida para ambos scopes antes de cerrar la pasada
**Lección:** cuando Rack 3 marca un status como deprecado, no alcanza con cambiar controllers; hay que revisar configuraciones globales del stack y cubrir explícitamente los flujos framework-managed

---

### 2026-03-09 — `pg` puede fallar al paralelizar suites grandes en este runner

**Contexto:** validación conjunta de controllers Rails con PostgreSQL real
**Error:** al correr una suite de 55 tests, Rails entró en paralelización y el adapter `pg` terminó en segfault durante la apertura de workers
**Causa:** combinación inestable del runner actual con `pg`/PostgreSQL bajo ejecución paralela; no se manifestó en corridas seriales o por lotes más pequeños
**Solución adoptada:** cambiar `test/test_helper.rb` para que la suite corra serial por defecto y habilite paralelización solo con `PARALLELIZE_TESTS=1`; tras ese cambio, la corrida conjunta de 55 tests validó correctamente en una sola invocación
**Lección:** en este repo, la paralelización de tests debe ser opt-in y solo usarse cuando el runner y PostgreSQL hayan sido revalidados explícitamente

---

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
**Causa:** El repo requiere Ruby 3.3.5 y Bundler 2.7.1, pero la shell estaba resolviendo `ruby` a `2.6.10` del sistema y `bundle` a `/usr/bin/bundle`. `rbenv` sí tenía Ruby 3.3.5 y Bundler 2.7.1 instalados, pero no era el binario activo por defecto.
**Solución:** Corregir la activación global de `rbenv` en shells login para que los shims tengan prioridad efectiva; validar con `ruby -v`, `which bundle`, `rbenv which bundle`. Mientras el fix global no esté verificado, usar `rbenv exec bundle _2.7.1_ ...` como fallback explícito.
**Impacto:** Todas las migraciones pendientes y validaciones de flujo end-to-end requieren el entorno correcto
**Lección:** Antes de instalar gemas o tocar `Gemfile.lock`, confirmar qué Ruby y qué `bundle` está usando realmente la shell.

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
- En integration tests, una request protegida que termina en `404` bajo rutas declaradas con `authenticate` puede requerir `sign_in` nuevamente antes de la siguiente request del mismo ejemplo

### Shell / Tooling con rbenv

- Si `bundle` resuelve a `/usr/bin/bundle`, la shell está usando el Bundler del sistema aunque `rbenv` tenga la versión correcta instalada.
- `eval "$(rbenv init - zsh)"` en `.zshrc` no alcanza para shells login no interactivas; en ese caso debe estar también en `.zprofile` o el archivo de arranque equivalente.
- Verificación mínima antes de asumir que “falta Bundler”:
  - `ruby -v`
  - `which ruby`
  - `which bundle`
  - `rbenv versions`
  - `rbenv exec bundle _2.7.1_ -v`
- Si `rbenv exec bundle _2.7.1_ -v` funciona pero `bundle -v` falla, el problema es de activación/PATH, no de instalación.

### PostgreSQL connectivity por capas

- Si `config/database.yml` omite `host`, Rails/pg suele preferir socket Unix local.
- En sandboxes, contenedores o entornos con permisos recortados, ese socket puede fallar incluso cuando PostgreSQL está corriendo correctamente.
- Recomendación operativa del proyecto:
  - usar `host: 127.0.0.1` por defecto en development/test
  - preferir `DATABASE_URL` explícito cuando exista
- Diagnóstico por capas antes de culpar al código:
  1. `ruby -v` y `bundle -v`
  2. `bundle exec rails about`
  3. `pg_isready -h 127.0.0.1 -p 5432` y `lsof -nP -iTCP:5432 -sTCP:LISTEN`
  4. `bundle exec rails db:prepare` y luego tests/migraciones

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

### 2026-03-09 — PlansController legacy eliminado en lugar de endurecido
**Contexto:** Cierre de Sprint 1 Task 01
**Error:** Existía una superficie legacy insegura aunque la ruta activa ya no estaba publicada
**Causa raíz:** Controller scaffold/debug no consolidado, mantenido en el repo pese a no formar parte del producto soportado
**Solución adoptada:** Eliminar `PlansController`, eliminar `app/views/plans/show.html.erb`, quitar la referencia comentada en rutas y consolidar el acceso soportado en `NutritionPlansController`
**Lección:** Si un endpoint no pertenece al producto soportado, no se endurece “por si acaso”; se elimina para reducir superficie de ataque.

### 2026-03-09 — Validación automática parcial bloqueada por entorno
**Contexto:** Validación de la corrección de seguridad de Sprint 1
**Error:** Los tests focalizados no pudieron ejecutarse inicialmente con `bundle exec rails test ...`
**Causa:** Toolchain activa incorrecta en la shell, no un fallo funcional del cambio implementado
**Solución adoptada:** Separar evidencia de validación estática de validación runtime y registrar explícitamente el bloqueo del entorno hasta corregir `rbenv`/Bundler
**Lección:** Marcar siempre cuándo una validación queda bloqueada por entorno, para no confundir “no ejecutado” con “falló”.

### 2026-03-09 — PostgreSQL local bloqueado por sandbox tras corregir Bundler
**Contexto:** Reintento de `bundle exec rails test test/controllers/plans_controller_test.rb test/controllers/nutrition_plans_controller_test.rb`
**Error:** `connection to server on socket "/tmp/.s.PGSQL.5432" failed: Operation not permitted`
**Causa:** El toolchain Ruby/Bundler ya estaba correcto. PostgreSQL sí estaba escuchando en `127.0.0.1:5432`, pero el repo seguía favoreciendo socket Unix al no definir `host`, y además este sandbox no puede abrir conectividad local ni por socket Unix ni por TCP loopback.
**Solución adoptada:** Estandarizar TCP en `config/database.yml` y `.env.example`, documentar `DATABASE_URL`/`PGHOST` como camino recomendado y dejar explícito que la validación final de DB debe hacerse en una terminal local real o CI con acceso a PostgreSQL.
**Lección:** No asumir que “PostgreSQL no responde” implica que el servidor está caído; primero distinguir entre socket Unix, TCP y restricciones del entorno de ejecución.

### 2026-03-09 — Validación final de PostgreSQL confirmada fuera del sandbox
**Contexto:** Ejecución con permisos elevados tras corregir Ruby/Bundler, `database.yml` y `schema.rb`
**Resultado:** `bundle exec rails db:prepare` completó correctamente y la suite focalizada de controllers pasó con `24 runs, 73 assertions, 0 failures, 0 errors`
**Causa raíz resuelta:** El repo ya no depende implícitamente del socket Unix y el entorno validado tuvo acceso real a PostgreSQL
**Solución adoptada:** Mantener TCP (`127.0.0.1`) como default en development/test, conservar el diagnóstico por capas y tratar el sandbox sin permisos como limitación operativa, no como bug del repo
**Lección:** Una vez corregida la configuración del repo, la validación definitiva de DB debe ejecutarse en un entorno con acceso real a PostgreSQL para separar problemas de aplicación de restricciones del runner.

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

### 2026-03-09 — rails test bloqueado por PostgreSQL inaccesible en sandbox y schema desactualizado
**Contexto:** validación focalizada de controllers de Sprint 1
**Error:** Intenté ejecutar `bundle exec rails test ...`, pero falló antes de correr la suite por bloqueo de conexión a PostgreSQL en `/tmp/.s.PGSQL.5432` dentro del sandbox.
**Causa:** El entorno inicial no podía abrir el socket local de PostgreSQL, y además el proyecto dependía de migraciones 20251010 que no estaban reflejadas en `db/schema.rb`. Durante la reparación apareció un segundo problema: la migración `20251010101000` asumía JSON válido en `nutrition_plans.meal_distribution`, pero había filas persistidas con formato hash de Ruby (`=>`).
**Solución requerida:** correr la suite en un entorno con PostgreSQL accesible, ejecutar `bin/rails db:migrate`, normalizar previamente `meal_distribution` a JSON válido, regenerar `db/schema.rb` y recién después repetir la suite focalizada.
**Pendiente operativo:** si el entorno de test usa `db/schema.rb`, puede requerir recrear la base de test desde el schema actualizado antes de correr `rails test`.
**Lección:** no considerar “tests no ejecutados” como bloqueo ambiguo; registrar siempre si el problema es conectividad de DB, schema stale, datos legacy incompatibles con la migración o una combinación de los tres.

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
