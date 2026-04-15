---
name: requirements
description: Transform a raw idea into a structured PRD (Product Requirements Document). Dispatches Grace (product-manager) to elicit, structure, and validate requirements.
user_invocable: true
---

# Requirements

Create a structured Product Requirements Document from a raw idea or concept.

---

<on-init>
If the user provides $ARGUMENTS, analyze them for:
- A raw idea or concept description
- An existing PRD path to review/iterate
- Reference documents (briefs, notes, competitive analysis)
</on-init>

<on-check>
No strict prerequisites — this is typically the first skill in Stage 1 after `/manifesto`.

If a manifesto exists at `docs/MANIFESTO.md`:
- Read it for context — the PRD should align with the manifesto's principles and governing laws.
</on-check>

<on-execute>
1. **Gather context:**
   - Ask the user if they have any existing documents about the idea (briefs, notes, sketches, competitive analysis)
   - If documents exist, read them and include their paths in the dispatch prompt

2. **Define output location:**
   - Ask the user where the PRD should be saved
   - Suggest default: `docs/prd/PRD-{feature-name-kebab-case}.md`
   - Ensure the parent directory exists (create if needed)

3. **Dispatch** using **exactly** these parameters — no more, no less:

   ```python
   Task(
       subagent_type="product-manager",
       prompt="Create a PRD for the requested feature/product. Save the PRD to {agreed_path}. Context: {user_idea}. Reference documents: {doc_paths_if_any}"
   )
   ```

   **Do NOT add extra parameters** unless the user explicitly requests it.
</on-execute>

<on-complete>
1. Verify the PRD file was created at the agreed path
2. Show the user the status from Grace's report (DRAFT or APPROVED)
</on-complete>

<on-complete if="status=DRAFT">
Inform the user they can continue iterating with Grace by running `/requirements` again or editing directly.
</on-complete>

<on-next>
Recommend proceeding with `/architecture` referencing the PRD path.
</on-next>
