---
name: review
description: Code review gate — dispatches the code-reviewer agent to analyze an implementation branch, tracks findings, and auto-dispatches the supervisor for rework when verdict is NEEDS-REWORK.
user_invocable: true
---

# Review

Dispatch a code review for a completed implementation. Quality gate between implementation and QA.

---

<on-init>
If the user provides $ARGUMENTS, check if it contains a bead ID (e.g., `bd-a3f`, `bd-001.2`).

**If bead ID provided:** use it directly.

**If no bead ID provided:**
1. Run `bd list --label needs-review --json` to get beads awaiting review
2. Present the list showing: ID, title, priority, and labels
3. If no beads with `needs-review` label found, inform the user and stop
4. Ask the user which task to review
</on-init>

<on-check>
1. **Bead must exist and have status `in-review`.** Validate with `bd show {BEAD_ID} --json`.
2. **Implementation branch must exist.** Check with `git branch -a | grep {BEAD_ID}`.
3. **COMPLETED comment should exist.** Read `bd comments {BEAD_ID}` and search for `COMPLETED:`.
</on-check>

<on-check-fail if="bead">
Bead does not exist. Inform the user and stop.
</on-check-fail>

<on-check-fail if="completed_comment">
Warn: "The implementation supervisor did not leave a COMPLETED comment. The reviewer will have less context."
</on-check-fail>

<on-execute>

### Step 1: Read Bead Context

1. Parse bead JSON. Extract: `description`, `acceptance`, `design`, `notes`, `status`, `labels`, `parent`
2. Read bead comments: `bd comments {BEAD_ID}`
3. Identify the implementation branch

### Step 2: Dispatch Code Reviewer

Dispatch using **exactly** these parameters — no more, no less:

```python
Agent(
    subagent_type="code-reviewer",
    prompt="Review BEAD {BEAD_ID} on branch {branch-name}. Read the bead (bd show {BEAD_ID}) and comments (bd comments {BEAD_ID}) for full context — description, acceptance criteria, design notes, and the COMPLETED comment from the supervisor. Analyze the branch diff against acceptance criteria and log a structured REVIEW comment to the bead."
)
```

**Do NOT add extra parameters** unless the user explicitly requests it.

### Step 3: Present Verdict

After the code-reviewer completes:

1. Read the REVIEW comment: `bd comments {BEAD_ID}`
2. Extract verdict: `APPROVE` or `NEEDS-REWORK`
3. Present the review summary

**If APPROVE:**
- Update labels:
  ```bash
  bd label remove {BEAD_ID} needs-review
  bd label add {BEAD_ID} approved
  ```

**If NEEDS-REWORK:**
- Present findings (critical, warnings, suggestions)
- Update labels and status:
  ```bash
  bd label remove {BEAD_ID} needs-review
  bd label add {BEAD_ID} needs-rework
  bd update {BEAD_ID} --status in_progress
  ```
- Resolve branch for rework:
  - Ask: "Continue on existing branch `{branch-name}` or create a fresh branch? (default: continue)"
  - Store `{REWORK_BRANCH_INSTRUCTION}`

### Step 4: Track Review Findings

Extract actionable findings from the REVIEW comment and apply the **severity threshold policy**:

| Severity | Action |
|---|---|
| **CRITICAL** | Addressed by rework (same bead) — never tracked separately |
| **WARNING** | Individual bead — justifies its own pipeline |
| **SUGGESTION** | Batched into a single "Review cleanup" bead per epic — one bead for all suggestions |
| **GOOD** | Not tracked — acknowledgement only |

**Filtering rules:**
- **APPROVE:** track WARNINGs as individual beads, batch SUGGESTIONs into one bead
- **NEEDS-REWORK:** CRITICAL/WARNING addressed by rework; batch SUGGESTIONs into one bead
- **If no WARNINGs or SUGGESTIONs exist:** skip tracking entirely — do NOT dispatch Fernando

**Resolve the target epic** — findings go to the parent epic of the reviewed bead:
```bash
bd show {BEAD_ID} --json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0].get('parent',''))"
```
- **If `parent` is not empty:** use it as `{TARGET_EPIC_ID}`
- **ONLY if `parent` is empty:** fall back to a "Review Findings" epic

Dispatch **beads-owner** using **exactly** these parameters — no more, no less:
```python
Agent(
    subagent_type="beads-owner",
    prompt="Create beads issues for the following review findings from BEAD {BEAD_ID} review. IMPORTANT: Each issue MUST use --parent {TARGET_EPIC_ID} flag to place it inside the epic, and --deps 'discovered-from:{BEAD_ID}' to link back to the reviewed task. Do NOT use 'bd dep add' to link tasks to epics — only --parent does that. Use label 'finding:{severity}' (lowercase) for each. Include file path and line number. BATCHING RULE: Create individual beads for WARNING findings only. Batch ALL SUGGESTION findings into a single bead titled 'Review cleanup: {BEAD_ID}' with each suggestion as a checklist item in the description. Findings:\n\n{FINDINGS_LIST}"
)
```
**Do NOT add extra parameters** unless the user explicitly requests it.

### Step 5: Auto-Dispatch Supervisor (NEEDS-REWORK only)

**Skip when verdict is APPROVE.**

1. Resolve supervisor from `assignee` field (same as `/do` Step 2)
2. Confirm before dispatch:
   ```
   Ready to dispatch {resolved-supervisor} for rework of {BEAD_ID}: "{bead title}"
     Branch: {REWORK_BRANCH_INSTRUCTION summary}
     Findings to address: {N} CRITICAL + {M} WARNING

   Proceed? [y/n]
   ```
3. **If confirmed**, dispatch using **exactly** these parameters — no more, no less:
   ```python
   Agent(
       subagent_type="{resolved-supervisor}",
       prompt="Rework BEAD {BEAD_ID}. {REWORK_BRANCH_INSTRUCTION} Read the bead (bd show {BEAD_ID}) and comments (bd comments {BEAD_ID}) for full context. The latest REVIEW comment contains CRITICAL and WARNING findings that MUST be addressed — SUGGESTIONS have been tracked as separate issues. After addressing findings, log a COMPLETED comment summarizing what was fixed."
   )
   ```
   **Do NOT add extra parameters** unless the user explicitly requests it.
4. **If declined:** inform "Run `/do {BEAD_ID}` when ready." and stop.

</on-execute>

<on-complete>
1. Show verdict (APPROVE or NEEDS-REWORK)
2. Report findings tracked: {N} issues created in epic
</on-complete>

<on-complete if="verdict=APPROVE">
Inform: "Code review passed. Ready for QA validation."
</on-complete>

<on-next>
- If APPROVE → recommend `/quality {BEAD_ID}`
- If NEEDS-REWORK → supervisor already dispatched (or user deferred to `/do`)
</on-next>
