---
name: tasks
description: Create beads from a spec (full decomposition) or from user input (ad-hoc issues). Single entry point for all bead creation.
user_invocable: true
---

# Tasks

Create epics and issues — either by decomposing a spec or from ad-hoc user input.

---

<on-init>
If the user provides $ARGUMENTS, analyze them for:
- A spec path (full decomposition mode)
- A PRD path
- An issue description or list (ad-hoc mode)
- A parent epic ID

Determine the mode:
- **Full decomposition** — user references a spec or PRD to decompose
- **Ad-hoc** — user describes individual issues to create
</on-init>

<on-check>
**Full decomposition mode:**
1. **Spec must exist and be APPROVED.** Ask the user for the spec path. Read to confirm.
2. **PRD must exist.** Ask the user for the PRD path. Read to confirm.

**Ad-hoc mode:**
1. **Issue context must be provided.** Either from user input or referenced documents.
2. **Parent epic (optional).** Ask if issues should belong to an existing epic.
</on-check>

<on-check-fail if="spec">
No spec found. Recommend running `/spec` first, or switch to ad-hoc mode for individual issues.
</on-check-fail>

<on-check-fail if="prd">
No PRD found. Recommend running `/requirements` first.
</on-check-fail>

<on-execute>

### Full Decomposition Mode

Dispatch using **exactly** these parameters — no more, no less:

```python
Agent(
    subagent_type="beads-owner",
    prompt="Create epics and issues for the requested solution. Product requirements: {prd_path}. Spec: {spec_path}. Read both documents for full context before creating issues. CRITICAL — Reference-only beads: set --spec-id to the PRD document reference. Set --external-ref to the spec path with section references. Set --design to a one-line pointer (e.g., 'See {spec_path} § {section}'). Acceptance criteria must be verifiable pass/fail conditions only — no implementation details. NEVER copy spec content into description or design fields. Beads track work; specs define work."
)
```

**Do NOT add extra parameters** unless the user explicitly requests it.

### Ad-hoc Mode

Gather context:
1. What issue(s) to create? From user input or documents.
2. Which epic should they belong to? Ask for parent epic ID if applicable.
3. Any reference documents (PRD, spec, plan)?

Dispatch using **exactly** these parameters — no more, no less:

```python
Agent(
    subagent_type="beads-owner",
    prompt="Create issues based on the following context. Issue description: {user_input_or_summary}. Reference documents: {doc_paths_if_any}. Parent epic: {epic_id_or_none}. Project type: {monorepo with package X | single-repo}."
)
```

**Do NOT add extra parameters** unless the user explicitly requests it.

</on-execute>

<on-complete>
1. Verify epics and issues were created
2. Show the user a summary: number of epics, total issues, dependency graph
</on-complete>

<on-next>
Recommend proceeding with `/investigate` to begin implementation. Use `bd ready` to see available work.
</on-next>
