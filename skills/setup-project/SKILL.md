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
- **Supervisors** (specialized agents) execute fixes in isolated worktrees
- **Beads CLI** tracks all work with git-native task management
- **Hooks** enforce workflow discipline automatically

Each task gets its own branch, keeping main clean and enabling human session work.

---

## Requirements

- **beads CLI**: Installed automatically by bootstrap (via brew, npm, or go)

Test if `bd --version` works on terminal, if not stop all the setup process and tel user to install beads from here: https://github.com/steveyegge/beads/tree/main

---

## Step 0: Detect Setup State (ALWAYS RUN FIRST)

<detection-phase>
**Before doing anything else, detect if this is a fresh setup or a resume after restart.**

Check if beads is initialized:
```bash
bd list 2>/dev/null && echo "BEADS_INITIALIZED" || echo "BEADS_NOT_INITIALIZED"
```

**If `BEADS_NOT_INITIALIZED`:**
- Init in bash: `bd init --branch beads-sync`
- Config in bash: `bd config set routing.maintainer "."`

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

## Step 2: Create and copy CLAUDE.md

Use the template at `./skills/setup-project/templates/CLAUDE.md` and update sections with previous information.

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

Copy or write file to the root of the project.

```bash
cp ./skills/setup-project/templates/CLAUDE.md ./
```

---

## Step 3: Create and copy AGENTS.md

Use the template at `./skills/setup-project/templates/AGENTS.md`.

Copy or write file to the root of the project.

```bash
cp ./skills/setup-project/templates/AGENTS.md ./
```

---

## Step 4: Copy skills directory

Copy skills directory to .claude/skills.

```bash
cp -r ./skills ./claude/skills
```

---

## Step 5: Create Tech supervisors

```python
Task(
    subagent_type="discovery",
    prompt="Detect tech stack and create supervisors for this project"
)
```

## Step 6: Delete Setup Skills

Delete setup skills directory from .claude/skills/setup-project.

```bash
rm -rf ./claude/skills/setup-project
```
