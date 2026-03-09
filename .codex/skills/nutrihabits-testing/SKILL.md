---
name: nutrihabits-testing
description: Use for request, model, service, and system test strategy in NutriHabits. Trigger when adding coverage for ownership, AI flows, uploads, patient flows, or grocery-list behavior.
---

# NutriHabits Testing

Read `docs/QA_CHECKLIST.md`, `docs/PRODUCT_SCOPE.md`, and `docs/subagents/release-qa.md`.

## Focus

- request coverage for role ownership
- service coverage for AI and grocery logic
- system coverage for nutritionist and patient critical paths

## Workflow

1. Cover ownership and regressions before edge polish.
2. Prefer deterministic tests around service contracts.
3. Add system tests only for the highest-signal flows.
4. Record what was validated in the tracker or worklog.

## References

- `references/checklist.md`
