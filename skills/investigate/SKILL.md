---
name: investigate
description: Dispatch codebase investigation for a bead task. Resolves bead context, runs the research agent, and flags spec drift before implementation.
user_invocable: true
---

# Investigate

Run codebase investigation on a bead task before implementation. Dispatches the research agent to analyze the task context, trace code paths, and flag spec drift.

---

<on-init>
If the user provides $ARGUMENTS, check if it contains a bead ID (e.g., `bd-a3f`, `bd-001.2`).

**If bead ID provided:** use it directly.

**If no bead ID provided:**
1. Run `bd ready --json` to get unblocked tasks
2. Present the list showing: ID, title, priority, and labels
3. Pick by order and priority; if unclear, ask the user
</on-init>

<on-check>
1. **Bead must exist.** Validate with `bd show {BEAD_ID} --json`.
2. **Check for existing investigation.** Read bead comments: `bd comments {BEAD_ID}`. Search for a comment containing `INVESTIGATION:`.
</on-check>

<on-check-fail if="bead">
Bead does not exist. Inform the user and stop.
</on-check-fail>

<on-check-fail if="investigation_exists">
An investigation already exists for this bead. Show the existing findings and ask:
"An investigation already exists. Do you want to (1) re-investigate, or (2) proceed to `/do` with the existing findings?"
</on-check-fail>

<on-execute>

### Step 1: Read Full Bead Context

1. Parse bead JSON. Extract: `description`, `acceptance`, `design`, `notes`, `status`, `parent`, `labels`
2. **If bead is an epic child** (BEAD_ID contains a dot, e.g., `bd-001.2`):
   - Extract EPIC_ID: the part before the first dot (e.g., `bd-001`)
   - Read the epic: `bd show {EPIC_ID} --json`
   - Extract the design doc path from the epic if available
   - Read the design doc content — this is the implementation contract
3. Store all context for the dispatch prompt

### Step 2: Dispatch Research Agent

Dispatch using **exactly** these parameters — no more, no less:

```python
Agent(
    subagent_type="research",
    prompt="Investigate BEAD {BEAD_ID}. [Include EPIC_ID if epic child]. Read the bead (bd show {BEAD_ID}) for full context — description, acceptance criteria, and design notes. Read the spec and plan referenced in the bead's external-ref or spec-id fields. If the spec has a Research Findings section, spot-check 2-3 assumptions against the current codebase. Flag any SPEC_DRIFT in your investigation comment. Log your structured findings as a bead comment using bd comments add."
)
```

**Do NOT add extra parameters** unless the user explicitly requests it.

### Step 3: Handle Spec Drift

After the research agent completes, read the investigation comment: `bd comments {BEAD_ID}`

**If SPEC_DRIFT found:**
- Present the drift to the user clearly
- Ask: "Spec drift detected. Do you want to (1) update the spec first with `/spec`, (2) proceed to `/do` anyway with known drift, or (3) skip this task?"
- If user chooses (1) → stop and recommend `/spec`
- If user chooses (2) → inform user to run `/do {BEAD_ID}` with drift noted
- If user chooses (3) → stop

**If no SPEC_DRIFT** → inform user investigation is complete.

</on-execute>

<on-complete>
1. Show the investigation summary from the bead comments
2. Report spec drift status (clean or drift detected)
</on-complete>

<on-next>
Recommend proceeding with `/do {BEAD_ID}` to dispatch the implementation supervisor.
</on-next>
