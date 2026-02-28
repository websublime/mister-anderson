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

**Step 1 — Add the marketplace:**

```bash
/plugin marketplace add websublime/mister-anderson
```

**Step 2 — Install the plugin:**

```bash
/plugin install mister-anderson@websublime-mister-anderson
```

**Step 3 — Bootstrap your project:**

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
/product-requirements        Elicit and structure requirements (PRD)
        |
/architect-solution          Design the solution from PRD
        |
/beads-product-owner         Create epics and tasks with acceptance criteria
/create-bead-issues          Create individual issues
        |
/start-task [bd-xxx]         Pick a task, investigate, implement
        |
/review-task [bd-xxx]        Code review gate, optional refactoring
        |
/qa-task [bd-xxx]            QA validation: conformity, tests, build, lint
        |
    Create PR                External reviews run (CodeRabbit, Copilot, etc.)
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
       APPROVE          --> Label: approved, proceed to QA
       NEEDS-REFACTORING --> Dispatch Martin (refactoring-supervisor)
       NEEDS-REWORK     --> Label: needs-rework, back to /start-task
       |
/qa-task
    |
    Phase 1: List beads with approved label
    Phase 2: Read bead context + spec/PRD
    Phase 3: Dispatch Quinn (qa-gate)
       --> Conformity check, user stories, boundaries
       --> Runs tests, build, lint
       --> Audits decision trail
       --> Logs QA: comment with verdict
    Phase 4: Present verdict
       |
       PASS --> Label: qa-passed, ready to merge
       FAIL --> Rework, follow-up bead, or override
```

---

## Skills

User-invocable commands that orchestrate the workflow.

| Skill | Command | Purpose |
|-------|---------|---------|
| **setup-project** | `/setup-project` | One-time bootstrap: init beads, detect stack, create supervisors |
| **product-requirements** | `/product-requirements` | Elicit and structure a PRD from a raw idea |
| **architect-solution** | `/architect-solution` | Dispatch architect for design docs and specs from PRD |
| **beads-product-owner** | `/beads-product-owner` | Create epics and issues from product requirements |
| **create-bead-issues** | `/create-bead-issues` | Create individual well-defined issues |
| **start-task** | `/start-task [bead-id]` | Full implementation cycle: investigate, resolve supervisor, dispatch |
| **review-task** | `/review-task [bead-id]` | Code review gate with optional refactoring dispatch |
| **qa-task** | `/qa-task [bead-id]` | QA finalization: spec conformity, tests, build, lint |
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
| **product-manager.md** | Grace | Requirements elicitation, PRD creation, product strategy | Document advisor |
| **architect.md** | Ada | System design, specs, implementation plans | Document advisor |
| **research.md** | Sherlock | Codebase investigation, root cause analysis | Read-only investigator |
| **code-reviewer.md** | Linus | Quality gate, structured review reports | Read-only reviewer |
| **qa-gate.md** | Quinn | QA finalization: spec conformity, tests, build, lint | QA gate |
| **beads-owner.md** | Fernando | Product owner, creates epics and issues | Task creator |
| **refactoring-supervisor.md** | Martin | Safe code transformation, review finding validation | Implementation supervisor |
| **discovery.md** | Daphne | Supervisor factory: detects tech stack, creates supervisors | Factory agent |

### Dynamic Supervisors (created per project)

Created by the Discovery agent based on your tech stack:

| Technology | Supervisor | Persona |
|------------|-----------|---------|
| Node.js (Express/Fastify/NestJS) | `node-backend-supervisor` | Nina |
| Python (FastAPI/Django/Flask) | `python-backend-supervisor` | Tessa |
| Go | `go-supervisor` | Greta |
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
| **Rule 4** | Log decisions (`DECISION:`) and deviations from spec (`DEVIATION:`) as bead comments |
| **Rule 5** | Log completion summary with files, decision/deviation counts, tests (mandatory) |

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
INVESTIGATION: (Sherlock)    -- what was found in the codebase
DECISION:      (supervisor)  -- non-trivial implementation choices
DEVIATION:     (supervisor)  -- where implementation differs from spec and why
COMPLETED:     (supervisor)  -- what was implemented and how
REVIEW:        (Linus)       -- code quality findings with severities and verdict
REFACTORING:   (Martin)      -- what was fixed, deferred, or skipped
QA:            (Quinn)       -- spec conformity, tests, build, lint, verdict
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
|   |-- product-manager.md       # Grace - requirements elicitation, PRD creation
|   |-- architect.md             # Ada - system design, specs
|   |-- research.md              # Sherlock - codebase investigation (read-only)
|   |-- code-reviewer.md         # Linus - quality gate (read-only)
|   |-- qa-gate.md               # Quinn - QA finalization gate
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
|   |-- product-requirements/
|   |   +-- SKILL.md
|   |-- architect-solution/
|   |   +-- SKILL.md
|   |-- beads-product-owner/
|   |   +-- SKILL.md
|   |-- create-bead-issues/
|   |   +-- SKILL.md
|   |-- qa-task/
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

| Category | Suffix | Writes code? | Writes docs? | Creates beads? | Gets discipline hook? |
|----------|--------|-------------|-------------|----------------|----------------------|
| **Document advisors** | none | No | Yes (PRD, specs) | No | No |
| **Read-only advisors** | none | No | No | No | No |
| **QA gate** | none | No | No | No | No |
| **Task creator** | none | No | No | Yes | No |
| **Factory** | none | Yes (agent files only) | No | No | No |
| **Implementation supervisors** | `-supervisor` | Yes | No | No | Yes |

The `-supervisor` suffix is the key — it triggers the PreToolUse hook that injects engineering discipline.

---

## Quick Start

```bash
# 1. Add the marketplace
/plugin marketplace add websublime/mister-anderson

