---
name: spec
description: Create a detailed technical spec grounded in validated research. Dispatches Ada with PRD + Plan + Research as inputs. Only after plan and research exist.
user_invocable: true
---

# Spec

Create a detailed technical specification from an approved plan, validated by research.

---

<on-init>
If the user provides $ARGUMENTS, analyze them for:
- A plan path
- A PRD path
- Specific focus areas or constraints
</on-init>

<on-check>
1. **Plan must exist and be APPROVED.** Ask the user for the plan path (e.g., `docs/plans/02-plan-mcp-complete.md`). Read to confirm.
2. **Research docs should exist.** Determine the phase number from the plan filename (e.g., `02`). Search for `docs/research/{NN}-research-*.md`.
3. **PRD must exist.** Ask the user for the PRD path (e.g., `docs/PRD.md`). Read to confirm.
</on-check>

<on-check-fail if="plan">
No plan found. Recommend running `/plan` first.
</on-check-fail>

<on-check-fail if="research">
Warn: "No research docs found for this phase. The spec will be based on unvalidated assumptions from the plan. This historically causes drift during implementation."

Ask: "Do you want to run `/research` first, or proceed without research?"
- If user wants research → stop and recommend `/research`
- If user proceeds → include this warning in the dispatch prompt
</on-check-fail>

<on-check-fail if="prd">
No PRD found. Recommend running `/requirements` first.
</on-check-fail>

<on-execute>
1. **List research findings:**
   - If research docs found, read them and list for the user
   - Confirm which docs to include in the dispatch

2. **Define output location:**
   - Suggest default: `docs/specs/{NN}-spec-{feature-kebab}.md`
   - Ensure the `docs/specs/` directory exists (create if needed)

3. **Dispatch** using **exactly** these parameters — no more, no less:

   ```python
   Task(
       subagent_type="architect",
       prompt="Create a detailed TECHNICAL SPEC for the plan at {plan_path}. PRD for context: {prd_path}. Research findings (MUST READ before designing): {research_paths_comma_separated}. The research docs contain validated assumptions — your design MUST align with the confirmed findings and address any contradictions or risks identified. Do NOT re-assume what research already validated or contradicted. If research contradicted a plan assumption, design the spec around the reality documented in the research, not the original plan assumption. Save to {spec_path} with status DRAFT. Iterate with the user until APPROVED."
   )
   ```

   **Do NOT add extra parameters** unless the user explicitly requests it.
</on-execute>

<on-complete>
1. Verify the spec file was created at the agreed path
2. Show the user the status from Ada's report (DRAFT or APPROVED)
</on-complete>

<on-complete if="status=DRAFT">
Inform the user they can continue iterating with Ada.
</on-complete>

<on-next>
Recommend proceeding with `/tasks` to decompose the spec into trackable issues.
</on-next>
