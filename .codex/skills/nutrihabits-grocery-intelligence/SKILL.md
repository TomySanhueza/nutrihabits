---
name: nutrihabits-grocery-intelligence
description: Use for grocery-list generation, supermarket preferences, retailer adapters, scraping-safe catalog ingestion, ingredient normalization, and product matching in NutriHabits.
---

# NutriHabits Grocery Intelligence

Read `docs/PRODUCT_SCOPE.md`, `docs/DOMAIN_MODEL.md`, and `docs/subagents/grocery-integrator.md`.

## Focus

- generate lists from plans and meals
- isolate retailer-specific logic behind adapters
- normalize ingredient names and units
- degrade gracefully when a retailer lookup fails

## Workflow

1. Model patient preference and grocery entities first.
2. Keep catalog provider logic out of controllers and views.
3. Prefer cached normalized results over direct scraping in request paths.
4. Leave a fallback list even when no product match exists.

## References

- `references/checklist.md`
