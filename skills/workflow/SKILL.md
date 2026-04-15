---
name: workflow
description: Meta-orchestrator — shows project state across all 3 stages, suggests next step, and routes to stage orchestrators or individual skills.
user_invocable: true
---

# Workflow

Interactive pipeline guide. Shows current project state, suggests the next step, and routes to the correct stage orchestrator or skill.

---

<on-init>
If the user provides $ARGUMENTS, parse them for:
- A stage number (e.g., `1`, `2`, `3`) → delegate to the stage orchestrator
- `next` → advance to the next pending step
- A skill name (e.g., `spec`, `research`) → jump directly to that step with prerequisite warnings
- `status` → show full state only, no action
</on-init>

<on-state>
Scan the filesystem to determine project state across all stages.

### Artifact Detection

| Artifact | Detection Pattern |
|---|---|
| Manifesto | `docs/MANIFESTO.md` |
| PRD | `docs/PRD.md` or `docs/prd/*.md` — check for `Status: APPROVED` |
| Architecture | `docs/*architecture*.md` or `docs/ARCHITECTURE.md` — check for `Status: APPROVED` |
| Plan | `docs/plans/NN-plan-*.md` — check for `Status: APPROVED` |
| Research | `docs/research/NN-research-*.md` — match NN to phase number |
| Spec | `docs/specs/NN-spec-*.md` — check for `Status: APPROVED` |
| Beads | `bd list --status=open --json 2>/dev/null` — check for epic matching the phase |

**Phase grouping:** Files sharing the same `NN` prefix belong to the same phase.

### Display Format

```
Stage 1 — Product Discovery              → /product
  {check} Manifesto     {path or "not found"}
  {check} PRD           {path} ({status})
  {check} Architecture  {path} ({status})

Stage 2 — Specification                   → /specification {NN}
  Phase {NN} ({name from plan title}):
    {check} Plan        {path} ({status})
    {check} Research    {count} doc(s) in docs/research/{NN}-*
    {check} Spec        {path} ({status})
    {check} Beads       {epic_id} ({completed}/{total} complete)

Stage 3 — Implementation                  → /implementation {NN}
  Phase {NN}:
    {progress} {completed}/{total} tasks complete
    Ready:       {list of ready task IDs}
    In progress: {list of in-progress task IDs}
    Blocked:     {count}
```

Where `{check}` is:
- `[done]` — artifact exists and is APPROVED/complete
- `[exists]` — artifact exists but not yet APPROVED
- `[missing]` — not found
- `[warning]` — missing but a later step was already done (skipped step)
</on-state>

<on-step name="next">
Determine the next pending step by finding the first incomplete step in order:

1. If no PRD → suggest `/product` or `/requirements`
2. If PRD but no Architecture → suggest `/product` or `/architecture`
3. If Architecture APPROVED but no Plan for current phase → suggest `/specification {NN}` or `/plan`
4. If Plan but no Research → suggest `/specification {NN}` or `/research`
5. If Research but no Spec → suggest `/specification {NN}` or `/spec`
6. If Spec but no Beads → suggest `/specification {NN}` or `/tasks`
7. If Beads exist → suggest `/implementation {NN}` or `/investigate` with ready tasks

When suggesting, present both the orchestrator (guided flow) and the direct skill (quick jump):
```
Next step: Research (Phase 01)
  Guided:  /specification 01  — walks through remaining steps
  Direct:  /research          — jump straight to research
```
</on-step>

<on-step name="stage_jump">
When the user provides a stage number, delegate to the corresponding orchestrator:

- `1` → `Skill(skill="product")`
- `2` → `Skill(skill="specification")` — ask for phase number if not provided
- `3` → `Skill(skill="implementation")` — ask for phase number if not provided
</on-step>

<on-step name="skill_jump">
When the user provides a specific skill name, check prerequisites before dispatching.

**Prerequisite map:**

| Skill | Requires |
|---|---|
| requirements | — |
| architecture | PRD APPROVED |
| plan | PRD APPROVED + Architecture APPROVED |
| research | Plan APPROVED |
| spec | Plan APPROVED + Research (warn if missing) |
| tasks | Spec APPROVED |
| investigate | Beads exist |
| do | Beads exist |
| review | Bead with `needs-review` label |
| quality | Bead with `approved` label |

If prerequisites are unmet, warn but do not block:

```
Warning: You are about to run /spec but the following prerequisites are missing:
  - Research: no docs found in docs/research/{NN}-*

Without validated research, the spec will be based on unvalidated assumptions
from the plan. This historically causes task drift during implementation.

Do you want to:
  1. Run /research first (recommended)
  2. Proceed to /spec anyway
  3. Cancel
```

If user confirms → dispatch: `Skill(skill="{skill-name}")`
</on-step>

<on-complete>
Show full project state and identify the next action.
</on-complete>

<on-next>
Always end by showing what comes next — either the next step or phase completion status.

Do NOT dispatch agents directly — always go through the corresponding skill or orchestrator so prerequisites are checked.
</on-next>
