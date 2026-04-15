---
name: quality
description: QA finalization gate — validates spec conformity, runs tests/build/lint, produces a structured QA report. Auto-dispatches the supervisor for rework on FAIL. Last gate before human merge.
user_invocable: true
---

# Quality

Dispatch QA validation for a code-review-approved implementation. Last gate before merge.

---

<on-init>
If the user provides $ARGUMENTS, check if it contains a bead ID (e.g., `bd-a3f`, `bd-001.2`).

**If bead ID provided:** use it directly.

**If no bead ID provided:**
1. Run `bd list --label approved --json` to get beads that passed code review
2. Present the list showing: ID, title, priority, and labels
3. If no beads with `approved` label found, inform the user and stop
4. Ask the user which task to QA
</on-init>

<on-check>
1. **Bead must exist and have `approved` label.** Validate with `bd show {BEAD_ID} --json`.
2. **REVIEW comment with APPROVE verdict must exist.** Read `bd comments {BEAD_ID}`.
3. **Implementation branch must exist.** Check with `git branch -a | grep {BEAD_ID}`.
</on-check>

<on-check-fail if="bead">
Bead does not exist. Inform the user and stop.
</on-check-fail>

<on-check-fail if="approved">
This task hasn't passed code review yet. Recommend running `/review {BEAD_ID}` first.
</on-check-fail>

<on-execute>

### Step 1: Read Bead Context

1. Parse bead JSON. Extract: `description`, `acceptance`, `design`, `notes`, `status`, `labels`, `parent`
2. Read bead comments: `bd comments {BEAD_ID}`
3. Locate the spec/design doc from the bead's `design` field or parent epic
4. If spec references a Source PRD, note the path
5. Identify the implementation branch

### Step 2: Dispatch QA Gate

Dispatch using **exactly** these parameters — no more, no less:

```python
Task(
    subagent_type="qa-gate",
    prompt="QA validate BEAD {BEAD_ID} on branch {branch-name}. Spec: {spec_path}. PRD: {prd_path}. Read the bead (bd show {BEAD_ID}) and comments (bd comments {BEAD_ID}) for full context — description, acceptance criteria, design notes, COMPLETED, DECISION, DEVIATION, and REVIEW comments. Run tests, build, and lint. Log a structured QA comment to the bead."
)
```

**Do NOT add extra parameters** unless the user explicitly requests it.

### Step 3: Present QA Results

After the QA agent completes:

1. Read the QA comment: `bd comments {BEAD_ID}`
2. Extract verdict: `PASS` or `FAIL`
3. Present the QA summary

**If PASS:**
- Update labels: `bd label add {BEAD_ID} qa-passed`
- Ask: "Do you want to close this bead?"
  - If yes: `bd close {BEAD_ID}`
  - If no: leave open for manual merge workflow

**If FAIL:**
- Present specific failure reasons
- Ask how to proceed:
  - **Rework**: address gaps — auto-dispatches supervisor
  - **Follow-up**: create new bead for gaps, merge as-is
  - **Override**: merge anyway — user's decision
- Update labels:
  ```bash
  # If rework:
  bd label remove {BEAD_ID} approved
  bd label add {BEAD_ID} needs-rework
  bd update {BEAD_ID} --status in_progress

  # If follow-up or override:
  bd label add {BEAD_ID} qa-override
  ```
- If rework: resolve branch instruction (continue existing or fresh)

### Step 4: Track QA Findings

Extract actionable findings from the QA comment and create tracked issues.

- **PASS:** all non-positive findings deferred — create issues
- **FAIL + rework:** BLOCKER/MAJOR addressed by rework; track MINOR, EXTRA, RISK
- **FAIL + follow-up/override:** track all non-positive findings

**Resolve the target epic** — findings go to the parent epic:
```bash
bd show {BEAD_ID} --json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0].get('parent',''))"
```
- **If `parent` is not empty:** use it as `{TARGET_EPIC_ID}`
- **ONLY if `parent` is empty:** fall back to a "Review Findings" epic

Dispatch **beads-owner** using **exactly** these parameters — no more, no less:
```python
Task(
    subagent_type="beads-owner",
    prompt="Create beads issues for the following QA findings from BEAD {BEAD_ID} QA validation. IMPORTANT: Each issue MUST use --parent {TARGET_EPIC_ID} flag to place it inside the epic, and --deps 'discovered-from:{BEAD_ID}' to link back to the validated task. Do NOT use 'bd dep add' to link tasks to epics — only --parent does that. Use label 'finding:{type}' (lowercase) for each. Include relevant context from QA report. Findings:\n\n{FINDINGS_LIST}"
)
```
**Do NOT add extra parameters** unless the user explicitly requests it.

### Step 5: Auto-Dispatch Supervisor (FAIL + rework only)

**Skip when verdict is PASS, or user chose follow-up/override.**

1. Resolve supervisor from `assignee` field (same as `/do` Step 2)
2. Confirm before dispatch:
   ```
   Ready to dispatch {resolved-supervisor} for QA rework of {BEAD_ID}: "{bead title}"
     Branch: {REWORK_BRANCH_INSTRUCTION summary}
     Failures to address: {N} BLOCKER + {M} MAJOR

   Proceed? [y/n]
   ```
3. **If confirmed**, dispatch using **exactly** these parameters — no more, no less:
   ```python
   Task(
       subagent_type="{resolved-supervisor}",
       prompt="QA rework for BEAD {BEAD_ID}. {REWORK_BRANCH_INSTRUCTION} Read the bead (bd show {BEAD_ID}) and comments (bd comments {BEAD_ID}) for full context. The latest QA comment contains BLOCKER and MAJOR failures that MUST be addressed — MINOR, EXTRA, RISK findings have been tracked as separate issues. After addressing failures, log a COMPLETED comment summarizing what was fixed."
   )
   ```
   **Do NOT add extra parameters** unless the user explicitly requests it.
4. **If declined:** inform "Run `/do {BEAD_ID}` when ready." and stop.

</on-execute>

<on-complete>
1. Show verdict (PASS or FAIL)
2. Report findings tracked: {N} issues created in epic
</on-complete>

<on-complete if="verdict=PASS">
Inform: "QA passed. All checks green. Ready for merge."
</on-complete>

<on-next>
- If PASS → close bead and merge
- If FAIL + rework → supervisor dispatched (or user deferred to `/do`)
- If FAIL + follow-up → new bead created for gaps
</on-next>
