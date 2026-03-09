---
name: nutrihabits-rails-core
description: Use for Rails architecture, routes, auth ownership, migrations, models, jobs, and storage changes in NutriHabits. Trigger when touching multi-role flows, persistence, controllers, or domain rules.
---

# NutriHabits Rails Core

Read `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/DOMAIN_MODEL.md`, and `docs/DECISIONS.md` first.

## Focus

- preserve patient/nutritionist ownership boundaries
- keep canonical persisted values in English
- use `plans` and `meals` as operational source of truth
- keep AI or grocery snapshot payloads auditable, not authoritative

## Workflow

1. Inspect routes, models, and the nearest controller before editing.
2. Prefer scoping through authenticated associations over global `find`.
3. When changing persistence, add migrations and update domain docs.
4. When changing cross-cutting behavior, update `docs/DELIVERY_TRACKER.md` and `docs/WORKLOG.md`.

## References

- `references/checklist.md`
