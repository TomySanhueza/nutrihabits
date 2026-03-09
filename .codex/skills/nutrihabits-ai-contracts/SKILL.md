---
name: nutrihabits-ai-contracts
description: Use for AI prompt contracts, structured outputs, latency reduction, retry behavior, and context design in NutriHabits copilots, plan generation, and meal analysis.
---

# NutriHabits AI Contracts

Read `docs/AI_AGENTS.md`, `docs/DECISIONS.md`, and `docs/subagents/ai-reliability.md`.

## Focus

- strict JSON contracts
- graceful failures and retries
- scoped context per role
- low-latency user experience

## Workflow

1. Define expected input and output shape before editing prompts or jobs.
2. Keep long-running AI work asynchronous when possible.
3. Store enough metadata for retries and incident review.
4. Update AI docs whenever behavior or scope changes.

## References

- `references/checklist.md`
