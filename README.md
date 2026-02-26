# mister-anderson

A Claude Code plugin for methodical, human-controlled software development with [beads](https://github.com/steveyegge/beads) task tracking.

> Follow the white rabbit, Neo.

## What This Plugin Does

mister-anderson turns Claude Code into a structured development pipeline where **you stay in control**. Every task gets its own branch, every implementation is investigated before coding starts, every change gets reviewed, and nothing merges without your approval.

This is not multi-agent vibe coding. This is:

- **Task-by-task** execution with full traceability
- **Branch-per-task** isolation keeping main clean
- **Investigation before implementation** so the AI understands before it codes
- **Code review as a gate** you trigger when ready
- **Comment trails** on every bead so context is never lost

## Requirements

- [Claude Code](https://claude.com/claude-code)
- [beads CLI](https://github.com/steveyegge/beads) (`bd` command)

## Installation

```bash
claude plugin add websublime/mister-anderson
```

Then run the setup skill in your project:

```
/setup-project
```

This will:
1. Initialize beads task tracking
2. Detect your tech stack and create specialized supervisors
3. Copy agents, skills, and templates to your project
4. Configure hooks for workflow discipline

---

## The Pipeline

```
/architect-solution          Design the solution
        |
/beads-product-owner         Create epics and tasks with acceptance criteria
/create-bead-issues          Create individual issues
        |
/start-task [bd-xxx]         Pick a task, investigate, implement
        |
/review-task [bd-xxx]        Code review gate, optional refactoring
        |
    User merges              You decide when it's ready
```

### Detailed Flow

```
/start-task bd-xxx
    |
    Phase 1: Resolve bead ID (or show ready tasks)
    Phase 2: Read full context (description, acceptance, design, epic docs)
    Phase 3: Resolve supervisor from notes field
    Phase 4: Investigation check
       |
       No investigation found?
       --> Dispatch Sherlock (research agent)
       --> Logs INVESTIGATION: comment to bead
       |
    Phase 5: Check for existing branch (NEEDS-REWORK cycles)
    Phase 6: Dispatch implementation supervisor
       |
       Supervisor creates branch, implements, tests
       --> Logs COMPLETED: comment to bead
       --> Adds needs-review label
       --> Marks status in-review
       |
/review-task
    |
    Phase 1: List beads with needs-review label
    Phase 2: Read bead context + COMPLETED comment
    Phase 3: Dispatch Linus (code-reviewer)
       --> Logs REVIEW: comment with verdict
    Phase 4: Present verdict
       |
       APPROVE          --> Label: approved, ready to merge
       NEEDS-REFACTORING --> Dispatch Martin (refactoring-supervisor)
       NEEDS-REWORK     --> Label: needs-rework, back to /start-task
```

---

## Skills

User-invocable commands that orchestrate the workflow.

| Skill | Command | Purpose |
|-------|---------|---------|
| **setup-project** | `/setup-project` | One-time bootstrap: init beads, detect stack, create supervisors |
| **architect-solution** | `/architect-solution` | Dispatch architect for design docs and specs |
| **beads-product-owner** | `/beads-product-owner` | Create epics and issues from product requirements |
| **create-bead-issues** | `/create-bead-issues` | Create individual well-defined issues |
| **start-task** | `/start-task [bead-id]` | Full implementation cycle: investigate, resolve supervisor, dispatch |
| **review-task** | `/review-task [bead-id]` | Code review gate with optional refactoring dispatch |
| **add-supervisor** | `/add-supervisor [tech]` | Create a new supervisor for a specific technology |

### Internal Skills

| Skill | Purpose |
|-------|---------|
| **subagents-discipline** | Engineering principles auto-injected into implementation supervisors (Rules 0-5) |

---

## Agents

### Core Agents (included with plugin)

| Agent | Persona | Role | Type |
|-------|---------|------|------|
| **architect.md** | Ada | System design, specs, implementation plans | Read-only advisor |
| **research.md** | Sherlock | Codebase investigation, root cause analysis | Read-only investigator |
| **code-reviewer.md** | Linus | Quality gate, structured review reports | Read-only reviewer |
| **beads-owner.md** | Fernando | Product owner, creates epics and issues | Task creator |
| **refactoring-supervisor.md** | Martin | Safe code transformation, review finding validation | Implementation supervisor |
| **discovery.md** | Daphne | Supervisor factory: detects tech stack, creates supervisors | Factory agent |

### Dynamic Supervisors (created per project)

Created by the Discovery agent based on your tech stack:

| Technology | Supervisor | Persona |
|------------|-----------|---------|
| Node.js (Express/Fastify/NestJS) | `node-backend-supervisor` | Nina |
| Python (FastAPI/Django/Flask) | `python-backend-supervisor` | Tessa |
| Go | `go-supervisor` | Grace |
| Rust | `rust-supervisor` | Neo |
| React/Next.js | `react-supervisor` | Luna |
| Vue/Nuxt | `vue-supervisor` | Violet |
| Svelte | `svelte-supervisor` | -- |
| Angular | `angular-supervisor` | -- |
| Docker/CI/Terraform | `infra-supervisor` | Olive |
| Flutter | `flutter-supervisor` | Maya |
| iOS | `ios-supervisor` | Isla |
| Android | `android-supervisor` | Ava |
| Blockchain/Web3 | `blockchain-supervisor` | Nova |
| ML/AI | `ml-supervisor` | Iris |

Need a supervisor that doesn't exist? Run `/add-supervisor {tech}`.

---

## How It Works

### Task Routing

When Fernando (beads-owner) creates a task, he adds a `supervisor:` field in the notes:

```
supervisor: rust-supervisor
```

The `/start-task` skill reads this field and dispatches the correct supervisor automatically. If the supervisor doesn't exist, it suggests `/add-supervisor`.

### Investigation Before Implementation

Every task can go through an investigation phase. Sherlock (research agent) reads the bead, traces code paths, identifies root cause, and logs structured findings:

```
INVESTIGATION:
Root cause: Missing null check in parseConfig() at config.ts:42
Files: config.ts:42, types.ts:15
Approach: Add optional chaining and fallback default
Risks: Other callers may depend on the thrown error
Related tests: config.test.ts
```

Implementation supervisors read this via **Rule 0** ("Read the Bead First") before writing any code.

### Discipline Enforcement

All implementation supervisors follow 5 mandatory rules:

| Rule | Principle |
|------|-----------|
| **Rule 0** | Read the bead comments before implementing |
| **Rule 1** | Look at actual data before coding against it |
| **Rule 2** | Test functionally — close the loop |
| **Rule 3** | Use available tools to verify |
| **Rule 4** | Log your approach if you deviated (optional) |
| **Rule 5** | Log completion summary with files, decisions, tests (mandatory) |

### Code Review Gate

After implementation, the supervisor marks the bead `in-review` with label `needs-review`. When you run `/review-task`:

1. **Linus** (code-reviewer) analyzes the branch diff against acceptance criteria
2. Each finding has a severity: `CRITICAL`, `WARNING`, `SUGGESTION`, `GOOD`
3. Verdict: `APPROVE`, `NEEDS-REFACTORING`, or `NEEDS-REWORK`

### Smart Refactoring

If the verdict is `NEEDS-REFACTORING`, **Martin** (refactoring-supervisor) doesn't blindly apply fixes. For each finding he:

1. **Validates** — is it a real issue or false positive?
2. **Cross-references beads** — is it already tracked in a future task?
3. **If tracked** — adds a `// TODO(bd-xxx): description` instead of fixing
4. **If real** — applies the fix with tests
5. **If risky** — skips and logs why

### Comment Trail

Every bead accumulates a structured history:

```
INVESTIGATION: (Sherlock)  -- what was found in the codebase
COMPLETED:     (supervisor) -- what was implemented and how
REVIEW:        (Linus)     -- findings with severities and verdict
REFACTORING:   (Martin)    -- what was fixed, deferred, or skipped
```

This trail persists across sessions and compaction. Any agent or human can reconstruct the full context.

### Branch-Per-Task Workflow

Every implementation task follows:

1. Create branch: `feature/{task-id-kebab-case}`
2. Mark bead `in_progress`
3. Implement with frequent commits
4. Push to remote
5. Add `needs-review` label
6. Mark bead `in-review`
7. **You** merge via PR when satisfied

Banned: working on main, implementing without a bead ID, self-merging.

---

## Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| **inject-discipline-reminder.sh** | `PreToolUse` (Task tool) | Injects discipline skill reminder when dispatching `*-supervisor` agents |
| **session-start.sh** | `SessionStart` | Shows task context: in-progress, ready, blocked, stale, and labeled beads |

---

## Project Structure

```
mister-anderson/
|-- .claude-plugin/
|   +-- plugin.json              # Plugin manifest
|-- agents/
|   |-- architect.md             # Ada - system design (read-only)
|   |-- research.md              # Sherlock - codebase investigation (read-only)
|   |-- code-reviewer.md         # Linus - quality gate (read-only)
|   |-- beads-owner.md           # Fernando - product owner (task creator)
|   |-- refactoring-supervisor.md # Martin - safe refactoring (implementation)
|   +-- discovery.md             # Daphne - supervisor factory
|-- hooks/
|   |-- hooks.json               # Hook configuration
|   |-- inject-discipline-reminder.sh
|   +-- session-start.sh
|-- skills/
|   |-- setup-project/
|   |   |-- SKILL.md             # Bootstrap skill
|   |   +-- templates/
|   |       |-- AGENTS.md        # Agent instructions template
|   |       |-- BEADS-WORKFLOW.md # Branch-per-task workflow template
|   |       +-- CLAUDE.md        # Project config template
|   |-- architect-solution/
|   |   +-- SKILL.md
|   |-- beads-product-owner/
|   |   +-- SKILL.md
|   |-- create-bead-issues/
|   |   +-- SKILL.md
|   |-- start-task/
|   |   +-- SKILL.md
|   |-- review-task/
|   |   +-- SKILL.md
|   |-- add-supervisor/
|   |   +-- SKILL.md
|   +-- subagents-discipline/
|       +-- SKILL.md             # Auto-injected engineering rules
|-- LICENSE
+-- README.md
```

---

## Agent Classification

Agents are categorized by what they can do:

| Category | Suffix | Writes code? | Creates beads? | Gets discipline hook? |
|----------|--------|-------------|----------------|----------------------|
| **Read-only advisors** | none | No | No | No |
| **Task creator** | none | No | Yes | No |
| **Factory** | none | Yes (agent files only) | No | No |
| **Implementation supervisors** | `-supervisor` | Yes | No | Yes |

The `-supervisor` suffix is the key — it triggers the PreToolUse hook that injects engineering discipline.

---

## Quick Start

```bash
# 1. Install the plugin
claude plugin add websublime/mister-anderson

# 2. In your project, run setup
/setup-project

# 3. Design your solution
/architect-solution

# 4. Create tasks from the design
/beads-product-owner

# 5. Start working on a task
/start-task

# 6. When implementation is done, review it
/review-task

# 7. Merge when satisfied
```

---

## How-To Guides

### Setting Up a New Project

Setup requires an **existing project skeleton** — the Discovery agent scans for files like `package.json`, `Cargo.toml`, `go.mod`, `requirements.txt`, etc. to detect your tech stack and create the right supervisors. If you run setup on an empty directory, no supervisors will be created because there's nothing to detect.

**Prerequisite:** Your project already has its initial structure (at minimum, the manifest files for your tech stack).

```
/setup-project
```

**What happens:**
1. Beads task tracking is initialized (`bd init`)
2. Daphne (Discovery agent) scans your codebase to detect tech stacks (package.json, Cargo.toml, go.mod, etc.)
3. For each detected stack, a specialized supervisor is created in `.claude/agents/` by fetching from the external directory and injecting the beads workflow
4. Core agents are copied: architect, research, code-reviewer, beads-owner, refactoring-supervisor, discovery
5. Templates are installed: CLAUDE.md, AGENTS.md, BEADS-WORKFLOW.md
6. Hooks are configured for discipline enforcement and session context

**After setup, verify:**
- `.claude/agents/` contains your tech-specific supervisors (e.g., `react-supervisor.md`, `rust-supervisor.md`)
- `.claude/CLAUDE.md` exists with your project configuration
- `bd list` works and shows no issues yet

**What if your project evolves?** Setup is a one-time bootstrap. If you later add a new technology to your project (e.g., a Rust service in a previously Node.js-only monorepo), you don't re-run setup — you use `/add-supervisor rust` to create the new supervisor on demand. See [Adding a New Supervisor](#adding-a-new-supervisor-monorepo-scenario).

---

### Designing a Solution

Before creating tasks, design the solution with Ada (architect). This produces design docs and specs that become the implementation contract.

```
/architect-solution
```

**What happens:**
1. Ada analyzes your requirements and codebase
2. Produces design documents with architecture decisions, data models, API contracts, and implementation plans
3. These docs are referenced by beads tasks via the `design` field

**Best practice:** Run this before creating any tasks. The design doc is what keeps implementation aligned — supervisors and the research agent both reference it.

---

### Creating Tasks from a Design

Once you have a design, Fernando (beads-owner) breaks it down into epics and tasks with acceptance criteria.

**For epics with subtasks:**
```
/beads-product-owner
```

Fernando creates epics and child tasks. Each task includes:
- Clear description tied to the design
- Acceptance criteria (what "done" means)
- A `supervisor:` routing field in notes pointing to the correct implementation supervisor
- Priority and dependency information

**For individual well-defined issues:**
```
/create-bead-issues
```

Use this when you already know exactly what needs to be done and don't need the full epic structure.

**After creating tasks, verify routing:**
```bash
bd show bd-001.1 --json
```
Check that the `notes` field contains `supervisor: {name}-supervisor` and that the referenced supervisor exists in `.claude/agents/`.

---

### Starting Work on a Task

This is the main entry point for implementation. The skill handles everything: resolving what to work on, investigating the codebase, and dispatching the right supervisor.

**Pick from ready tasks (recommended):**
```
/start-task
```
Shows all unblocked tasks from `bd ready` with ID, title, priority, and labels. Pick by order and priority.

**Start a specific task:**
```
/start-task bd-001.2
```

**What happens step by step:**
1. **Resolve** — Validates the bead exists and reads full context (description, acceptance, design, notes)
2. **Epic context** — If this is an epic child (e.g., `bd-001.2`), reads the parent epic's design doc as the implementation contract
3. **Supervisor routing** — Reads the `supervisor:` field from notes, verifies the agent file exists in `.claude/agents/`
4. **Investigation** — Checks if Sherlock has already investigated (looks for `INVESTIGATION:` in bead comments). If not, asks if you want to dispatch research first
5. **Branch check** — Detects if a branch already exists (from a previous NEEDS-REWORK cycle) and asks whether to continue on it or start fresh
6. **Dispatch** — Sends the task to the resolved supervisor with full context. The PreToolUse hook automatically injects engineering discipline (Rules 0-5)

**The supervisor then:**
- Creates branch `feature/{task-id-kebab-case}`
- Marks bead `in_progress`
- Implements with frequent commits
- Pushes to remote
- Logs a `COMPLETED:` comment with summary of files changed, decisions made, and tests run
- Adds `needs-review` label
- Marks bead `in-review`

---

### Reviewing Completed Work

After a supervisor finishes implementation, the task enters the review gate. You control when this happens.

**List all tasks awaiting review:**
```
/review-task
```
Shows beads with the `needs-review` label. Pick which one to review.

**Review a specific task:**
```
/review-task bd-001.2
```

**What happens step by step:**
1. **Context** — Reads the bead, its comments (especially the `COMPLETED:` summary), and identifies the implementation branch
2. **Code review** — Linus (code-reviewer) analyzes the branch diff against acceptance criteria. Each finding gets a severity: `CRITICAL`, `WARNING`, `SUGGESTION`, or `GOOD`
3. **Verdict** — One of three outcomes:

**APPROVE** — Code review passed:
- Labels updated: `needs-review` removed, `approved` added
- The branch is ready for you to merge via PR
- No further dispatch needed

**NEEDS-REFACTORING** — Minor issues, fixable without re-implementation:
- You're shown the findings and asked if you want to dispatch Martin (refactoring-supervisor)
- If yes, Martin validates each finding: checks for false positives, cross-references with future beads, adds `// TODO(bd-xxx)` for tracked issues, and only fixes validated real issues
- After refactoring, Martin logs a `REFACTORING:` comment and the task goes through review again

**NEEDS-REWORK** — Critical issues or acceptance criteria unmet:
- Labels updated: `needs-review` removed, `needs-rework` added
- You're told to use `/start-task bd-xxx` to re-dispatch the implementation supervisor
- The existing branch is preserved — `/start-task` will detect it and ask if you want to continue on it

---

### Handling a NEEDS-REWORK Cycle

When a code review returns `NEEDS-REWORK`, the task goes back to the implementation supervisor for substantial changes.

```
/start-task bd-001.2
```

**What's different from the first run:**
1. The bead already has an `INVESTIGATION:` comment — Sherlock's research is reused
2. A branch already exists — you're asked whether to continue on it or start fresh
3. The bead has a `REVIEW:` comment — the supervisor reads it via Rule 0 to understand what went wrong
4. The `needs-rework` label tells everyone this is a second pass

After the supervisor finishes, the task goes back to `in-review` with `needs-review` label, and you run `/review-task` again.

---

### Handling NEEDS-REFACTORING

When a code review returns `NEEDS-REFACTORING`, the issues are minor enough that Martin (refactoring-supervisor) can address them without full re-implementation.

During `/review-task`, after seeing the findings, you're asked:

> "Do you want to dispatch the refactoring-supervisor to address these findings?"

**If yes**, Martin is dispatched. For each finding he:

1. **Reads the code in context** — Is this actually a problem? If not → marks as `FALSE-POSITIVE`
2. **Checks existing beads** — Is this already tracked in a future task? If yes → adds `// TODO(bd-xxx): description` and marks as `DEFERRED`
3. **Assesses risk** — Would fixing this break other things or go beyond scope? If risky → marks as `SKIPPED` with reason
4. **Applies the fix** — Only for validated real issues → marks as `FIXED`

Martin logs a structured `REFACTORING:` comment to the bead with the disposition of every finding. After refactoring, the task goes through another review cycle.

---

### Adding a New Supervisor (Monorepo Scenario)

When you add a new technology to your project after the initial setup — for example, a new Rust service in a monorepo that previously only had Node.js — the needed supervisor won't exist yet.

**Scenario:** You run `/start-task` and the `supervisor: rust-supervisor` field points to an agent that doesn't exist. The skill warns you and suggests creating one.

```
/add-supervisor rust
```

**What happens:**
1. Checks if a supervisor already exists for this technology (e.g., `rust-supervisor.md` in `.claude/agents/`)
2. If not, dispatches Daphne (Discovery) in **on-demand mode** — she skips the full codebase scan and creates only the requested supervisor
3. The supervisor is fetched from the external directory, filtered, injected with the beads workflow, and written to `.claude/agents/`
4. CLAUDE.md Supervisors section is updated

**After creation:**
```
/start-task bd-001.2
```
Now the `supervisor: rust-supervisor` routing resolves correctly.

**Supported technologies:** Node.js, Python, Go, Rust, React, Vue, Svelte, Angular, Docker/CI/Terraform, Flutter, iOS, Android, Blockchain/Web3, ML/AI. If your technology isn't in the list, `/add-supervisor` will attempt to create one — Discovery handles the mapping.

---

### Creating Individual Issues Without Epics

Sometimes you need to create a single, well-defined issue without the full epic structure — a bug fix, a small improvement, or a standalone task.

```
/create-bead-issues
```

Fernando (beads-owner) creates the issue with:
- Description of what needs to be done
- Acceptance criteria
- The `supervisor:` routing field in notes
- Priority and any relevant labels

This is useful when you already know exactly what the task is and don't need architectural decomposition.

---

### The Complete Comment Trail

Every bead accumulates a structured history that any agent or human can read to reconstruct full context:

```
INVESTIGATION: (Sherlock)    -- What was found in the codebase before implementation
COMPLETED:     (supervisor)  -- What was implemented, files changed, decisions made
REVIEW:        (Linus)       -- Findings with severities and overall verdict
REFACTORING:   (Martin)      -- What was fixed, deferred, or skipped from review
```

This trail survives session restarts and context compaction. When `/start-task` re-dispatches after a NEEDS-REWORK, the supervisor reads all previous comments via Rule 0 and has full history.

**To inspect a bead's trail at any time:**
```bash
bd comments bd-001.2
```

---

### Merging When Satisfied

mister-anderson never merges for you. After a task receives the `approved` label from code review:

1. The implementation branch is pushed to remote
2. Create a PR from the branch (or use your normal merge process)
3. Review the PR yourself — the bead comments give you full traceability
4. Merge when you're satisfied
5. Close the bead: `bd close bd-001.2`

The principle: **you decide when it's ready, not the AI.**

---

## License

MIT
