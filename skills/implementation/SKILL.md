---
name: implementation
description: "Stage 3 orchestrator — guides Implementation for a phase: shows task progress, routes through investigate → do → review → quality per task."
user_invocable: true
---

# Implementation (Stage 3 Orchestrator)

Guide the user through Stage 3 — Implementation for a specific phase. Shows task progress and routes through the per-task pipeline.

---

<on-init>
If the user provides $ARGUMENTS, analyze them for:
- A phase number (e.g., `01`, `02`) — optional, used to filter tasks
- A bead ID (e.g., `bd-a3f`, `bd-001.2`) — jump directly to that task
- `status` — show current implementation state only
</on-init>

<on-check>
1. **Beads must exist for the phase.** Check `bd list --status=open --json` for matching epics.
2. **Spec should be APPROVED.** Check `docs/specs/{NN}-spec-*.md` if phase number provided.
</on-check>

<on-check-fail if="beads">
No beads found for this phase. Recommend running `/specification {NN}` or `/tasks` first.
</on-check-fail>

<on-state>
Show implementation progress:

```bash
bd ready
bd list --status=in_progress
bd blocked
```

Display:
```
Stage 3 — Implementation (Phase {NN})
  Progress: {completed}/{total} tasks complete
  Ready:       {list of ready task IDs with titles}
  In progress: {list of in-progress task IDs with titles}
  In review:   {list of in-review task IDs with titles}
  Blocked:     {count}
```

For each task, show its pipeline position:
- `[ ]` — not started
- `[investigate]` — investigation done, awaiting implementation
- `[do]` — implementation in progress
- `[review]` — awaiting or in code review
- `[quality]` — awaiting or in QA
- `[done]` — closed
</on-state>

<on-step name="pick">
**Pick a task** — Select the next task to work on.

If no bead ID was provided in arguments:
1. Run `bd ready` to show unblocked tasks
2. Present list with: ID, title, priority, labels, pipeline position
3. Ask: "Which task do you want to work on?"

Determine the task's current pipeline position and route to the appropriate step.
</on-step>

<on-step name="investigate">
**Investigate** — Run codebase analysis before implementation.

Check if investigation already exists for this bead (search comments for `INVESTIGATION:`).
- If exists → ask if user wants to re-investigate or skip to `/do`
- If not → dispatch: `Skill(skill="investigate", args="{BEAD_ID}")`

Wait for completion before proceeding.
</on-step>

<on-step name="do">
**Implement** — Dispatch the implementation supervisor.

Dispatch: `Skill(skill="do", args="{BEAD_ID}")`

Wait for supervisor to complete. After completion, the bead should be `in-review` with `needs-review` label.
</on-step>

<on-step name="review">
**Review** — Run code review gate.

Check if bead has `needs-review` label.
- If yes → dispatch: `Skill(skill="review", args="{BEAD_ID}")`
- If no → inform user the task is not ready for review

The `/review` skill handles auto-dispatching rework if needed.
</on-step>

<on-step name="quality">
**QA** — Run quality assurance gate.

Check if bead has `approved` label.
- If yes → dispatch: `Skill(skill="quality", args="{BEAD_ID}")`
- If no → inform user the task hasn't passed code review yet

The `/quality` skill handles auto-dispatching rework if needed.
</on-step>

<on-complete>
After QA passes:
1. Ask user if they want to close the bead
2. Re-scan implementation state
3. If more ready tasks exist, ask: "Pick the next task?"
4. If all tasks complete, show phase completion summary

```
Stage 3 — Implementation (Phase {NN}): COMPLETE
  All {total} tasks closed
  Ready for merge to main
```
</on-complete>

<on-next>
- If more tasks remain → pick next task
- If phase complete → recommend starting next phase with `/specification {NN+1}` or check overall status with `/workflow`
</on-next>
