---
name: manifesto
description: Guide the creation of a product manifesto — vision, principles, and governing laws that shape all downstream decisions.
user_invocable: true
---

# Manifesto

Guide the user through defining the product's vision, principles, and governing laws. The manifesto is the foundation that PRD, architecture, and all downstream documents reference.

---

<on-init>
If the user provides $ARGUMENTS, analyze them for:
- A product name or concept
- An existing manifesto path to review/iterate

Check if a manifesto already exists:
- Search for `docs/MANIFESTO.md` or `MANIFESTO.md`
- If found, ask the user: "A manifesto already exists at {path}. Do you want to review and iterate on it, or start fresh?"
</on-init>

<on-check>
No strict prerequisites — the manifesto is the first artifact in the pipeline.

If a PRD already exists but no manifesto:
- Inform: "A PRD exists but no manifesto was found. The manifesto defines the governing principles that the PRD should align with. Creating it now will provide a foundation for reviewing the PRD."
</on-check>

<on-execute>
1. **Define output location:**
   - Suggest default: `docs/MANIFESTO.md`
   - Ensure the `docs/` directory exists (create if needed)

2. **Guide the user through these sections:**

   **Vision** — What does this product exist to do? One sentence.

   **Principles** — 3-7 guiding principles that shape every decision.
   Example: "GitHub stores, Rust computes — zero custom storage"

   **Governing Laws** — Non-negotiable rules. If a design violates a law, the design is wrong.
   Example: "Every write invalidates and recomputes — consistency after mutations"

   **Out of Scope** — What this product will never do. Explicit boundaries.

3. **Write the manifesto** to the agreed path using this structure:

   ```markdown
   # {Product Name} — Manifesto

   **Status:** DRAFT | APPROVED
   **Date:** {date}

   ## Vision
   {one sentence}

   ## Principles
   1. {principle} — {why}
   2. ...

   ## Governing Laws
   1. {law} — {consequence if violated}
   2. ...

   ## Out of Scope
   - {what this product will never do}
   ```

4. **Iterate** with the user until they approve
5. Update status to APPROVED
</on-execute>

<on-complete>
1. Verify the manifesto file was created at the agreed path
2. Show the user the status (DRAFT or APPROVED)
</on-complete>

<on-complete if="status=DRAFT">
Inform the user they can continue editing the manifesto directly or re-run `/manifesto` to iterate.
</on-complete>

<on-next>
Recommend proceeding with `/requirements` to create the PRD, referencing the manifesto as the governing document.
</on-next>
