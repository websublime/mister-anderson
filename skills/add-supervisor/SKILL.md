---
name: add-supervisor
description: Create a new implementation supervisor for a specific technology. Invokes the Discovery agent in on-demand mode to fetch, filter, and inject the beads workflow into a specialist agent. Use when adding a new tech stack to the project (e.g., new package in monorepo).
user_invocable: true
---

# Add Supervisor

Create an implementation supervisor for a technology that doesn't have one yet.

---

<on-init>
If the user provides $ARGUMENTS, extract the technology name (e.g., `rust`, `react`, `python`, `go`, `flutter`).

**If technology provided:** use it directly.

**If no technology provided:**
1. List existing supervisors in `.claude/agents/` matching `*-supervisor.md`
2. Present what's already covered
3. Ask the user: "Which technology do you need a supervisor for?"
</on-init>

<on-check>
1. **Technology must be resolved.** Either from arguments or user input.
2. **Check if supervisor already exists.** Search `.claude/agents/` for files that match the technology name (e.g., `rust` → `rust-supervisor.md`, `python` → `python-backend-supervisor.md`).
</on-check>

<on-check-fail if="technology">
No technology specified. Ask the user which technology they need a supervisor for.
</on-check-fail>

<on-check-fail if="supervisor_exists">
A supervisor already exists for this technology: `{name}-supervisor.md`.

Ask: "Do you want to recreate it from scratch, or keep the existing one?"
- If keep → stop
- If recreate → proceed (Discovery will overwrite)
</on-check-fail>

<on-execute>

### Step 1: Dispatch Discovery

Dispatch the Discovery agent in **on-demand mode** to create a single supervisor:

Dispatch using **exactly** these parameters — no more, no less:

```python
Agent(
    subagent_type="discovery",
    prompt="Create a supervisor for {technology}. This is on-demand mode — do NOT scan the full codebase. Create only the {technology} supervisor by fetching the specialist from the external directory, filtering the content, injecting the beads workflow, and writing to .claude/agents/. Also update the Supervisors section in CLAUDE.md."
)
```

**Do NOT add extra parameters** (e.g., `isolation`, `run_in_background`, etc.) unless the user explicitly requests it.

</on-execute>

<on-complete>
1. Verify the new supervisor file exists in `.claude/agents/`
2. Inform user: "Created `{name}-supervisor.md`. You can now use it in beads tasks by setting `--assignee {name}-supervisor` when creating the issue."
</on-complete>

<on-next>
Supervisor created. You can now assign tasks to this supervisor with `/tasks` (set `--assignee {name}-supervisor`) or start implementing with `/do`.
</on-next>
