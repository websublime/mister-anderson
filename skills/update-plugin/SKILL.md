---
name: update-plugin
description: Update mister-anderson plugin and clean up legacy local copies that are now provided by the plugin system.
user-invocable: true
---

# Update Plugin

Update the mister-anderson plugin and clean up legacy local copies from older versions.

Since v0.1.0, the plugin system provides skills, core agents, and hooks automatically. This skill handles:
1. Updating the marketplace cache to the latest version
2. Cleaning up legacy local copies that cause duplicate commands
3. Optionally re-running Discovery to refresh dynamic supervisors

---

## What the Plugin Provides vs What Stays Local

### Provided by Plugin (no local copy needed)
- **Skills** — all workflow commands
- **Core agents** — architect, product-manager, research, discovery, code-reviewer, qa-gate, refactoring-supervisor, beads-owner
- **Hooks** — session-start dashboard, discipline injection

### Local to Project (never touched by update)
- **CLAUDE.md** — project-specific orchestrator config
- **AGENTS.md** — project-specific workflow docs
- **BEADS-WORKFLOW.md** — project-specific workflow docs
- **Dynamic supervisors** — `*-supervisor.md` in `.claude/agents/` created by Discovery (project-specific)
- **Beads database** (`.beads/`)
- **Project settings** (`.claude/settings.json`, `.claude/settings.local.json`)
- **Version file** (`.claude/.mister-anderson-version`)

---

## Phase 1: Version Check

Compare installed version with the latest remote version.

```bash
LOCAL_VERSION=$(cat .claude/.mister-anderson-version 2>/dev/null | tr -d '[:space:]')
echo "Installed version: ${LOCAL_VERSION:-unknown}"
```

Fetch the latest version from the remote repository (same method as session-start hook):
```bash
REMOTE_VERSION=$(curl -sf --max-time 5 \
  https://raw.githubusercontent.com/websublime/mister-anderson/main/.claude-plugin/plugin.json \
  2>/dev/null | grep '"version"' | head -1 | sed 's/[^0-9.]//g')
echo "Remote version: ${REMOTE_VERSION:-fetch failed}"
```

**If remote fetch fails:** Warn user that remote version could not be checked. Fall back to reading the local plugin cache as a secondary source:
```bash
cat ${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json
```

**If versions match:** Inform user they are already up to date. Proceed to Phase 2 anyway to check for legacy cleanup.

**If local version is unknown:** Warn that this project may not have been set up with `/setup-project`. Ask user if they want to proceed anyway.

---

## Phase 2: Detect Legacy Local Copies

Check if the project has legacy local copies from older plugin versions (pre-0.1.0):

```bash
# Check for legacy local skills
LEGACY_SKILLS=$(ls -d .claude/skills/*/ 2>/dev/null | wc -l | tr -d '[:space:]')

# Check for legacy local hooks
LEGACY_HOOKS=$(ls .claude/hooks/ 2>/dev/null | wc -l | tr -d '[:space:]')

# Check for legacy core agents (NOT dynamic supervisors)
LEGACY_AGENTS=0
CORE_AGENTS=(architect product-manager research discovery code-reviewer qa-gate beads-owner refactoring-supervisor)
for agent in "${CORE_AGENTS[@]}"; do
  [[ -f ".claude/agents/${agent}.md" ]] && LEGACY_AGENTS=$((LEGACY_AGENTS + 1))
done

echo "Legacy skills: $LEGACY_SKILLS"
echo "Legacy hooks: $LEGACY_HOOKS"
echo "Legacy core agents: $LEGACY_AGENTS"
```

**List dynamic supervisors** that will be PRESERVED:
```bash
# All *-supervisor.md EXCEPT refactoring-supervisor.md (core agent)
ls .claude/agents/*-supervisor.md 2>/dev/null | grep -v refactoring-supervisor.md
```

**If no legacy files found:** Inform user the project is clean. Skip to Phase 4.

**If legacy files found:** Present summary and proceed to Phase 3.

```
Legacy cleanup needed:
  - {LEGACY_SKILLS} local skill directories (duplicates of plugin-provided skills)
  - {LEGACY_HOOKS} local hook files (duplicates of plugin-provided hooks)
  - {LEGACY_AGENTS} local core agent files (duplicates of plugin-provided agents)

Will PRESERVE:
  - CLAUDE.md, AGENTS.md, BEADS-WORKFLOW.md
  - {N} dynamic supervisors: {list names}
  - .beads/ database
  - Project settings
```

**Ask user for confirmation before proceeding.**

---

## Phase 3: Cleanup Legacy Local Copies

After user confirms:

### 3.1 Remove legacy local skills
```bash
rm -rf .claude/skills/
```

### 3.2 Remove legacy local hooks
```bash
rm -rf .claude/hooks/
```

### 3.3 Remove legacy core agents (preserve dynamic supervisors)
```bash
CORE_AGENTS=(architect product-manager research discovery code-reviewer qa-gate beads-owner refactoring-supervisor)
for agent in "${CORE_AGENTS[@]}"; do
  rm -f ".claude/agents/${agent}.md"
done
```

**Important:** Do NOT remove `*-supervisor.md` files created by Discovery — only remove the 8 core agents listed above.

### 3.4 Update version file
```bash
echo "{NEW_VERSION}" > ./.claude/.mister-anderson-version
```

---

## Phase 4: Post-Update Verification

1. **Verify dynamic supervisors are intact:**
   ```bash
   ls .claude/agents/*-supervisor.md 2>/dev/null | grep -v refactoring-supervisor.md
   ```

2. **Verify no legacy duplicates remain:**
   ```bash
   ls -d .claude/skills/*/ 2>/dev/null && echo "WARNING: Local skills still exist" || echo "OK: No local skills"
   ls .claude/hooks/ 2>/dev/null && echo "WARNING: Local hooks still exist" || echo "OK: No local hooks"
   ```

3. **Report result:**
   ```
   mister-anderson updated to {NEW_VERSION}

   Cleaned up: {N} local skills, {N} local hooks, {N} core agents
   Preserved: {N} dynamic supervisors, CLAUDE.md, AGENTS.md

   Skills, core agents, and hooks are now provided by the plugin system.
   Dynamic supervisors remain in .claude/agents/.
   ```

---

## Phase 5: Optional — Re-run Discovery

Offer to refresh dynamic supervisors:

> "Do you want to re-run discovery to refresh your dynamic supervisors? This will NOT delete existing ones — only create missing ones or update the template."

**If user agrees**, dispatch using **exactly** these parameters — no more, no less:
```python
Task(
    subagent_type="discovery",
    prompt="Detect tech stack and create/update supervisors for this project. Do NOT delete existing supervisors. Write supervisor files to .claude/agents/."
)
```
**Do NOT add extra parameters** (e.g., `isolation`, `run_in_background`, etc.) unless the user explicitly requests it.

**If user declines:** no action needed.

---

## Phase 6: Plugin Cache Refresh

**ALWAYS show this warning at the end**, regardless of whether cleanup or discovery ran:

> **Important:** The version file has been updated, but Claude Code's plugin cache may still hold the previous version. To complete the update:
>
> 1. Open the plugin menu: type `/plugin` or go to **Plugins → Installed**
> 2. Select **mister-anderson** and click **"Update now"** — this downloads the latest version into the cache
> 3. **Restart Claude Code** for the new skills, agents, and hooks to take effect
>
> Until you do this, Claude Code will continue using the cached (old) version of the plugin.
