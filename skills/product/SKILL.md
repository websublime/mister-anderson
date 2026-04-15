---
name: product
description: "Stage 1 orchestrator — guides Product Discovery: manifesto → requirements → architecture. Scans artifacts, skips completed steps, dispatches sub-skills in sequence."
user_invocable: true
---

# Product (Stage 1 Orchestrator)

Guide the user through Stage 1 — Product Discovery. Sequences the atomic skills and tracks progress.

---

<on-init>
If the user provides $ARGUMENTS, analyze them for:
- `status` — show current stage state only
- A specific step name to jump to (e.g., `architecture`)
</on-init>

<on-state>
Scan the filesystem to determine Stage 1 state:

1. **Manifesto**: check for `docs/MANIFESTO.md`
2. **PRD**: check for `docs/PRD.md` or `docs/prd/*.md` — read for `Status: APPROVED`
3. **Architecture**: check for `docs/*architecture*.md` or `docs/ARCHITECTURE.md` — read for `Status: APPROVED`

Display:
```
Stage 1 — Product Discovery
  {check} Manifesto     {path or "not found"}
  {check} PRD           {path} ({status})
  {check} Architecture  {path} ({status})
```

Where `{check}` is:
- `[done]` — artifact exists and is APPROVED
- `[exists]` — artifact exists but not yet APPROVED
- `[missing]` — not found
- `[warning]` — missing but a later step was already done
</on-state>

<on-step name="manifesto">
**Manifesto** — Product vision, principles, governing laws.

This is typically a manual step — the user writes it directly.

Ask: "Do you have a manifesto, or would you like help creating one with `/manifesto`?"
- If manifesto exists → show path, proceed to next step
- If user wants help → dispatch: `Skill(skill="manifesto")`
- If user wants to skip → warn this is optional but recommended, proceed
</on-step>

<on-step-skip if="manifesto_done">
Manifesto already exists at `{path}`. Moving to next step.
</on-step-skip>

<on-step name="requirements">
**PRD** — Product Requirements Document.

Dispatch: `Skill(skill="requirements")`

Wait for completion, then re-scan state.
</on-step>

<on-step-skip if="requirements_done">
PRD already exists and is APPROVED at `{path}`. Moving to next step.
</on-step-skip>

<on-step name="architecture">
**Architecture** — High-level system design, tech stack, structural decisions.

Dispatch: `Skill(skill="architecture")`

Wait for completion, then re-scan state.
</on-step>

<on-step-skip if="architecture_done">
Architecture already exists and is APPROVED at `{path}`. Moving to next step.
</on-step-skip>

<on-complete>
Re-scan and display final Stage 1 state.

```
Stage 1 — Product Discovery: COMPLETE
  [done] Manifesto     {path}
  [done] PRD           {path} (APPROVED)
  [done] Architecture  {path} (APPROVED)
```
</on-complete>

<on-next>
Stage 1 complete. Recommend proceeding to Stage 2 with `/specification` or `/plan` to define the first phase.
</on-next>
