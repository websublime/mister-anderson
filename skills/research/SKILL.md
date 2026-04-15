---
name: research
description: Validate technical assumptions from the plan against real APIs, libraries, and codebase before spec creation. Dispatches Smith to produce structured research docs.
user_invocable: true
---

# Research

Validate technical assumptions from the plan against real APIs, libraries, and codebase before writing the spec.

---

<on-init>
If the user provides $ARGUMENTS, analyze them for:
- A plan path
- Specific APIs, libraries, or assumptions to focus on
</on-init>

<on-check>
1. **Plan must exist.** Ask the user for the plan path (e.g., `docs/plans/01-plan-mcp-foundation.md`). Read to confirm.
2. **PRD must exist.** Ask the user for the PRD path (e.g., `docs/PRD.md`). Read to confirm.
</on-check>

<on-check-fail if="plan">
No plan found. Recommend running `/plan` first.
</on-check-fail>

<on-check-fail if="prd">
No PRD found. Recommend running `/requirements` first.
</on-check-fail>

<on-execute>
1. **Define output location:**
   - Determine the phase number from the plan filename (e.g., `01` from `01-plan-*`)
   - Ask the user for the research topic (e.g., `github-dependencies-api`)
   - Suggest default path: `docs/research/{NN}-research-{topic-kebab}.md`
   - If multiple research docs needed for the same phase, use distinct topics (e.g., `01-research-github-api.md`, `01-research-projects-v2.md`)
   - Ensure the `docs/research/` directory exists (create if needed)

2. **Identify focus areas (optional):**
   - Ask the user: "Are there specific APIs, libraries, or assumptions you want Smith to focus on? Or should he extract all assumptions from the plan?"

3. **Dispatch** using **exactly** these parameters — no more, no less:

   ```python
   Agent(
       subagent_type="investigator",
       prompt="Research technical feasibility for the plan at {plan_path}. PRD for context: {prd_path}. Save the research document to {research_path}. {focus_areas_or_empty}Read the plan to extract all technical assumptions and external dependencies, then validate each one against real documentation and the existing codebase."
   )
   ```

   **Do NOT add extra parameters** unless the user explicitly requests it.
</on-execute>

<on-complete>
1. Verify the research doc was created at the agreed path
2. Show the user Smith's report summary: how many assumptions confirmed/contradicted
</on-complete>

<on-complete if="contradictions_found">
Present each contradiction clearly. Ask: "These contradictions need to be resolved before creating the spec. Do you want to adjust the plan first, or proceed to `/spec` with these known issues?"
</on-complete>

<on-next>
Recommend proceeding with `/spec` referencing the plan and research doc.
</on-next>
