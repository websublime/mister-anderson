---
name: setup
description: Bootstrap project orchestration with beads task tracking.
user_invocable: true
---

# Setup

Set up lightweight multi-agent orchestration with git-native task tracking for Claude Code.

---

<on-init>
This skill has no arguments. It detects project state automatically.
</on-init>

<on-check>
1. **beads CLI must be installed (>= 0.60).** Test with `bd --version`.
2. **Dolt SQL server must be reachable.** beads 0.56+ requires a running Dolt sql-server (port 3307 or 3306).

If either check fails, stop the setup process.
</on-check>

<on-check-fail if="beads">
beads CLI not found. Install from: https://github.com/steveyegge/beads/tree/main
</on-check-fail>

<on-check-fail if="dolt">
Dolt SQL server not reachable. beads 0.56+ requires a running Dolt sql-server on port 3307 or 3306.
</on-check-fail>

<on-execute>

### Step 0: Detect Setup State

Before doing anything else, detect if this is a fresh setup or a resume after restart.

```bash
bd list 2>/dev/null && echo "BEADS_INITIALIZED" || echo "BEADS_NOT_INITIALIZED"
```

**If `BEADS_NOT_INITIALIZED`:**
- Init: `bd init`
- Config custom statuses: `bd config set status.custom "in-review"`

**If `BEADS_INITIALIZED`:** proceed to next check.

```bash
ls ./CLAUDE.md 2>/dev/null && echo "BOOTSTRAP_COMPLETE" || echo "FRESH_SETUP"
```

**If `BOOTSTRAP_COMPLETE`:** Bootstrap already ran — do NOT ask for project info again. Skip to Step 4.

**If `FRESH_SETUP`:** Proceed to Step 1.

---

### Step 1: Get Project Info (Fresh Setup Only)

**YOU MUST GET PROJECT INFO BEFORE PROCEEDING TO STEP 2.**

1. **Project directory**: Get current working directory
2. **Project info**: Ask the user about the project name and overview
3. **Project docs**: Ask the user where to find documents (PRD, spec, plans)
4. **Detect tech stack**: Check for `package.json` (JS/TS), `Cargo.toml` (Rust), `go.mod` (Go), `pyproject.toml`/`requirements.txt` (Python)

If no docs provided, skip that step.

---

### Step 2: Create CLAUDE.md

Use the template at `${CLAUDE_PLUGIN_ROOT}/skills/setup/templates/CLAUDE.md` and fill in project info.

**MANDATORY: Create a Repository Structure section** by scanning the project directory. Example:

```
project-name/
├── packages/
│   ├── core/                         # Core logic
│   └── plugin/                       # Plugin wrapper
├── docs/                             # Planning and architecture
├── .github/workflows/                # CI/CD
└── config files
```

Write to the root of the project (generate from template, do NOT copy verbatim).

---

### Step 3: Create AGENTS.md

Use the template at `${CLAUDE_PLUGIN_ROOT}/skills/setup/templates/AGENTS.md`. Write to the root of the project.

---

### Step 4: Create Tech Supervisors

Ensure `.claude/agents/` exists, then dispatch:

```python
Agent(
    subagent_type="discovery",
    prompt="Detect tech stack and create supervisors for this project. Write supervisor files to .claude/agents/."
)
```

**Do NOT add extra parameters** unless the user explicitly requests it.

---

### Step 5: Write Version File

```bash
echo "0.3.0" > ./.claude/.mister-anderson-version
```

> When bumping the plugin version, update this step to match `plugin.json`.

---

### Step 6: Cleanup Legacy Local Copies

Check for legacy local copies from pre-0.1.0 versions:

```bash
ls -d .claude/skills/*/ 2>/dev/null
ls .claude/hooks/ 2>/dev/null
ls .claude/agents/{architect,product-manager,research,discovery,code-reviewer,qa-gate,beads-owner}.md 2>/dev/null
```

**If legacy files found:**
- Inform user these are now provided by the plugin system
- Ask for confirmation before removing
- Remove legacy skills (`rm -rf .claude/skills/`), hooks (`rm -rf .claude/hooks/`), and core agents only
- **NEVER remove** `*-supervisor.md` files created by Discovery

**If no legacy files found:** skip this step.

</on-execute>

<on-complete>
1. Verify CLAUDE.md exists at project root
2. Verify AGENTS.md exists at project root
3. Verify `.claude/agents/` contains dynamic supervisors
4. Verify `.claude/.mister-anderson-version` matches expected version
5. Report setup summary to user
</on-complete>

<on-next>
Setup complete. Recommend starting the product pipeline with `/requirements` or checking project state with `/workflow`.
</on-next>
