---
name: plan
description: Create a phase/feature plan that scopes work, defines high-level tasks, and identifies dependencies. Dispatches Ada for planning.
user_invocable: true
---

# Plan

Create a phase or feature plan that scopes work and identifies dependencies for research and specification.

---

<on-init>
If the user provides $ARGUMENTS, analyze them for:
- A phase number or feature name
- Existing PRD/architecture paths
</on-init>

<on-check>
1. **PRD must exist and be APPROVED.** Ask the user for the PRD path (e.g., `docs/PRD.md`). Read to confirm.
2. **Architecture doc should exist.** Ask the user for the architecture path (e.g., `docs/ARCHITECTURE.md`).
</on-check>

<on-check-fail if="prd">
No PRD found. Recommend running `/requirements` first.
</on-check-fail>

<on-check-fail if="architecture">
No architecture doc found. Warn that planning without architecture may lead to structural issues. Recommend running `/architecture` first, or proceed with caution.
</on-check-fail>

<on-execute>
1. **Define phase scope:**
   - Ask the user: "What phase/feature is this plan for?" (e.g., "Phase 02 — MCP Complete")
   - Ask for the phase number (e.g., `02`)

2. **Define output location:**
   - Suggest default: `docs/plans/{NN}-plan-{feature-kebab}.md`
   - Ensure the `docs/plans/` directory exists (create if needed)

3. **Dispatch** using **exactly** these parameters — no more, no less:

   ```python
   Agent(
       subagent_type="architect",
       prompt="Create a PHASE PLAN (not a spec) for: {phase_description}. Read the PRD at {prd_path} and architecture at {arch_path} for context. This is a planning document that defines: scope (what's in/out for this phase), high-level task breakdown, dependencies between tasks, external dependencies and APIs that will need research, and acceptance criteria for the phase. Save to {plan_path} with status DRAFT. Do NOT write implementation specs — that comes after research validates the plan's assumptions. Iterate with the user until APPROVED."
   )
   ```

   **Do NOT add extra parameters** unless the user explicitly requests it.
</on-execute>

<on-complete>
1. Verify the plan file was created at the agreed path
2. Show the user the status from Ada's report (DRAFT or APPROVED)
</on-complete>

<on-complete if="status=DRAFT">
Inform the user they can continue iterating with Ada.
</on-complete>

<on-next>
Recommend proceeding with `/research` to validate the plan's technical assumptions before creating the spec.
</on-next>
