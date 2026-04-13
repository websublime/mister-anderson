---
name: beads-product-owner
description: Decompose a PRD or product plan into structured epics and issues. Requires an existing product requirements document. For ad-hoc single issues, use /create-bead-issues instead.
user_invocable: true
---

# Guidelines

If the user provides $ARGUMENTS, analyze them first and ask for clarification if needed.

**CRITICAL**:
- It's mandatory that a product requirement be shared with you. If not ask the user about it.
- Ask the user if they already have a plan for the solution. If yes, ask where to find it.
- User can share the full product plan or a feature plan.

## Before Dispatching

1. **Locate the product requirements** — ask user for the path (e.g., `docs/prd/PRD-feature.md`)
2. **Locate the plan (if any)** — ask user for the path (e.g., `docs/spec/SPEC-feature.md`)
3. Read both documents to confirm they exist

## Dispatch

Dispatch using **exactly** these parameters — no more, no less:

```python
Task(
    subagent_type="beads-owner",
    prompt="Create epics and issues for the requested solution. Product requirements: {prd_path}. Plan/spec: {plan_path_or_none}. Read both documents for full context before creating issues."
)
```

**Do NOT add extra parameters** (e.g., `isolation`, `run_in_background`, etc.) unless the user explicitly requests it.
