# Delivery Tracker

| item | owner | status | evidence | blocker | next |
| --- | --- | --- | --- | --- | --- |
| Sprint 0 canon docs | agent | `done` | `AGENTS.md`, `docs/*`, `.env.example`, `CLAUDE.md` alignment | none | keep docs current as implementation moves |
| Architecture documentation enrichment | agent | `done` | `docs/ARCHITECTURE.md`, `docs/DOMAIN_MODEL.md`, `docs/AI_AGENTS.md`, `docs/DECISIONS.md`, `docs/DEPLOYMENT.md`, `docs/DATA_FLOWS.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/PROGRESS.md`, `docs/LESSONS.md` | none | update as implementation moves forward |
| Delivery tracking process | agent | `in_progress` | tracker/worklog templates and update rule documented in `AGENTS.md` | depends on continued discipline | update on every substantive turn |
| Local skills pack | agent | `done` | `.codex/skills/nutrihabits-*` | none | refine after real usage |
| Subagent routing docs | agent | `done` | `docs/subagents/*`, `docs/SUBAGENT_ROUTING.md` | none | expand if new roles appear |
| Grocery list domain scaffold | agent | `in_progress` | migrations, models, services, routes, catalogs, patient UI | full Rails boot blocked locally by Ruby/Bundler mismatch | run migrations, validate flow in app, add tests |
| Patient radar baseline | agent | `in_progress` | `PatientRadarService`, route, nutritionist view | no request-level validation yet | integrate into dashboard and add persistence if needed |
| Meal log async + preflight foundation | agent | `in_progress` | `ImagePreflightService`, `MealLogAnalysisJob`, controller flow | runtime queue/storage not validated locally | validate in staging-like environment |
| Production-safe image pipeline | agent | `planned` | not started | pending sprint 5 | add preflight/job flow |
| Patient access invitations | agent | `planned` | not started | pending sprint 3 | design onboarding state machine |
