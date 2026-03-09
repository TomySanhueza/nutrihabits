---
name: nutrihabits-debug-prod
description: Use for production or staging debugging in NutriHabits, especially uploads, Cloudinary, jobs, runtime configuration, deploy mismatches, and observability gaps.
---

# NutriHabits Debug Prod

Read `docs/DEPLOYMENT.md`, `docs/QA_CHECKLIST.md`, and `docs/subagents/prod-debugger.md`.

## Focus

- image upload failures
- Cloudinary integration
- background job failures
- environment mismatch between local, staging, and production

## Workflow

1. Reproduce through logs and config first.
2. Check env vars, storage config, and request/job boundaries.
3. Add or improve failure logging before speculative fixes.
4. Record production-impacting changes in the worklog.

## References

- `references/checklist.md`
