---
name: setup-beads-project
description: Bootstrap project orchestration with beads task tracking.
user-invocable: true
---

# Setup project

Set up lightweight multi-agent orchestration with git-native task tracking for Claude Code.

## What This Skill Does

This skill bootstraps a complete workflow where:

- **Orchestrator** (you) investigates issues, manages tasks, delegates implementation
- **Supervisors** (specialized agents) execute implementation on feature branches
- **Beads CLI** tracks all work with git-native task management
- **Hooks** enforce workflow discipline automatically (provided by the plugin)

Each task gets its own branch, keeping main clean and enabling human session work.

## What the Plugin Already Provides

The mister-anderson plugin (installed via Claude Code plugin system) automatically provides:
- **Skills** — all workflow commands (`/start-task`, `/review-task`, etc.)
- **Core agents** — architect, product-manager, research, code-reviewer, qa-gate, beads-owner, refactoring-supervisor, discovery
- **Hooks** — session-start dashboard, discipline injection for supervisors

**This setup skill only creates project-specific files that the plugin cannot provide.**

---

## Requirements

- **beads CLI** (>= 0.56): Install from https://github.com/steveyegge/beads/tree/main
- **Dolt SQL server**: beads 0.56+ requires a running Dolt sql-server (port 3307 or 3306)

Test if `bd --version` works on terminal, if not stop all the setup process and tell user to install beads from here: https://github.com/steveyegge/beads/tree/main

Also verify a Dolt sql-server is reachable (beads auto-detects on ports 3307/3306).

---

## Step 0: Detect Setup State (ALWAYS RUN FIRST)

<detection-phase>
**Before doing anything else, detect if this is a fresh setup or a resume after restart.**

Check if beads is initialized:
```bash
bd list 2>/dev/null && echo "BEADS_INITIALIZED" || echo "BEADS_NOT_INITIALIZED"
```

**If `BEADS_NOT_INITIALIZED`:**
- Init in bash: `bd init`
- Config custom statuses: `bd config set status.custom "in-review"`

**If `BEADS_INITIALIZED`:**
- Beads ready to use, proceed to next check

Check for bootstrap artifacts:
```bash
ls ./CLAUDE.md 2>/dev/null && echo "BOOTSTRAP_COMPLETE" || echo "FRESH_SETUP"
```

**If `BOOTSTRAP_COMPLETE`:**
- Bootstrap already ran in a previous session
- Do NOT ask for project info or run bootstrap again

**If `FRESH_SETUP`:**
- This is a new installation
- Proceed to **Step 1: Get Project Info**
</detection-phase>

---

## Step 1: Get Project Info (Fresh Setup Only)

<critical-step1>
**YOU MUST GET PROJECT INFO AND DETECT/ASK ABOUT THE PROJECT BEFORE PROCEEDING TO STEP 2.**

1. **Project directory**: Get current working directory
2. **Project info**: Ask the user about the project name and a overview about it
3. **Project docs**: Ask the user about where to find documents about the project (Product requirement, spec, plans)

If no docs provided skip the step.
</critical-step1>

### 1.1 Get Project Tech

Go thru the project and try to detect type of tech:

- Javascript/typescript (package.json)
- Rust (cargo.toml)
- Go (go.mod)
- Python (requirements.txt, pyproject.toml)

---

## Step 2: Create CLAUDE.md

Use the template at `${CLAUDE_PLUGIN_ROOT}/skills/setup-project/templates/CLAUDE.md` and update sections with previous information.

<mandatory>
**YOU MUST CREATE SECTION OF PROJECT STRUCTURE**

Example from directory:

## Repository Structure

```
vite-open-api-server/
├── packages/
│   ├── core/                         # Core server logic (Hono, store, generator)
│   ├── devtools-client/              # Vue SPA for DevTools
│   ├── vite-plugin/                  # Vite plugin wrapper
│   └── playground/                   # Demo application
├── history/                          # Planning and architecture docs
│   ├── PRODUCT-REQUIREMENTS-DOC-V2.md # Product Requirements Document (v1.0.0)
│   ├── TECHNICAL-SPECIFICATION-V2.md  # Technical Specification (v1.0.0)
│   ├── PLAN-V2.md                     # Development Plan (v1.0.0)
│   ├── PRODUCT-REQUIREMENTS-DOC.md    # [Legacy] PRD (v0.x)
│   ├── TECHNICAL-SPECIFICATION.md     # [Legacy] Tech Spec (v0.x)
│   └── PLAN.md                        # [Legacy] Plan (v0.x)
├── .github/workflows/                # CI/CD workflows
└── biome.json, tsconfig.json, etc.   # Configuration files
```
</mandatory>

Write the CLAUDE.md file to the root of the project (do NOT copy — generate from template with project info filled in).

---

## Step 3: Create AGENTS.md

Use the template at `${CLAUDE_PLUGIN_ROOT}/skills/setup-project/templates/AGENTS.md`.

Copy or write file to the root of the project.

---

## Step 4: Create Tech Supervisors

Dynamic supervisors are project-specific and must live in `.claude/agents/`. Ensure the directory exists:

```bash
mkdir -p .claude/agents
```

Dispatch using **exactly** these parameters — no more, no less:

```python
Task(
    subagent_type="discovery",
    prompt="Detect tech stack and create supervisors for this project. Write supervisor files to .claude/agents/."
)
```

**Do NOT add extra parameters** (e.g., `isolation`, `run_in_background`, etc.) unless the user explicitly requests it.

---

## Step 5: Write Version File

Write the installed plugin version to `.claude/.mister-anderson-version` so the session-start hook can detect when updates are available.

```bash
echo "0.0.9" > ./.claude/.mister-anderson-version
```

> **Important:** When bumping the plugin version, update this step to match the new version in `plugin.json`.

---

## Step 6: Cleanup Legacy Local Copies (if upgrading from pre-0.1.0)

Check if the project has legacy local copies from older plugin versions that copied skills, core agents, and hooks locally. These are no longer needed — the plugin system provides them.

```bash
# Check for legacy local skills
ls -d .claude/skills/*/ 2>/dev/null
# Check for legacy local hooks
ls .claude/hooks/ 2>/dev/null
# Check for legacy core agents (NOT dynamic supervisors)
ls .claude/agents/{architect,product-manager,research,discovery,code-reviewer,qa-gate,beads-owner}.md 2>/dev/null
```

**If legacy files found:**
- Inform user: "Found legacy local copies from a previous plugin version. These are now provided by the plugin system and the local copies cause duplicate commands."
- Ask user: "Do you want to remove the legacy local copies? Your dynamic supervisors and project files (CLAUDE.md, AGENTS.md) will NOT be touched."
- **If user agrees** → run cleanup (see below)
- **If user declines** → skip, warn that duplicate commands will persist

### Cleanup commands

```bash
# Remove legacy local skills (plugin provides these)
rm -rf .claude/skills/

# Remove legacy local hooks (plugin provides these via plugin.json)
rm -rf .claude/hooks/

# Remove legacy core agents ONLY (preserve dynamic supervisors)
CORE_AGENTS=(architect product-manager research discovery code-reviewer qa-gate beads-owner refactoring-supervisor)
for agent in "${CORE_AGENTS[@]}"; do
  rm -f ".claude/agents/${agent}.md"
done
```

**Important:** Do NOT remove `.claude/agents/*-supervisor.md` files created by Discovery — those are project-specific. Only remove the 8 core agents listed above.
