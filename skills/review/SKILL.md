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
1. Extract `[cosmetic]` SUGGESTIONs from the REVIEW comment
2. If `[cosmetic]` items exist, auto-apply before proceeding:
   - Resolve supervisor from bead `assignee` field (same as `/do` Step 2)
   - If no supervisor can be resolved, skip auto-apply and treat `[cosmetic]` items as `[semantic]` for tracking in Step 4
   - Dispatch:
     ```python
     Agent(
         subagent_type="{resolved-supervisor}",
         prompt="Apply cosmetic review fixes on BEAD {BEAD_ID}, branch {branch-name}. These are trivial, non-behavioral changes from the code review. Apply each fix, run build and tests to confirm nothing breaks, then commit as 'chore: review-cleanup {BEAD_ID}'. If any fix unexpectedly breaks build or tests, skip it and list skipped items in your report.\n\nCosmetic fixes to apply:\n{COSMETIC_LIST}"
     )
     ```
     **Do NOT add extra parameters** unless the user explicitly requests it.
   - If any items were skipped by the supervisor (reported as failures), promote them to `[semantic]` for tracking in Step 4
3. Update labels:
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
| **WARNING[must-fix]** | Individual bead — direct impact on correctness, security, or reliability |
| **WARNING[should-fix]** | Batched into a single "Review warnings: {BEAD_ID}" bead per epic |
| **SUGGESTION[semantic]** | Batched into a single "Review cleanup" bead per epic — one bead for all semantic suggestions |
| **SUGGESTION[cosmetic]** | Auto-applied in Step 3 (APPROVE) or bundled into rework (NEEDS-REWORK) — not tracked |
| **GOOD** | Not tracked — acknowledgement only |

**Filtering rules:**
- **APPROVE:** track `[must-fix]` WARNINGs as individual beads, batch `[should-fix]` WARNINGs into one bead, batch `[semantic]` SUGGESTIONs into one bead. `[cosmetic]` items already auto-applied in Step 3.
- **NEEDS-REWORK:** CRITICAL and `[must-fix]` WARNINGs addressed by rework. Batch `[should-fix]` WARNINGs and `[semantic]` SUGGESTIONs. `[cosmetic]` items bundled into rework prompt in Step 5.
- **If no `[must-fix]` WARNINGs, `[should-fix]` WARNINGs, or `[semantic]` SUGGESTIONs exist:** skip tracking entirely — do NOT dispatch Fernando
- **Findings beads** (bead has any `finding:*` label): the review verdict (APPROVE / NEEDS-REWORK) and rework cycle operate normally — CRITICALs and `[must-fix]` WARNINGs are still fixed via rework on the same bead. However, Step 4 tracking is skipped: `[should-fix]` WARNINGs and `[semantic]` SUGGESTIONs found during review of a findings bead are reported in the REVIEW comment for transparency but do NOT generate new beads. This breaks the recursive cycle where findings create findings indefinitely.

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
    prompt="Create beads issues for the following review findings from BEAD {BEAD_ID} review. IMPORTANT: Each issue MUST use --parent {TARGET_EPIC_ID} flag to place it inside the epic, and --deps 'discovered-from:{BEAD_ID}' to link back to the reviewed task. Do NOT use 'bd dep add' to link tasks to epics — only --parent does that. Use label 'finding:{severity}' (lowercase) for each. Include file path and line number. BATCHING RULE: Create individual beads for [must-fix] WARNING findings only. Batch [should-fix] WARNING findings into a single bead titled 'Review warnings: {BEAD_ID}' with each item as a checklist in the description. Batch ALL [semantic] SUGGESTION findings into a single bead titled 'Review cleanup: {BEAD_ID}' with each suggestion as a checklist item in the description. Note: [cosmetic] suggestions have already been applied automatically and are NOT included. Findings:\n\n{FINDINGS_LIST}"
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
     Findings to address: {N} CRITICAL + {M} [must-fix] WARNING

   Proceed? [y/n]
   ```
3. **If confirmed**, dispatch using **exactly** these parameters — no more, no less:
   ```python
   Agent(
       subagent_type="{resolved-supervisor}",
       prompt="Rework BEAD {BEAD_ID}. {REWORK_BRANCH_INSTRUCTION} Read the bead (bd show {BEAD_ID}) and comments (bd comments {BEAD_ID}) for full context. The latest REVIEW comment contains CRITICAL and [must-fix] WARNING findings that MUST be addressed. [should-fix] WARNINGs and [semantic] SUGGESTIONs have been tracked as separate issues. Also apply any [cosmetic] suggestions from the REVIEW — they are trivial, non-behavioral fixes that do not need separate tracking. After addressing all findings, log a COMPLETED comment summarizing what was fixed."
   )
   ```
   **Do NOT add extra parameters** unless the user explicitly requests it.
4. **If declined:** inform "Run `/do {BEAD_ID}` when ready." and stop.

</on-execute>

<on-complete>
Present the result following the **Presenting to the User** guidelines:

1. **Headline**: verdict in plain language — "Code review passed — ready for QA" or "Code review found {N} issues that need attention"
2. **What was found**:
   - If APPROVE: brief summary of what was checked and confirmed. Mention any `[cosmetic]` items that were auto-applied.
   - If NEEDS-REWORK: for each CRITICAL/WARNING, explain in natural language what the issue is, why it matters, and what needs to change. Use a ASCII diagram if findings involve multi-component interactions.
3. **Findings tracked**: if Fernando created beads, list them with plain-language descriptions, not raw finding text
4. **Repercussions**: what could break if NEEDS-REWORK findings aren't addressed
5. **Next step**: recommend `/quality {BEAD_ID}` (APPROVE) or confirm rework dispatch (NEEDS-REWORK)
6. **Technical details**: raw REVIEW comment, spec references, and file:line locations in a `<details>` block
</on-complete>

<on-complete if="verdict=APPROVE">
Inform: "Code review passed. Ready for QA validation."
</on-complete>

<on-next>
- If APPROVE → recommend `/quality {BEAD_ID}`
- If NEEDS-REWORK → supervisor already dispatched (or user deferred to `/do`)
</on-next>
