# Subagent Routing

Use the smallest relevant role first.

## Roles

- `architect`: domain, routes, migrations, ownership, jobs
- `ux-auditor`: information hierarchy, flow friction, empty states, mobile UX
- `ai-reliability`: prompt contracts, retries, latency, structured outputs
- `grocery-integrator`: catalog adapters, normalization, product matching
- `release-qa`: checklists, acceptance scenarios, regression coverage
- `prod-debugger`: uploads, Cloudinary, jobs, deploy, operational failures

## Routing Rules

- Use `architect` when changing models, routes, or persistence shape.
- Use `ux-auditor` when a task changes visible workflows.
- Use `ai-reliability` when touching LLM services or AI chat behavior.
- Use `grocery-integrator` for supermarket adapters or shopping lists.
- Use `release-qa` when closing a sprint or validating release readiness.
- Use `prod-debugger` for any staging or production-only failure.
