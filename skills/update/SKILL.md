---
name: update
description: Update mister-anderson plugin and clean up legacy local copies that are now provided by the plugin system.
user_invocable: true
---

# Update

Update the mister-anderson plugin and clean up legacy local copies from older versions.

---

<on-init>
This skill has no arguments. It checks versions and detects legacy files automatically.
</on-init>

<on-check>
Compare installed version with the latest remote version.

```bash
LOCAL_VERSION=$(cat .claude/.mister-anderson-version 2>/dev/null | tr -d '[:space:]')
echo "Installed version: ${LOCAL_VERSION:-unknown}"
```

```bash
REMOTE_VERSION=$(curl -sf --max-time 5 \
  https://raw.githubusercontent.com/websublime/mister-anderson/main/.claude-plugin/plugin.json \
  2>/dev/null | grep '"version"' | head -1 | sed 's/[^0-9.]//g')
echo "Remote version: ${REMOTE_VERSION:-fetch failed}"
```

If remote fetch fails, fall back to reading the local plugin cache:
```bash
cat ${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json
```
</on-check>

<on-check-fail if="version_unknown">
This project may not have been set up with `/setup`. Ask user if they want to proceed anyway.
</on-check-fail>

<on-execute>

### What the Plugin Provides vs What Stays Local

**Provided by Plugin (no local copy needed):**
- Skills, core agents, hooks

**Local to Project (never touched by update):**
- CLAUDE.md, AGENTS.md, BEADS-WORKFLOW.md
- Dynamic supervisors (`*-supervisor.md` in `.claude/agents/`)
- `.beads/` database, project settings, version file

---

### Step 1: Detect Legacy Local Copies

```bash
LEGACY_SKILLS=$(ls -d .claude/skills/*/ 2>/dev/null | wc -l | tr -d '[:space:]')
LEGACY_HOOKS=$(ls .claude/hooks/ 2>/dev/null | wc -l | tr -d '[:space:]')
LEGACY_AGENTS=0
CORE_AGENTS=(architect product-manager research discovery code-reviewer qa-gate beads-owner)
for agent in "${CORE_AGENTS[@]}"; do
  [[ -f ".claude/agents/${agent}.md" ]] && LEGACY_AGENTS=$((LEGACY_AGENTS + 1))
done
echo "Legacy skills: $LEGACY_SKILLS"
echo "Legacy hooks: $LEGACY_HOOKS"
echo "Legacy core agents: $LEGACY_AGENTS"
```

List dynamic supervisors that will be PRESERVED:
```bash
ls .claude/agents/*-supervisor.md 2>/dev/null | grep -v "^$"
```

**If no legacy files found:** inform user the project is clean, skip to Step 3.

**If legacy files found:** present summary and ask user for confirmation.

---

### Step 2: Cleanup Legacy Local Copies

After user confirms:

```bash
# Remove legacy local skills
rm -rf .claude/skills/

# Remove legacy local hooks
rm -rf .claude/hooks/

# Remove legacy core agents ONLY (preserve dynamic supervisors)
CORE_AGENTS=(architect product-manager research discovery code-reviewer qa-gate beads-owner)
for agent in "${CORE_AGENTS[@]}"; do
  rm -f ".claude/agents/${agent}.md"
done
rm -f ".claude/agents/refactoring-supervisor.md"
```

**NEVER remove** `*-supervisor.md` files created by Discovery.

Update version file:
```bash
echo "{NEW_VERSION}" > ./.claude/.mister-anderson-version
```

---

### Step 3: Migrate Supervisors for New Plugin Features

Newer plugin versions may introduce frontmatter or workflow contracts that existing supervisors don't have. Supervisors are local to the project (never removed by cleanup) so they need in-place migration.

**Current migrations (as of plugin version introducing state-dimension enforcement):**

1. **`hooks:` block missing from supervisor frontmatter** — required for `SubagentStop` enforcement.
2. **`bd set-state impl=done` step missing from embedded `<on-completion>`** — required so the agent closes the enforcement state before the hook checks it.

#### Detect supervisors needing migration

