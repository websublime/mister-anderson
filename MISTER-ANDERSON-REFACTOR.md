# Mister-Anderson Plugin Refactor

**Date:** 2026-04-15
**Status:** Awaiting review — no commits made yet
**Scope:** Complete restructuring of the plugin pipeline to eliminate task drift

---

## 1. Problem Statement

### What happened

The `unblock` project's epic `unblock-29p` grew from ~14 planned tasks to 32 during implementation. This "task drift" is a systemic problem in the plugin's multi-agent pipeline, not an isolated incident.

### Root cause analysis

Three structural flaws were identified:

#### Flaw 1 — No research/validation step before spec creation

The pipeline went directly from Plan → Spec. Ada (Architect) created specs based on unvalidated assumptions from the plan. When supervisors hit reality during implementation, they discovered mismatches and created new tasks to handle them.

**Fix:** Introduced a new Feasibility Research step (Smith agent) between Plan and Spec. Smith investigates APIs, libraries, and existing code to validate every assumption in the plan. Ada then builds the spec on verified facts, not assumptions.

#### Flaw 2 — Beads duplicate spec content (lossy compression)

The beads-product-owner skill (Fernando) was copying spec content into bead fields — descriptions, design notes, acceptance criteria all contained summarized versions of the spec. Each summary lost nuance. Supervisors treated the bead as the source of truth instead of reading the actual spec, leading to implementation gaps.

**Fix:** Beads are now reference-only tracking artifacts. The `--design` field contains a one-line pointer (e.g., `See spec.md § Section 3`). The `--external-ref` field points to spec and plan with section references. Acceptance criteria are verifiable pass/fail conditions only — no implementation details. Beads track work; specs define work.

#### Flaw 3 — Sherlock (research agent) positioned too late

Sherlock only ran during `/start-task` — after the spec was written and beads were created. By then, discovering that a spec assumption was wrong meant creating new tasks ad-hoc, outside the original scope.

**Fix:** Sherlock's investigation during Stage 3 now includes spec drift detection. He spot-checks the spec's Research Findings section against the current codebase and flags `SPEC_DRIFT`. Meanwhile, the new Smith agent catches assumption errors before the spec is even written.

---

## 2. New Pipeline Architecture

### Before (flat, implicit ordering)

```
PRD → Spec → Beads → Start-Task (investigate + implement) → Review → QA
```

### After (3-stage model with explicit gates)

```
Stage 1 — Product Discovery (one-shot per project)
  manifesto → /requirements (Grace) → /architecture (Ada)
  Gate: PRD APPROVED + Architecture APPROVED

Stage 2 — Specification (per phase/feature)
  /plan (Ada) → /research (Smith) → /spec (Ada + Research) → /tasks (Fernando)
  Gate: Spec APPROVED + beads created

Stage 3 — Implementation (per task)
  /investigate (Sherlock) → /do (supervisor) → /review (Linus) → /quality (Quinn)
  Gate: QA PASS → merge
```

Each stage has an orchestrator skill that sequences the atomic skills:
- `/product` — Stage 1 orchestrator
- `/specification` — Stage 2 orchestrator
- `/implementation` — Stage 3 orchestrator
- `/workflow` — Meta-orchestrator across all stages

---

## 3. Changes Made

### 3.1 New Agent

| File | Persona | Role |
|---|---|---|
| `agents/investigator.md` | Smith | Feasibility research — validates plan assumptions against real APIs, libs, codebase before spec creation |

Registered in `plugin.json` agents array.

### 3.2 Modified Agents

| Agent | Persona | Changes |
|---|---|---|
| `agents/architect.md` | Ada | Added Research Findings section to design template; prioritizes research docs; updated ref `/start-task` → `/investigate` |
| `agents/beads-owner.md` | Fernando | Reference-only beads: design = pointer only, acceptance = pass/fail only, NEVER copy spec content; updated refs `/start-task` → `/do`, `/review-task` → `/review`, `/qa-task` → `/quality` |
| `agents/research.md` | Sherlock | Added step 2.5: spot-check spec Research Findings against codebase, flag SPEC_DRIFT |
| `agents/code-reviewer.md` | Linus | Updated ref `/start-task` → `/do` |
| `agents/discovery.md` | — | Updated `/setup-project` → `/setup` |
| `agents/product-manager.md` | Grace | Updated `/architect-solution` → `/architecture` |

