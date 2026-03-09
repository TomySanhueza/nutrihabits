# Delivery Tracker

| item | owner | status | evidence | blocker | next |
| --- | --- | --- | --- | --- | --- |
| Sprint 0 canon docs | agent | `done` | `AGENTS.md`, `docs/*`, `.env.example`, `CLAUDE.md` alignment | none | keep docs current as implementation moves |
| Architecture documentation enrichment | agent | `done` | `docs/ARCHITECTURE.md`, `docs/DOMAIN_MODEL.md`, `docs/AI_AGENTS.md`, `docs/DECISIONS.md`, `docs/DEPLOYMENT.md`, `docs/DATA_FLOWS.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/PROGRESS.md`, `docs/LESSONS.md` | none | update as implementation moves forward |
| Delivery tracking process | agent | `in_progress` | tracker/worklog templates and update rule documented in `AGENTS.md` | depends on continued discipline | update on every substantive turn |
| Local skills pack | agent | `done` | `.codex/skills/nutrihabits-*` | none | refine after real usage |
| Subagent routing docs | agent | `done` | `docs/subagents/*`, `docs/SUBAGENT_ROUTING.md` | none | expand if new roles appear |
| Grocery list domain scaffold | agent | `in_progress` | migrations, models, services, routes, catalogs, patient UI; `schema.rb` aligned to `20251010101000` | flow and service-level tests still pending | validate grocery flow in app and add tests |
| Patient radar baseline | agent | `in_progress` | `PatientRadarService`, route, nutritionist view | no request-level validation yet | integrate into dashboard and add persistence if needed |
| Meal log async + preflight foundation | agent | `in_progress` | `ImagePreflightService`, `MealLogAnalysisJob`, controller flow | runtime queue/storage not validated locally | validate in staging-like environment |
| Sprint 1 task 01 - legacy plans endpoint removal | agent | `done` | removed `PlansController` and `app/views/plans/show.html.erb`; deleted stale `/plans/:id` route comment; added route regression and nutrition-plan ownership tests; focused suite passing with PostgreSQL access (`24 runs, 73 assertions, 0 failures`) | none | continue Sprint 1 controller scoping audit on patient-side controllers |
| Sprint 1 task 02 nutritionist controller scoping | agent | `done` | nested controller scoping hardened, patient-history nutrition_plan ownership validation added, integration fixtures/tests expanded, `db/schema.rb` realigned to `20251010101000`, test DB rebuilt, focused controller suite + `plans_controller_test` passing (`24 runs, 73 assertions, 0 failures`) | none | continue Sprint 1 audit on patient-side controllers |
| Ruby/Bundler environment activation fix | agent | `done` | `.zprofile` now initializes `rbenv` for login shells; `ruby -v` => 3.3.5; `which bundle` => `~/.rbenv/shims/bundle`; `bundle -v` => 2.7.1; `bundle exec rails about` succeeds | none | use this environment to separate app issues from sandbox/DB issues |
| PostgreSQL connectivity hardening | agent | `done` | confirmed Postgres listens on `127.0.0.1:5432`; `config/database.yml` and `.env.example` switched to TCP defaults; `bundle exec rails db:prepare` completed; focused Rails controller suite passing in DB-capable environment | default sandbox still cannot reach local PostgreSQL without elevation | reuse elevated/local/CI environment for future DB-backed validation |
| Production-safe image pipeline | agent | `planned` | not started | pending sprint 5 | add preflight/job flow |
| Patient access invitations | agent | `planned` | not started | pending sprint 3 | design onboarding state machine |
