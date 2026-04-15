---
name: do
description: Dispatch the implementation supervisor for a bead task. Resolves the correct supervisor from the assignee field, checks branch state, and dispatches with full context.
user_invocable: true
---

# Do

Dispatch the implementation supervisor for a bead task. Handles supervisor resolution, branch management, and dispatch with full investigation context.

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
2. **Investigation should exist.** Read bead comments: `bd comments {BEAD_ID}`. Search for `INVESTIGATION:`.
</on-check>

<on-check-fail if="bead">
Bead does not exist. Inform the user and stop.
</on-check-fail>

<on-check-fail if="investigation">
No investigation found for this bead. Warn:
"No investigation found. The supervisor will implement without codebase analysis. This can lead to missed edge cases."

Ask: "Do you want to run `/investigate {BEAD_ID}` first, or proceed without investigation?"
- If user wants investigation → stop and recommend `/investigate`
- If user proceeds → continue to dispatch
</on-check-fail>

<on-execute>

### Step 1: Read Full Bead Context

1. Parse bead JSON. Extract: `description`, `acceptance`, `design`, `notes`, `status`, `parent`, `labels`
2. **If bead is an epic child** (BEAD_ID contains a dot):
   - Extract EPIC_ID, read the epic, extract design doc path
   - Read the design doc content — this is the implementation contract
3. Store all context for the dispatch prompt

### Step 2: Resolve Supervisor

1. Read the `assignee` field from the bead JSON — this contains the supervisor name (e.g., `rust-supervisor`)
2. **If `assignee` is set and non-empty:**
   - Verify the agent file exists: `.claude/agents/{assignee}.md`
   - If found → supervisor resolved
   - If NOT found → warn user, fall through to manual selection
3. **If `assignee` is empty or unset:**
   - List available supervisors: find all `*-supervisor.md` in `.claude/agents/`
   - Present the list
   - Inform: "If the supervisor you need is not listed, create one with `/add-supervisor {technology}`."
   - Ask: "Which supervisor should handle this task?"
   - If user wants to create → stop and suggest `/add-supervisor`, then re-run `/do`

### Step 3: Check Branch State

```bash
git branch -a | grep {BEAD_ID}
```

**If branch exists:**
- Inform user: "A branch already exists: `{branch-name}`. This may be from a previous implementation attempt."
- Ask: "Continue on the existing branch, or create a fresh branch?"
- Include context in dispatch prompt

**If no branch exists:**
- Ask: "Which branch should I base from? (default: `main`)"
- Store as `{BASE_BRANCH}`

### Step 4: Dispatch Implementation Supervisor

1. **Announce** before dispatching:
   ```
   Dispatching {resolved-supervisor} for {BEAD_ID}: "{bead title}"
   ```

2. Dispatch using **exactly** these parameters — no more, no less:
   ```python
   Agent(
       subagent_type="{resolved-supervisor}",
       prompt="Implement BEAD {BEAD_ID}. [Include EPIC_ID if epic child]. Base branch: {BASE_BRANCH} — run `git checkout {BASE_BRANCH}` before creating your feature branch. Read the bead (bd show {BEAD_ID}) and comments (bd comments {BEAD_ID}) for full context — description, acceptance criteria, design notes, and investigation findings."
   )
   ```
   **Do NOT add extra parameters** unless the user explicitly requests it.

3. The `PreToolUse` hook automatically injects the discipline reminder because the agent name ends in `-supervisor`.

</on-execute>

<on-complete>
1. Confirm the supervisor was dispatched
2. Show the branch name being used
</on-complete>

<on-next>
After the supervisor completes, recommend `/review {BEAD_ID}` for code review.
</on-next>