### 3.3 Skill Renames

| Old Name | New Name | Reason |
|---|---|---|
| `product-requirements/` | `requirements/` | Shorter, self-descriptive |
| `architect-solution/` | `architecture/` | Matches the artifact it produces |
| `plan-phase/` (was `beads-product-owner/` before that) | `plan/` | Shorter |
| `spec-phase/` | `spec/` | Shorter |
| `beads-product-owner/` | `tasks/` | Describes the output, not the agent |
| `setup-project/` | `setup/` | Shorter |
| `update-plugin/` | `update/` | Shorter |
| `review-task/` | `review/` | Shorter |
| `qa-task/` | `quality/` | Shorter, self-descriptive |

### 3.4 Skill Splits

| Old Skill | New Skills | Reason |
|---|---|---|
| `start-task/` | `investigate/` + `do/` | Investigation and implementation are distinct concerns; sometimes you want to investigate without immediately implementing |

### 3.5 Skill Merges

| Absorbed | Into | Reason |
|---|---|---|
| `create-bead-issues/` | `tasks/` (ad-hoc mode) | Single entry point for all bead creation; tasks now has two modes: full decomposition and ad-hoc |

### 3.6 Deleted Skills

| Skill | Reason |
|---|---|
| `migrate-beads/` | No longer needed |

### 3.7 New Skills

| Skill | Type | Description |
|---|---|---|
| `manifesto/` | Stage 1 atom | Create product vision, principles, governing laws |
| `investigate/` | Stage 3 atom | Dispatch Sherlock for codebase investigation before implementation |
| `do/` | Stage 3 atom | Resolve supervisor, check branch, dispatch implementation |
| `product/` | Stage 1 orchestrator | Sequences manifesto → requirements → architecture |
| `specification/` | Stage 2 orchestrator | Sequences plan → research → spec → tasks (per phase) |
| `implementation/` | Stage 3 orchestrator | Routes through investigate → do → review → quality (per task) |
| `workflow/` | Meta-orchestrator | Shows project state across all stages, suggests next step, routes to orchestrators |

### 3.8 Other Changes

| File | Change |
|---|---|
| `.claude-plugin/plugin.json` | Added `investigator.md` to agents array |
| `hooks/session-start.sh` | Updated `/update-plugin` → `/update` |

---

## 4. Tag Schema

All skills were rewritten with a standardized tag schema for consistent structure:

### Atomic Skill Tags

| Tag | Purpose |
|---|---|
| `<on-init>` | Parse arguments from user input |
| `<on-check>` | Validate prerequisites (docs exist, status APPROVED, etc.) |
| `<on-check-fail if="X">` | What to do when prerequisite X fails |
| `<on-execute>` | Main execution logic — numbered steps, dispatch calls |
| `<on-complete>` | Post-execution verification |
| `<on-complete if="condition">` | Conditional post-execution (e.g., `if="status=DRAFT"`) |
| `<on-next>` | Recommend the next skill in the pipeline |

### Orchestrator Tags (in addition to standard tags)

| Tag | Purpose |
|---|---|
| `<on-state>` | Scan artifacts and display current stage/phase state |
| `<on-step name="X">` | Define what happens at step X |
| `<on-step-skip if="X_done">` | When to skip step X (already completed) |

---

## 5. Final Skill Map (19 skills)

```
Stage 1 — Product Discovery
  atoms:        manifesto, requirements, architecture
  orchestrator: product

Stage 2 — Specification
  atoms:        plan, research, spec, tasks
  orchestrator: specification

Stage 3 — Implementation
  atoms:        investigate, do, review, quality
  orchestrator: implementation

Meta:           workflow

Infra:          setup, update, add-supervisor
Internal:       subagents-discipline
```

---

## 6. Agent Persona Map

