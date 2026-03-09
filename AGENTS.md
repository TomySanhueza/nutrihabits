# NutriHabits Agents Guide

This file is the local source of truth for Codex/Claude working inside this repository.

## Canonical Documents

Read these first when the task is broader than a single bug fix:

- `docs/ROADMAP.md`
- `docs/DELIVERY_TRACKER.md`
- `docs/WORKLOG.md`
- `docs/DECISIONS.md`
- `docs/PRODUCT_SCOPE.md`
- `docs/ARCHITECTURE.md`
- `docs/DOMAIN_MODEL.md`
- `docs/AI_AGENTS.md`
- `docs/DEPLOYMENT.md`
- `docs/QA_CHECKLIST.md`
- `docs/SUBAGENT_ROUTING.md`

`CLAUDE.md` should remain aligned with these docs. If they diverge, update both in the same change.

## Mandatory Working Rules

1. Any substantial implementation must update:
   - `docs/DELIVERY_TRACKER.md`
   - `docs/WORKLOG.md`
2. Any architectural or product decision that changes scope or direction must update:
   - `docs/DECISIONS.md`
3. New AI flows must be documented in:
   - `docs/AI_AGENTS.md`
4. New operational or deployment assumptions must update:
   - `docs/DEPLOYMENT.md`

## Delivery Status Vocabulary

Use only these status values in trackers:

- `planned`
- `in_progress`
- `blocked`
- `review`
- `done`

## Product Priorities

Current release target is a closed pilot with:

- nutritionist backoffice
- robust patient app
- human chat
- nutrition plan generation with AI
- meal photo analysis with AI
- patient risk radar
- meal swap coach
- AI food purchase list

## Technical Priorities

- Protect data ownership across nutritionists and patients.
- Prefer canonical domain values in English and translate in the UI.
- Keep `plans` and `meals` as the source of truth for operational flows.
- Treat `nutrition_plans.meal_distribution` as an auditable AI snapshot.
- Keep AI work asynchronous where latency or external failures matter.
- Degrade gracefully when image uploads, catalogs, or LLMs fail.

## Local Skills

Repository-local skills live under `.codex/skills/`.
Subagent role docs live under `docs/subagents/`.

When a task matches one of those skills, load the smallest relevant skill set first.
