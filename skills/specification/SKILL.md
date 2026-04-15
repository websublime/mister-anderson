---
name: specification
description: "Stage 2 orchestrator — guides Specification for a phase: plan → research → spec → tasks. Requires a phase number. Scans phase artifacts, skips completed steps, dispatches sub-skills in sequence."
user_invocable: true
---

# Specification (Stage 2 Orchestrator)

Guide the user through Stage 2 — Specification for a specific phase. Sequences the atomic skills and tracks progress.

---

<on-init>
If the user provides $ARGUMENTS, analyze them for:
- A phase number (e.g., `01`, `02`) — required
- `status` — show current phase state only
- A specific step name to jump to (e.g., `spec`)

**If no phase number provided:** ask the user which phase to work on. List existing phases by scanning `docs/plans/NN-plan-*.md`.
</on-init>

<on-check>
1. **Stage 1 must be complete.** Verify PRD and Architecture exist and are APPROVED.
2. **Phase number must be provided.**
</on-check>

<on-check-fail if="stage1">
Stage 1 is incomplete. Recommend running `/product` first:
- PRD: {status}
- Architecture: {status}
</on-check-fail>

<on-state>
Scan the filesystem for phase `{NN}` artifacts:

1. **Plan**: `docs/plans/{NN}-plan-*.md` — check for `Status: APPROVED`
2. **Research**: `docs/research/{NN}-research-*.md` — count docs
3. **Spec**: `docs/specs/{NN}-spec-*.md` — check for `Status: APPROVED`
4. **Beads**: `bd list --status=open --json` — check for epic matching the phase

Display:
```
Stage 2 — Specification (Phase {NN})
  {check} Plan        {path} ({status})
  {check} Research    {count} doc(s) in docs/research/{NN}-*
  {check} Spec        {path} ({status})
  {check} Beads       {epic_id} ({completed}/{total} complete)
```
</on-state>

<on-step name="plan">
**Plan** — Phase scope, task breakdown, dependencies, acceptance criteria.

Dispatch: `Skill(skill="plan")`

Wait for completion. Plan must be APPROVED before proceeding.
</on-step>

<on-step-skip if="plan_done">
Plan already exists and is APPROVED at `{path}`. Moving to next step.
</on-step-skip>

<on-step name="research">
**Research** — Validate technical assumptions from the plan against real APIs, libraries, and codebase.

Dispatch: `Skill(skill="research")`

Wait for completion. If contradictions found, present them and ask:
"Do you want to adjust the plan first, or proceed to spec with known issues?"
</on-step>

<on-step-skip if="research_done">
Research docs already exist for phase {NN}: {count} doc(s). Moving to next step.
</on-step-skip>

<on-step name="spec">
**Spec** — Detailed technical specification grounded in validated research.

Dispatch: `Skill(skill="spec")`

Wait for completion. Spec must be APPROVED before proceeding.
</on-step>

<on-step-skip if="spec_done">
Spec already exists and is APPROVED at `{path}`. Moving to next step.
</on-step-skip>

<on-step name="tasks">
**Tasks** — Decompose the spec into trackable epics and issues.

Dispatch: `Skill(skill="tasks")`

Wait for completion.
</on-step>

<on-step-skip if="tasks_done">
Beads already exist for this phase: {epic_id} with {total} issues. Moving to next step.
</on-step-skip>

<on-complete>
Re-scan and display final phase state.

```
Stage 2 — Specification (Phase {NN}): COMPLETE
  [done] Plan        {path} (APPROVED)
  [done] Research    {count} doc(s)
  [done] Spec        {path} (APPROVED)
  [done] Beads       {epic_id} ({total} issues)
```
</on-complete>

<on-next>
Phase {NN} specification complete. Recommend proceeding to Stage 3 with `/implementation {NN}` or `/investigate` to start working on tasks. Use `bd ready` to see available work.
</on-next>
