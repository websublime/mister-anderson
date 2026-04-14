---
name: qa-task
description: QA finalization gate — validates spec conformity, runs tests/build/lint, produces a structured QA report, and auto-dispatches the implementation supervisor for rework (with confirmation) when the user chooses rework on a FAIL verdict. Last gate before human merge.
user_invocable: true
---

# QA Task

Dispatch QA validation for a code-review-approved implementation. This is the orchestrator's entry point for the finalization gate.

---

## Phase 1: Resolve Bead ID

If the user provides `$ARGUMENTS`, check if it contains a bead ID (e.g., `bd-a3f`, `bd-001.2`).

**If bead ID provided:** use it directly.

**If no bead ID provided:**
1. Run `bd list --label approved --json` to get beads that passed code review
2. Present the list to the user showing: ID, title, priority, and labels
3. If no beads with `approved` label found, inform the user and stop
4. Ask the user which task to QA

**Validate** the bead has the `approved` label (meaning Linus has already approved the code):
```bash
bd show {BEAD_ID} --json
```

If the bead does NOT have the `approved` label, warn the user: "This task hasn't passed code review yet. Run `/review-task {BEAD_ID}` first."

---

## Phase 2: Read Bead Context

1. Parse the bead JSON. Extract: `description`, `acceptance`, `design`, `notes`, `status`, `labels`, `parent`
2. Read bead comments: `bd comments {BEAD_ID}`
3. Verify a `REVIEW` comment exists with verdict `APPROVE` — if not, warn the user
4. Locate the spec/design doc:
   - Check bead's `design` field
   - If epic child, check parent epic: `bd show {EPIC_ID} --json`
5. If spec references a Source PRD, note the path
6. Identify the implementation branch:
   ```bash
   git branch -a | grep {BEAD_ID}
   ```

---

## Phase 3: Dispatch QA Gate

Dispatch the QA agent to validate the implementation:

Dispatch using **exactly** these parameters — no more, no less:

```python
Task(
    subagent_type="qa-gate",
    prompt="QA validate BEAD {BEAD_ID} on branch {branch-name}. Spec: {spec_path}. PRD: {prd_path}. Read the bead (bd show {BEAD_ID}) and comments (bd comments {BEAD_ID}) for full context — description, acceptance criteria, design notes, COMPLETED, DECISION, DEVIATION, and REVIEW comments. Run tests, build, and lint. Log a structured QA comment to the bead."
)
```

**Do NOT add extra parameters** (e.g., `isolation`, `run_in_background`, etc.) unless the user explicitly requests it.

---

## Phase 4: Present QA Results

After the QA agent completes:

1. Read the QA comment from bead comments: `bd comments {BEAD_ID}`
2. Extract the verdict: `PASS` or `FAIL`
3. Present the QA summary to the user

**If PASS:**
- Inform user: "QA passed. All checks green. The task is ready for merge."
- Update labels:
  ```bash
  bd label add {BEAD_ID} qa-passed
  ```
- Ask user: "Do you want to close this bead?"
  - If yes: `bd close {BEAD_ID}`
  - If no: leave open for manual merge workflow

**If FAIL:**
- Present the specific failure reasons to the user
- Ask user how to proceed:
  - **Rework**: address the gaps — auto-dispatches the implementation supervisor in the same session
  - **Follow-up**: create a new bead for the gaps and merge this as-is
  - **Override**: merge anyway — user's decision
- Update labels based on user choice:
  ```bash
  # If rework:
  bd label remove {BEAD_ID} approved
  bd label add {BEAD_ID} needs-rework
  bd update {BEAD_ID} --status in_progress

  # If follow-up or override:
  bd label add {BEAD_ID} qa-override
  ```
- **If rework:** also identify the current branch for the bead:
  ```bash
  git branch -a | grep {BEAD_ID}
  ```
  Then ask: "Continue on existing branch `{branch-name}` or create a fresh branch from a base? (default: continue current)"
  - If **continue**: store `{REWORK_BRANCH_INSTRUCTION}` = `"Continue work on existing branch {branch-name}."`
  - If **fresh**: ask "Which base branch? (default: main)", store `{REWORK_BRANCH_INSTRUCTION}` = `"Create a fresh branch from {BASE_BRANCH} — run git checkout {BASE_BRANCH} before creating the new feature branch."`
  Proceed to Phase 5 (track findings), then Phase 6 (auto-dispatch supervisor).
- **If follow-up or override:** proceed to Phase 5 only; skip Phase 6.

---

## Phase 5: Track QA Findings

After the verdict is resolved (regardless of PASS or FAIL), extract actionable findings from the QA comment and create tracked issues for anything that won't be addressed in the current cycle.

### When to run

- **PASS:** all non-positive findings (`[EXTRA]`, `[DEVIATES]`, `[RISK]`, unlogged deviations) are deferred — create issues for all of them
- **FAIL + rework:** `[BLOCKER]` and `[MAJOR]` failures will be addressed by the auto-dispatched supervisor in Phase 6, but `[MINOR]` failures, `[EXTRA]`, `[RISK]`, and unlogged deviations should still be tracked
- **FAIL + follow-up/override:** all non-positive findings should be tracked

