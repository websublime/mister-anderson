---
name: create-beads-issue
description: Create individual issues from user input or ad-hoc requests. For decomposing a full PRD into epics, use /beads-product-owner instead.
user_invocable: true
---

# Creation Guidelines

If the user provides $ARGUMENTS, analyze them first and ask for clarification if needed.

**CRITICAL**: Either the user provides the issue to create in the prompt, or you must ask the user where to find the documents that will be used to create the issues.

## Before Dispatching

1. **Gather issue context:**
   - What issue(s) to create? Get from user input or documents.
   - Which epic should they belong to? Ask user for parent epic ID if applicable.
   - Is this a monorepo? If yes, which package does the issue belong to?

2. **Locate references:**
   - Ask user for any relevant documents (PRD, spec, plan)
   - Note file paths for the dispatch prompt

## Dispatch

Dispatch using **exactly** these parameters — no more, no less:

```python
Task(
    subagent_type="beads-owner",
    prompt="Create issues based on the following context. Issue description: {user_input_or_summary}. Reference documents: {doc_paths_if_any}. Parent epic: {epic_id_or_none}. Project type: {monorepo with package X | single-repo}."
)
```

**Do NOT add extra parameters** (e.g., `isolation`, `run_in_background`, etc.) unless the user explicitly requests it.
