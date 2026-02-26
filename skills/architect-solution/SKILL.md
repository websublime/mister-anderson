---
name: architect-solution
description: design solutions and create implementation plans. You DO NOT implement code - you create design docs and specs for supervisors.
user-invocable: true
---

# Guidelines

If the user provides $ARGUMENTS, analyze them first and ask for clarification if needed.

**CRITICAL**: It's mandatory that a product requirement be shared with you. If not ask the user about it.

```python
Task(
    subagent_type="architect",
    prompt="Create design and specs for the requested solution"
)
```