# 2. Install the plugin
/plugin install mister-anderson@websublime-mister-anderson

# 3. In your project, run setup
/setup-project

# 4. Define product requirements (PRD)
/product-requirements

# 5. Design your solution from the PRD
/architect-solution

# 6. Create tasks from the design
/beads-product-owner

# 7. Start working on a task
/start-task

# 8. When implementation is done, review it
/review-task

# 9. QA validation: conformity, tests, build, lint
/qa-task

# 10. Merge when satisfied
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
4. Core agents are copied: product-manager, architect, research, code-reviewer, qa-gate, beads-owner, refactoring-supervisor, discovery
5. Templates are installed: CLAUDE.md, AGENTS.md, BEADS-WORKFLOW.md
6. Hooks are configured for discipline enforcement and session context

**After setup, verify:**
- `.claude/agents/` contains your tech-specific supervisors (e.g., `react-supervisor.md`, `rust-supervisor.md`)
- `.claude/CLAUDE.md` exists with your project configuration
- `bd list` works and shows no issues yet

**What if your project evolves?** Setup is a one-time bootstrap. If you later add a new technology to your project (e.g., a Rust service in a previously Node.js-only monorepo), you don't re-run setup — you use `/add-supervisor rust` to create the new supervisor on demand. See [Adding a New Supervisor](#adding-a-new-supervisor-monorepo-scenario).

---

### Defining Product Requirements (PRD)

Before designing a solution, define what needs to be built and why. Grace (product-manager) transforms your raw idea into a structured PRD through guided discovery.

```
/product-requirements
```

**What happens:**
1. You're asked for existing documents (briefs, notes, sketches) and where to save the PRD
2. Grace (product-manager) is dispatched and conducts a discovery interview — structured questions to extract requirements
3. She applies product frameworks (JTBD for user stories, RICE/Kano for prioritization) to structure the PRD
4. The PRD is written to the agreed path (default: `docs/prd/PRD-{name}.md`) with status **DRAFT**
5. You review and request changes — Grace iterates via Edit until you're satisfied
6. Once approved, Grace updates status to **APPROVED**

**The PRD includes:** Problem statement, objectives, target users, user stories with acceptance criteria, functional/non-functional requirements with priority classification, out-of-scope boundaries, dependencies, and risks.

**Iterating on a DRAFT:** You can request changes directly — "add this user story", "the scope is too broad", "what about edge case X". Grace edits the file in place, keeping the DRAFT status until you approve.

**Best practice:** Only pass APPROVED PRDs to `/architect-solution`. The PRD is the source of truth for what gets built — ambiguity here causes deviations downstream.

---

### Designing a Solution

Once you have an approved PRD, design the technical solution with Ada (architect). This produces design docs and specs that become the implementation contract.

```
/architect-solution
```