| Agent File | Type (subagent_type) | Persona | Role |
|---|---|---|---|
| `architect.md` | architect | Ada | System design, specs, plans |
| `product-manager.md` | product-manager | Grace | PRD creation |
| `investigator.md` | investigator | Smith | Feasibility research |
| `research.md` | research | Sherlock | Codebase investigation |
| `code-reviewer.md` | code-reviewer | Linus | Code review gate |
| `qa-gate.md` | qa-gate | Quinn | QA finalization gate |
| `beads-owner.md` | beads-owner | Fernando | Bead creation and tracking |
| `discovery.md` | discovery | — | Tech stack detection |

---

## 7. Git State

**No commits have been made.** All changes are unstaged in the working tree.

### Files deleted (tracked → deleted)
- `skills/architect-solution/SKILL.md`
- `skills/beads-product-owner/SKILL.md`
- `skills/create-bead-issues/SKILL.md`
- `skills/migrate-beads/SKILL.md`
- `skills/product-requirements/SKILL.md`
- `skills/qa-task/SKILL.md`
- `skills/review-task/SKILL.md`
- `skills/setup-project/SKILL.md`
- `skills/setup-project/templates/AGENTS.md`
- `skills/setup-project/templates/BEADS-WORKFLOW.md`
- `skills/setup-project/templates/CLAUDE.md`
- `skills/start-task/SKILL.md`
- `skills/update-plugin/SKILL.md`

### Files modified (tracked)
- `.claude-plugin/plugin.json`
- `agents/architect.md`
- `agents/beads-owner.md`
- `agents/code-reviewer.md`
- `agents/discovery.md`
- `agents/product-manager.md`
- `agents/research.md`
- `hooks/session-start.sh`

### Files created (untracked)
- `agents/investigator.md`
- `skills/architecture/SKILL.md`
- `skills/do/SKILL.md`
- `skills/implementation/SKILL.md`
- `skills/investigate/SKILL.md`
- `skills/manifesto/SKILL.md`
- `skills/plan/SKILL.md`
- `skills/product/SKILL.md`
- `skills/quality/SKILL.md`
- `skills/requirements/SKILL.md`
- `skills/research/SKILL.md`
- `skills/review/SKILL.md`
- `skills/setup/SKILL.md`
- `skills/setup/templates/AGENTS.md`
- `skills/setup/templates/BEADS-WORKFLOW.md`
- `skills/setup/templates/CLAUDE.md`
- `skills/spec/SKILL.md`
- `skills/specification/SKILL.md`
- `skills/tasks/SKILL.md`
- `skills/update/SKILL.md`
- `skills/workflow/SKILL.md`

### Templates preserved (moved with directory rename)
- `skills/setup/templates/AGENTS.md` (from `skills/setup-project/templates/`)
- `skills/setup/templates/BEADS-WORKFLOW.md` (from `skills/setup-project/templates/`)
- `skills/setup/templates/CLAUDE.md` (from `skills/setup-project/templates/`)

---

## 8. Review Checklist

Before committing, verify:

- [ ] All 19 skill directories exist with SKILL.md files
- [ ] All skills use the standardized tag schema
- [ ] No references to old skill names remain (`start-task`, `review-task`, `qa-task`, `create-bead-issues`, `product-requirements`, `architect-solution`, `beads-product-owner`, `setup-project`, `update-plugin`, `spec-phase`, `plan-phase`, `migrate-beads`)
- [ ] `plugin.json` includes `investigator.md` in agents array
- [ ] `investigator.md` has persona "Smith" (not "Investigator")
- [ ] `beads-owner.md` enforces reference-only beads (no spec content in bead fields)
- [ ] `architect.md` includes Research Findings section and prioritizes research docs
- [ ] `research.md` (Sherlock) includes spec drift detection (step 2.5)
- [ ] Stage orchestrators (`product`, `specification`, `implementation`) sequence their atoms correctly
- [ ] `/workflow` references orchestrators and provides both guided and direct dispatch options
- [ ] `setup/templates/` directory exists with AGENTS.md, BEADS-WORKFLOW.md, CLAUDE.md
- [ ] Cross-references between agents and skills are consistent
- [ ] README.md still needs updating (not done in this refactor)

---

## 9. Pending Work

- [ ] **README.md** — update with new skill names, structure, and pipeline diagram
- [ ] **Functional testing** — install plugin in a test project and verify each skill dispatches correctly
- [ ] **Version bump** — update version in `plugin.json` and `setup/SKILL.md` Step 5
