---
name: architecture
description: Create high-level product architecture — system design, tech stack, structural decisions. Stage 1 only. For phase specs use /spec.
user_invocable: true
---

# Architecture

Create high-level product architecture and system design from an approved PRD.

---

<on-init>
If the user provides $ARGUMENTS, analyze them for:
- A PRD path
- A specific scope or focus area
</on-init>

<on-check>
**CRITICAL**: A product requirement (PRD) must exist and be APPROVED.

1. Ask the user for the PRD path (e.g., `docs/prd/PRD-{name}.md`)
2. Read the PRD to confirm it exists and its status is APPROVED
</on-check>

<on-check-fail if="prd">
No PRD found. Recommend running `/requirements` first.
</on-check-fail>

<on-execute>
1. **Define output location:**
   - Ask the user where the architecture doc should be saved
   - Suggest default: `docs/ARCHITECTURE.md`
   - Ensure the parent directory exists (create if needed)

2. **Dispatch** using **exactly** these parameters — no more, no less:

   ```python
   Agent(
       subagent_type="architect",
       prompt="Create high-level product architecture for the requested solution. Read the PRD at {prd_path} as your input requirements. This is a Stage 1 architecture document — focus on system design, tech stack, crate/package structure, and key design decisions. Do NOT write phase-level implementation specs (that's /spec). Save the architecture document to {arch_path} with status DRAFT. Iterate with the user until APPROVED."
   )
   ```

   **Do NOT add extra parameters** unless the user explicitly requests it.
</on-execute>

<on-complete>
1. Verify the architecture file was created at the agreed path
2. Show the user the status from Ada's report (DRAFT or APPROVED)
</on-complete>

<on-complete if="status=DRAFT">
Inform the user they can continue iterating with Ada.
</on-complete>

<on-next>
Stage 1 complete. Recommend proceeding to Stage 2 with `/plan` to define the first phase.
</on-next>