### Process

1. Parse the QA comment for all findings that are NOT positive — i.e., anything that is not `[CONFORMS]`, `[PASS]`, or `[OK]`
2. Filter out findings that will be addressed in the current cycle (e.g., `[BLOCKER]` and `[MAJOR]` when user chose rework)
3. **Resolve the target epic** — findings MUST go to the parent epic of the validated bead:
   ```bash
   bd show {BEAD_ID} --json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0].get('parent',''))"
   ```
   - **If `parent` is not empty:** that IS the `{TARGET_EPIC_ID}`. Use it directly.
   - **ONLY if `parent` is empty** (standalone task with no epic): fall back to a "Review Findings" epic:
     - Search: `bd list --type epic --status open --json` and filter by title "Review Findings"
     - If not found, create it:
       ```bash
       bd create "Review Findings" --type epic --description "Fallback epic for findings from standalone tasks with no parent epic." --priority 3 --labels "findings"
       ```
     - Use it as `{TARGET_EPIC_ID}`

   > **CRITICAL:** Most tasks have a parent epic. Do NOT skip to the fallback. Always check `parent` first.

4. Dispatch **beads-owner** using **exactly** these parameters — no more, no less:
   ```python
   Task(
       subagent_type="beads-owner",
       prompt="Create beads issues for the following QA findings from BEAD {BEAD_ID} QA validation. IMPORTANT: Each issue MUST use --parent {TARGET_EPIC_ID} flag to place it inside the epic, and --deps 'discovered-from:{BEAD_ID}' to link back to the validated task. Do NOT use 'bd dep add' to link tasks to epics — only --parent does that. Use label 'finding:{type}' (lowercase) for each — e.g., finding:extra, finding:deviation, finding:risk, finding:minor. Include the relevant context from the QA report. Findings:\n\n{FINDINGS_LIST}"
   )
   ```
   **Do NOT add extra parameters** (e.g., `isolation`, `run_in_background`, etc.) unless the user explicitly requests it.
5. Inform the user how many finding issues were created and under which epic

---

## Phase 6: Auto-Dispatch Supervisor (FAIL + rework only)

**Skip this phase entirely when verdict is PASS, or when user chose follow-up/override on a FAIL.**

When the user chose `rework` on a FAIL, re-dispatch the implementation supervisor in the same session instead of asking them to run `/start-task`. This preserves flow and avoids re-entering the orchestration cycle from scratch.

### 6.1 Resolve Supervisor

1. Read the `assignee` field from the bead JSON (already fetched in Phase 2) — this contains the supervisor name (e.g., `rust-supervisor`).
2. **If `assignee` is set and non-empty:**
   - Verify the agent file exists: check for `.claude/agents/{assignee}.md`
   - If file exists → supervisor resolved, proceed to 6.2
   - If file NOT found → warn user the specified supervisor does not exist, fall through to manual selection
3. **If `assignee` is empty or unset, OR the file was missing:**
   - List available implementation supervisors: find all `*-supervisor.md` files in `.claude/agents/`
   - Present the list and ask: "Which supervisor should handle this rework? (or type `skip` to stop and run manually)"
   - If user types `skip` → inform "Run `/start-task {BEAD_ID}` when ready." and stop
   - Otherwise → supervisor resolved

### 6.2 Confirm Before Dispatch

Present a one-line summary and wait for explicit confirmation:

```
Ready to dispatch {resolved-supervisor} for QA rework of {BEAD_ID}: "{bead title}"
  Branch: {REWORK_BRANCH_INSTRUCTION summary}
  Failures to address: {N} BLOCKER + {M} MAJOR (MINOR/EXTRA/RISK tracked separately in epic)

Proceed? [y/n]
```

**If user answers `n` or anything other than `y`/`yes`:** inform "OK, rework paused. Run `/start-task {BEAD_ID}` when ready." and stop. Do NOT dispatch.

**If user confirms:** proceed to 6.3.

### 6.3 Dispatch Supervisor

Dispatch the resolved supervisor using **exactly** these parameters — no more, no less:

```python
Task(
    subagent_type="{resolved-supervisor}",
    prompt="QA rework for BEAD {BEAD_ID}. {REWORK_BRANCH_INSTRUCTION} Read the bead (bd show {BEAD_ID}) and comments (bd comments {BEAD_ID}) for full context. The latest QA comment contains BLOCKER and MAJOR failures that MUST be addressed in this cycle — MINOR failures, EXTRA findings, RISK notes, and unlogged deviations have been tracked as separate finding issues in the parent epic and are out of scope for this rework. After addressing failures, log a COMPLETED comment summarizing what was fixed."
)
```

**Do NOT add extra parameters** (e.g., `isolation`, `run_in_background`, etc.) unless the user explicitly requests it.

The `PreToolUse` hook automatically injects the discipline reminder because the agent name ends in `-supervisor`.
