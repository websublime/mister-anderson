---
name: review-task
description: Code review gate — lists beads with needs-review label, dispatches the code-reviewer agent to analyze the implementation branch, tracks findings, and routes rework back to the original implementation supervisor via /start-task.
user_invocable: true
---

# Review Task

Dispatch a code review for a completed implementation. This is the orchestrator's entry point for the quality gate phase.

---

## Phase 1: Resolve Bead ID

If the user provides `$ARGUMENTS`, check if it contains a bead ID (e.g., `bd-a3f`, `bd-001.2`).

**If bead ID provided:** use it directly.

**If no bead ID provided:**
1. Run `bd list --label needs-review --json` to get beads awaiting review
2. Present the list to the user showing: ID, title, priority, and labels
3. If no beads with `needs-review` label found, inform the user and stop
4. Ask the user which task to review

**Validate** the bead exists and has status `in-review`:
```bash
bd show {BEAD_ID} --json
```

---

## Phase 2: Read Bead Context

1. Parse the bead JSON. Extract: `description`, `acceptance`, `design`, `notes`, `status`, `labels`, `parent`
2. Read bead comments: `bd comments {BEAD_ID}`
3. Verify a `COMPLETED` comment exists — if not, warn user that the implementation supervisor did not leave a completion summary
4. Identify the implementation branch:
   ```bash
   git branch -a | grep {BEAD_ID}
   ```

---

## Phase 3: Dispatch Code Reviewer

Dispatch the code-reviewer agent to analyze the implementation:

Dispatch using **exactly** these parameters — no more, no less:

```python
Task(
    subagent_type="code-reviewer",
    prompt="Review BEAD {BEAD_ID} on branch {branch-name}. Read the bead (bd show {BEAD_ID}) and comments (bd comments {BEAD_ID}) for full context — description, acceptance criteria, design notes, and the COMPLETED comment from the supervisor. Analyze the branch diff against acceptance criteria and log a structured REVIEW comment to the bead."
)
```

**Do NOT add extra parameters** (e.g., `isolation`, `run_in_background`, etc.) unless the user explicitly requests it.

---

## Phase 4: Present Verdict

After the code-reviewer completes:

1. Read the REVIEW comment from bead comments: `bd comments {BEAD_ID}`
2. Extract the verdict: `APPROVE` or `NEEDS-REWORK`
3. Present the review summary to the user

**If APPROVE:**
- Inform user: "Code review passed. Ready for QA validation."
- Update labels:
  ```bash
  bd label remove {BEAD_ID} needs-review
  bd label add {BEAD_ID} approved
  ```
- Recommend: "Run `/qa-task {BEAD_ID}` to validate spec conformity, tests, build, and lint before merging."

**If NEEDS-REWORK:**
- Present findings to user (critical, warnings, and suggestions)
- Ask user: "Do you want the supervisor to continue on the current branch or create a new one? (default: current branch)"
- Update labels:
  ```bash
  bd label remove {BEAD_ID} needs-review
  bd label add {BEAD_ID} needs-rework
  ```
- Inform: "Use `/start-task {BEAD_ID}` to re-dispatch. The REVIEW comment contains all findings for the supervisor to address."
- If the user chose a new branch, note it so `/start-task` can pass the instruction to the supervisor

---

## Phase 5: Track Review Findings

After the verdict is resolved (regardless of APPROVE or NEEDS-REWORK), extract actionable findings from the REVIEW comment and create tracked issues for anything that won't be addressed in the current cycle.

### When to run

- **APPROVE:** all non-`[GOOD]` findings are deferred — create issues for all of them
- **NEEDS-REWORK:** `[CRITICAL]` and `[WARNING]` findings will be addressed via `/start-task` rework, but any `[SUGGESTION]` findings should still be tracked

### Process

1. Parse the REVIEW comment for all findings that are NOT `[GOOD]`
2. Filter out findings that will be addressed by the rework flow (i.e., `[CRITICAL]` and `[WARNING]` when verdict is NEEDS-REWORK)
3. **Resolve the target epic** — findings MUST go to the parent epic of the reviewed bead:
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
       prompt="Create beads issues for the following review findings from BEAD {BEAD_ID} review. IMPORTANT: Each issue MUST use --parent {TARGET_EPIC_ID} flag to place it inside the epic, and --deps 'discovered-from:{BEAD_ID}' to link back to the reviewed task. Do NOT use 'bd dep add' to link tasks to epics — only --parent does that. Use label 'finding:{severity}' (lowercase) for each — e.g., finding:suggestion, finding:warning, finding:critical. Include the file path and line number in the description. Findings:\n\n{FINDINGS_LIST}"
   )
   ```
   **Do NOT add extra parameters** (e.g., `isolation`, `run_in_background`, etc.) unless the user explicitly requests it.
5. Inform the user how many finding issues were created and under which epic