```bash
SUPERVISORS=$(ls .claude/agents/*-supervisor.md 2>/dev/null)
[[ -z "$SUPERVISORS" ]] && echo "No supervisors to migrate" || {
  echo "Supervisors found:"
  for f in $SUPERVISORS; do
    NEEDS_HOOKS=$(grep -q "verify-state.sh" "$f" && echo "no" || echo "yes")
    NEEDS_STATE=$(grep -q "set-state.*impl=done" "$f" && echo "no" || echo "yes")
    echo "  $f — hooks: $NEEDS_HOOKS, set-state: $NEEDS_STATE"
  done
}
```

#### Patch each supervisor that needs migration

**Do not attempt this with `sed`/`awk`.** Per-supervisor layout varies (different tech stacks, different specialty content injected by discovery). Use `Read` + `Edit` tools so you can see the exact structure before modifying.

For each supervisor file where `NEEDS_HOOKS=yes` or `NEEDS_STATE=yes`:

**(a) Frontmatter `hooks:` block** — if `NEEDS_HOOKS=yes`:

Read the file. Locate the YAML frontmatter (between the opening `---` and closing `---`). Immediately before the closing `---`, insert:

```yaml
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: ${CLAUDE_PLUGIN_ROOT}/hooks/stamp-pending.sh
  Stop:
    - hooks:
        - type: command
          command: ${CLAUDE_PLUGIN_ROOT}/hooks/verify-state.sh
```

Preserve all existing frontmatter fields (`name`, `description`, `model`, `tools`, etc.) exactly.

**(b) Embedded `<on-completion>` set-state step** — if `NEEDS_STATE=yes`:

Read the file. Locate the `<on-completion>` section (inside the embedded beads-workflow block). Find the step that calls `bd comments add {BEAD_ID} "COMPLETED:` and ends with `"`. Immediately after that step's code block closes, insert a new numbered step:

```markdown
3. **Record implementation state (MANDATORY — enforced by SubagentStop hook):**
   ```bash
   bd set-state {BEAD_ID} impl=done --reason "Implementation completed on branch {branch-name}"
   ```
```

Renumber subsequent steps accordingly (Push to remote → 4, Clean up labels → 5, etc.). The numbering must be sequential because the workflow is read step-by-step.

#### Post-patch verification

Re-run the detection block. Every supervisor must now show `hooks: no, set-state: no` (both patches applied).

**If any supervisor still fails**, do NOT force-push a broken state. Report the file and ask the user whether to:
- Retry the patch (may have had a parse issue)
- Regenerate that supervisor via `/add-supervisor <tech>` (Step 5 flow)
- Skip (user will patch manually)

---

### Step 4: Post-Update Verification

```bash
ls .claude/agents/*-supervisor.md 2>/dev/null | grep -v "^$"
ls -d .claude/skills/*/ 2>/dev/null && echo "WARNING: Local skills still exist" || echo "OK: No local skills"
ls .claude/hooks/ 2>/dev/null && echo "WARNING: Local hooks still exist" || echo "OK: No local hooks"
```

---

### Step 5: Optional — Re-run Discovery

Offer to refresh dynamic supervisors. If user agrees:

```python
Agent(
    subagent_type="discovery",
    prompt="Detect tech stack and create/update supervisors for this project. Do NOT delete existing supervisors. Write supervisor files to .claude/agents/."
)
```

**Do NOT add extra parameters** unless the user explicitly requests it.

</on-execute>

<on-complete>
Report result:
```
mister-anderson updated to {NEW_VERSION}

Cleaned up:  {N} local skills, {N} local hooks, {N} core agents
Migrated:    {N} supervisors patched (hooks block / impl=done step)
Preserved:   {N} dynamic supervisors (specialty content intact), CLAUDE.md, AGENTS.md

Skills, core agents, and hooks are now provided by the plugin system.
Dynamic supervisors remain in .claude/agents/ with enforcement hooks attached.
```

If any supervisor migration was skipped, list it explicitly so the user knows enforcement is not active for that supervisor.
</on-complete>

<on-next>
**Important:** The version file has been updated, but Claude Code's plugin cache may still hold the previous version.

1. Open the plugin menu: type `/plugin` or go to **Plugins → Installed**
2. Select **mister-anderson** and click **"Update now"**
3. **Restart Claude Code** for the new skills, agents, and hooks to take effect
</on-next>
