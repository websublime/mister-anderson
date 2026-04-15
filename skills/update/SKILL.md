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

### Step 3: Post-Update Verification

```bash
ls .claude/agents/*-supervisor.md 2>/dev/null | grep -v "^$"
ls -d .claude/skills/*/ 2>/dev/null && echo "WARNING: Local skills still exist" || echo "OK: No local skills"
ls .claude/hooks/ 2>/dev/null && echo "WARNING: Local hooks still exist" || echo "OK: No local hooks"
```

---

### Step 4: Optional — Re-run Discovery

Offer to refresh dynamic supervisors. If user agrees:

```python
Task(
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

Cleaned up: {N} local skills, {N} local hooks, {N} core agents
Preserved: {N} dynamic supervisors, CLAUDE.md, AGENTS.md

Skills, core agents, and hooks are now provided by the plugin system.
Dynamic supervisors remain in .claude/agents/.
```
</on-complete>

<on-next>
**Important:** The version file has been updated, but Claude Code's plugin cache may still hold the previous version.

1. Open the plugin menu: type `/plugin` or go to **Plugins → Installed**
2. Select **mister-anderson** and click **"Update now"**
3. **Restart Claude Code** for the new skills, agents, and hooks to take effect
</on-next>
