# Deployment

## Target Operating Model

- Un proceso Rails web (`rails server` o Puma)
- Un proceso worker para jobs (Sidekiq o similar con Active Job)
- PostgreSQL
- Cloudinary (imágenes via Active Storage)
- SMTP provider (para invitaciones y notificaciones)
- OpenAI API (via ruby_llm gem)

## Mandatory Environment Variables

| Variable | Descripción |
|----------|-------------|
| `RAILS_MASTER_KEY` | Clave para desencriptar credentials |
| `DATABASE_URL` | Connection string de PostgreSQL |
| `OPENAI_API_KEY` | API key para ruby_llm (GPT-4o y otros modelos) |
| `REDIS_URL` | URL de Redis para Sidekiq (si se usa Sidekiq como queue adapter) |
| Cloudinary creds | Configuradas en Rails encrypted credentials (`cloud_name`, `api_key`, `api_secret`) |
| SMTP creds | Configuradas en credentials o variables de entorno |
| `RAILS_HOSTNAME` | Hostname para links en emails |

## Local Bootstrap Notes

- El repositorio fija Ruby `3.3.5` en `.ruby-version` y Bundler `2.7.1` en `Gemfile.lock`.
- En máquinas con `rbenv`, validar primero:
  - `ruby -v`
  - `which bundle`
  - `bundle -v`
- Si `bundle` apunta a `/usr/bin/bundle` o no encuentra `2.7.1`, el problema suele ser de activación de `rbenv` en la shell, no de instalación de Bundler.
- Fallback temporal recomendado:
```bash
rbenv exec bundle _2.7.1_ install
rbenv exec bundle _2.7.1_ exec rails about
```

## Local PostgreSQL Bootstrap

- Development y test deben usar TCP por defecto (`127.0.0.1`) en lugar de depender del socket Unix `/tmp/.s.PGSQL.5432`.
- `config/database.yml` ya prioriza:
  - `PGHOST` (default `127.0.0.1`)
  - `PGPORT` (default `5432`)
  - `PGUSER`
  - `PGPASSWORD`
- Si `DATABASE_URL` está presente, sigue siendo la fuente preferida y Rails la mergea por encima de `database.yml`.
- Diagnóstico mínimo recomendado:
```bash
pg_isready -h 127.0.0.1 -p 5432
bundle exec rails about
bundle exec rails db:prepare
bundle exec rails test test/controllers/plans_controller_test.rb test/controllers/nutrition_plans_controller_test.rb
```
- Si `lsof -nP -iTCP:5432 -sTCP:LISTEN` muestra PostgreSQL escuchando pero `pg_isready` falla solo dentro del sandbox, tratarlo como restricción del entorno y mover la validación a una terminal local real o CI con acceso a DB.

**Editar credentials:**
```bash
bin/rails credentials:edit
```

## Queue Adapter Configuration

El queue adapter está configurado via Active Job. Para producción se recomienda Sidekiq:

```ruby
# config/application.rb o config/environments/production.rb
config.active_job.queue_adapter = :sidekiq
```

**Queues definidas:**
| Queue | Uso |
|-------|-----|
| `:default` | Jobs generales |
| `:ai_analysis` | MealLogAnalysisJob (latencia alta, prioridad media) |
| `:catalog_refresh` | SupermarketCatalogRefreshJob (puede correr en horas valle) |

**Configuración de retry para MealLogAnalysisJob:**
```ruby
class MealLogAnalysisJob < ApplicationJob
  queue_as :ai_analysis
  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  # Después de 3 intentos: analysis_status → failed
end
```

## Active Storage Configuration

```yaml
# config/storage.yml
cloudinary:
  service: Cloudinary
  cloud_name: <%= Rails.application.credentials.dig(:cloudinary, :cloud_name) %>
  api_key: <%= Rails.application.credentials.dig(:cloudinary, :api_key) %>
  api_secret: <%= Rails.application.credentials.dig(:cloudinary, :api_secret) %>
```

- Development y production: Cloudinary
- Test: disco local (`:local` service)

## Deployment Controls

- `/up` health endpoint (Rails built-in desde 7.1)
- Smoke test después de cada deploy:
  1. `GET /up` → 200 OK
  2. Login de nutritionist de prueba
  3. Ver dashboard de paciente de prueba
- Delivery tracker actualizado con evidencia de deploy
- Worklog con entrada para cada cambio que impacte el entorno

## Proceso de Deploy (referencia)

```bash
# 1. Migrations
bin/rails db:migrate

# 2. Assets
bin/rails assets:precompile

# 3. Restart web process
# (comando específico depende de hosting: Heroku, Fly.io, etc.)

# 4. Restart worker process
# (Sidekiq restart o similar)

# 5. Smoke test
curl https://your-app.com/up
```

## Consideraciones de Seguridad

- Nunca commitear `.env` o credentials sin encriptar
- `RAILS_MASTER_KEY` solo en variables de entorno del servidor, nunca en repo
- Cloudinary: configurar restricciones de upload en dashboard de Cloudinary (tipos de archivo, tamaño máximo)
- Rate limiting en endpoints de upload de fotos (evitar abuso de API de OpenAI)
