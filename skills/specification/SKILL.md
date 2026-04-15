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
2. **Research**: `docs/research/{NN}-research-*.md` — count docs, check for CONTRADICTED findings
3. **Spec**: `docs/specs/{NN}-spec-*.md` — check for `Status: APPROVED`
4. **Coherence**: check if coherence review passed (3 clean rounds)
5. **Beads**: `bd list --status=open --json` — check for epic matching the phase

Display:
```
Stage 2 — Specification (Phase {NN})
  {check} Plan        {path} ({status})
  {check} Research    {count} doc(s) in docs/research/{NN}-*
  {check} Spec        {path} ({status})
  {check} Coherence   {clean_rounds}/3 clean rounds
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

Wait for completion. Read Smith's report and check for contradictions.

**If contradictions found:**
Present each contradiction clearly with plan-vs-reality comparison.

Ask: "These contradictions affect the plan's assumptions. How do you want to proceed?"
1. **Adjust the plan** (recommended) — route back to `/plan` for corrections, then re-research
2. **Proceed to spec with known issues** — Ada will follow research reality over the plan
3. **Cancel** — stop and review manually

**If user chooses "Adjust the plan":**
- Inform: "Routing back to plan. Ada will update the plan to align with research findings."
- Reset the plan step — dispatch `Skill(skill="plan")` again
- After plan is re-APPROVED, re-dispatch `Skill(skill="research")` to validate the corrections
- **Repeat this loop** until either:
  - Research confirms zero contradictions, OR
  - User explicitly chooses to proceed with known issues
- This plan↔research loop ensures both documents are coherent before spec creation.
</on-step>

<on-step-skip if="research_done">
Research docs already exist for phase {NN}: {count} doc(s).

**Verify coherence:** Read the research doc summary. If it lists CONTRADICTED findings, ask:
"Research found contradictions. Were these resolved in the plan? (Check plan status)"
- If resolved → proceed
- If unresolved → route back to plan↔research loop
</on-step-skip>

<on-step name="spec">
**Spec** — Detailed technical specification grounded in validated research.

Dispatch: `Skill(skill="spec")`

Wait for completion. Spec must be APPROVED before proceeding.
</on-step>

<on-step-skip if="spec_done">
Spec already exists and is APPROVED at `{path}`. Moving to next step.
</on-step-skip>

<on-step name="coherence">
**Coherence Review** — Cross-document validation before task creation. Minimum 3 review rounds.

This gate ensures plan, research, and spec are fully aligned. No tasks are created until coherence is verified.

**For each round**, dispatch Ada to review coherence:

```python
Agent(
    subagent_type="architect",
    prompt="COHERENCE REVIEW (Round {N}/3 minimum) for Phase {NN}. Read ALL three documents: Plan: {plan_path}. Research: {research_paths}. Spec: {spec_path}. Cross-check for: (1) Spec assumptions that contradict research findings, (2) Plan scope items missing from the spec, (3) Research risks not addressed in the spec design, (4) Spec design decisions that conflict with plan dependencies, (5) Acceptance criteria that reference outdated assumptions. Report format: COHERENCE REVIEW Round {N} — list each discrepancy found with document, section, and what conflicts. If no discrepancies: state COHERENT. Do NOT write files — this is a read-only review."
)
```

**After each round:**
1. Present Ada's coherence report to the user
2. **If discrepancies found:**
   - Ask user: "Fix these in the spec? Or adjust the plan/re-research?"
   - If spec fix → dispatch `Skill(skill="spec")` for Ada to correct, then re-run coherence
   - If plan fix → route back to plan↔research loop, then re-run spec + coherence
   - Reset round counter to 0 after any fix
3. **If COHERENT:**
   - Increment clean round counter
   - If < 3 clean rounds → run next round (each round may focus on different aspects)
   - If >= 3 clean rounds → coherence gate passed

**Round focus guidance (suggest to Ada):**
- Round 1: Structural coherence — scope, requirements coverage, missing sections
- Round 2: Technical coherence — API contracts, data models, dependency assumptions
- Round 3: Acceptance coherence — criteria traceability from PRD → plan → spec

Display progress:
```
Coherence Review (Phase {NN}):
  Round {N}: {COHERENT|DISCREPANCIES — count}
  Clean rounds: {count}/3 required
```
</on-step>

<on-step name="tasks">
**Tasks** — Decompose the spec into trackable epics and issues.

**Prerequisite:** Coherence review must have passed (3 clean rounds).

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
  [done] Coherence   3/3 clean rounds
  [done] Beads       {epic_id} ({total} issues)
```
</on-complete>

<on-next>
Phase {NN} specification complete. Recommend proceeding to Stage 3 with `/implementation {NN}` or `/investigate` to start working on tasks. Use `bd ready` to see available work.
</on-next>