**What happens:**
1. You're asked for the PRD path and where to save the spec (default: `docs/spec/SPEC-{name}.md`)
2. Ada reads the PRD, analyzes the codebase, and researches patterns and dependencies
3. Produces a design document with architecture decisions, data models, API contracts, and implementation plans — written to file with status **DRAFT**
4. You review and iterate — Ada edits the spec via Edit until you approve
5. Once approved, Ada updates status to **APPROVED**
6. The spec references the source PRD for full traceability

**Iterating on a DRAFT:** Same as with the PRD — you can request changes, challenge decisions, ask about trade-offs. Ada edits in place.

**Best practice:** Run this after `/product-requirements` and before creating any tasks. The spec references the PRD and becomes the implementation contract that supervisors follow.

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
- Ready for QA validation — run `/qa-task bd-xxx`

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

### QA Validation Before Merge

After code review approves, Quinn (QA gate) validates that the implementation matches the product spec and that the build is healthy. This is the last gate before you merge.

**List all tasks awaiting QA:**
```
/qa-task
```
Shows beads with the `approved` label. Pick which one to QA.

**QA a specific task:**
```
/qa-task bd-001.2
```

**What happens step by step:**
1. **Context** — Reads the bead, all comments (COMPLETED, DECISION, DEVIATION, REVIEW), and locates the spec/design doc and PRD
2. **Conformity check** — Compares each spec requirement against the implementation: CONFORMS, DEVIATES, MISSING, or EXTRA
3. **User story validation** — Verifies each acceptance criterion is functionally satisfied
4. **Boundary & edge case analysis** — Checks critical boundaries: empty inputs, max values, error paths, null handling
5. **Decision trail audit** — Reads DECISION and DEVIATION comments, flags unlogged deviations found in code
6. **Tests** — Runs the project's test suite
7. **Build** — Runs the build command
8. **Lint** — Runs the linter
9. **Functional verification** — When feasible, exercises the implementation (curl endpoints, run CLI, check outputs)
10. **Verdict** — PASS or FAIL with severity classification (BLOCKER/MAJOR/MINOR)

**If PASS:**
- Label `qa-passed` added
- You're asked if you want to close the bead
- The branch is ready for merge

**If FAIL:**
- Failures listed with severity
- You decide: rework (back to `/start-task`), create follow-up bead, or override and merge anyway

---

### Handling External Review Feedback (CodeRabbit, Copilot, etc.)

If you use external review services (CodeRabbit, GitHub Copilot, SonarQube, etc.) that leave comments on your PRs, the pipeline handles this naturally — no special skill needed.

**The flow:**
1. Your task passes the internal pipeline (`/review-task` → `/qa-task`)
2. You create a PR from the branch
3. The external service runs and leaves comments on the PR
4. You read the comments and filter what's relevant
5. You ask the orchestrator to apply the corrections:

```
"The CodeRabbit review on PR #42 for bead bd-001.2 flagged:
  1. Missing error handling in parseConfig()
  2. Variable should be const instead of let
Can you fix these?"
```

The orchestrator reads the bead, resolves the correct supervisor, and dispatches with the external feedback as context.

**Why no dedicated skill?** External review feedback varies widely in quality and relevance. The human filter is valuable here — you decide what's worth fixing, what's noise, and what's a follow-up task. The orchestrator (this Claude Code session) already has everything needed to dispatch corrections.

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
DECISION:      (supervisor)  -- Non-trivial implementation choices and their reasoning
DEVIATION:     (supervisor)  -- Where implementation differs from spec and why
COMPLETED:     (supervisor)  -- What was implemented, files changed, decisions made
REVIEW:        (Linus)       -- Findings with severities and overall verdict
REFACTORING:   (Martin)      -- What was fixed, deferred, or skipped from review
QA:            (Quinn)       -- Spec conformity, tests, build, lint, final verdict
```

This trail survives session restarts and context compaction. When `/start-task` re-dispatches after a NEEDS-REWORK, the supervisor reads all previous comments via Rule 0 and has full history.

**To inspect a bead's trail at any time:**
```bash
bd comments bd-001.2
```

---

### Merging When Satisfied

mister-anderson never merges for you. After a task passes QA validation (`qa-passed` label):

1. The implementation branch is pushed to remote
2. Create a PR from the branch (or use your normal merge process)
3. Review the PR yourself — the bead comments give you full traceability
4. Merge when you're satisfied
5. Close the bead: `bd close bd-001.2`

The principle: **you decide when it's ready, not the AI.**

---

## License

MIT
