---
name: writing-skills
description: Guides authors through writing effective Agent Skills (SKILL.md). Use when creating or editing skills, or when asked about skill structure, best practices, natural language strength (MUST/SHOULD/MAY), or the SKILL.md format.
metadata:
  author: Deerhide
  version: 1.0.0
---

# Writing Agent Skills

This skill consolidates recommendations from the [Agent Skills specification](https://agentskills.io/specification), Cursor's create-skill guidance, and Claude/Anthropic best practices. Use it when authoring or reviewing skills.

## When to Use This Skill

- Creating or editing an Agent Skill (SKILL.md and supporting files)
- Questions about skill structure, frontmatter, or the SKILL.md format
- Questions about skill authoring best practices (Claude or Cursor)
- Choosing how strongly to phrase requirements (MUST, SHOULD, imperative, callouts)

## Skill Format (Spec)

A skill is a directory with at least a `SKILL.md` file:

```
skill-name/
├── SKILL.md          # Required: frontmatter + markdown body
├── references/       # Optional: docs loaded on demand
├── scripts/          # Optional: executable code
└── assets/           # Optional: templates, examples
```

**Frontmatter (required):**

- `name`: 1–64 chars, lowercase letters, numbers, hyphens only. Must not start/end with hyphen or contain `--`. Must match directory name. Cannot contain "anthropic" or "claude" (Cursor/Claude).
- `description`: 1–1024 chars, non-empty. Describe **what** the skill does and **when** to use it. No XML tags.

**Optional frontmatter:** `license`, `compatibility`, `metadata` (key-value map), `allowed-tools` (space-delimited; experimental).

**Body:** Markdown after the frontmatter. No format mandate; use step-by-step instructions, examples, and edge cases. Keep under 500 lines; use progressive disclosure for more.

---

## Natural Language Strength

Use clear requirement levels and callouts so the agent (and humans) know what is mandatory vs optional.

### RFC 2119 Keywords

Reserve these for real requirements; use sparingly.

| Keyword | Meaning | Use when |
|---------|---------|----------|
| **MUST** / REQUIRED / SHALL | Absolute requirement | Non-negotiable rules (e.g. "Breaking changes MUST be in the footer") |
| **MUST NOT** / SHALL NOT | Absolute prohibition | Things that must never be done |
| **SHOULD** / RECOMMENDED | Recommended; exceptions allowed if justified | Best practices, preferred behavior |
| **SHOULD NOT** / NOT RECOMMENDED | Discouraged; allowed only with good reason | Avoid unless necessary |
| **MAY** / OPTIONAL | Truly optional | Choice left to the agent or user |

**IMPORTANT**: Use MUST/SHALL only where interoperability or safety demands it. Prefer SHOULD for guidance so the agent can adapt when context warrants.

**Examples in skills:**

- Good: "Breaking changes **MUST** be indicated in the commit footer."
- Good: "Every commit **SHOULD** start with a ticket reference when applicable."
- Weak: "It's a good idea to validate before merging." → Prefer: "**SHOULD** validate with `scripts/validate.py` before merging."

### Imperative Phrasing

Prefer direct imperatives for steps:

- **Good:** "Run `scripts/validate.py` after editing."
- **Good:** "Always filter out test accounts in reports."
- **Avoid:** "You might want to run the validator." or "It's good to filter test accounts."

Use imperatives for sequential steps and for rules you want followed consistently.

### Callouts (IMPORTANT, ATTENTION, WARNING, NOTE, CRITICAL)

Use block-level or inline callouts to highlight critical or non-obvious information:

| Callout | When to use | Example |
|---------|-------------|---------|
| **IMPORTANT** | Must-not-miss rule or constraint | "**IMPORTANT**: Never create skills in `~/.cursor/skills-cursor/`." |
| **ATTENTION** | Draw focus to a decision or pitfall | "**ATTENTION**: This step is irreversible." |
| **WARNING** | Risk or side effect | "**WARNING**: The script overwrites existing files." |
| **NOTE** | Clarification or context | "**NOTE**: Use forward slashes in paths on all platforms." |
| **CRITICAL** | Safety or correctness requirement | "**CRITICAL**: Only proceed when validation passes." |

Reserve CRITICAL/IMPORTANT for requirements; use NOTE for helpful context.

---

## Discovery and Descriptions

The description is loaded at startup for all skills; the agent uses it to decide when to apply the skill.

- **Third person only.** The description is injected into the system prompt.
  - Good: "Processes Excel files and generates reports."
  - Avoid: "I can help you process Excel files." / "You can use this to process Excel files."
- **WHAT + WHEN.** State capabilities and trigger scenarios.
- **Trigger terms.** Include concrete keywords (file types, actions, domain terms) so the agent can match user requests.
- **Naming.** Prefer gerund form: `processing-pdfs`, `analyzing-spreadsheets`. Avoid vague names: `helper`, `utils`, `tools`.

**Example description:**

```yaml
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
```

---

## Core Authoring Principles

1. **Concise is key.** The context window is shared. Only add what the agent does not already know. Challenge every paragraph: "Does the agent really need this?"
2. **Keep SKILL.md under 500 lines.** Put detailed material in `references/` and link from SKILL.md.
3. **Progressive disclosure.** Put essential instructions in SKILL.md; link to references/scripts/assets that are loaded or run only when needed.
4. **References one level deep.** Link directly from SKILL.md to files (e.g. `references/guide.md`). Avoid chains (SKILL → A → B); deep nesting can lead to partial reads.
5. **Degrees of freedom:** Match specificity to task fragility.
   - **High:** Multiple valid approaches (e.g. code review) — use text instructions.
   - **Medium:** Preferred pattern with acceptable variation — use templates or parameterized scripts.
   - **Low:** Fragile or critical sequence — use exact commands and strict steps.

---

## Structure and Patterns

- **High-level guide + references:** Overview and quick start in SKILL.md; link to `references/` for details (e.g. "See [reference.md](references/reference.md) for the full API.").
- **Workflows:** Break complex tasks into numbered steps; optionally provide a checklist the agent can track.
- **Feedback loops:** For quality-critical tasks, specify validate → fix → repeat (e.g. "Run `scripts/validate.py`; only proceed when it passes.").
- **Templates:** Provide output templates when format matters (e.g. commit message format, report structure).
- **Examples:** Use input/output pairs for style-sensitive tasks (e.g. commit messages, report formats).
- **Conditional workflows:** Branch by context (e.g. "Creating new content? → Follow Creation workflow. Editing? → Follow Editing workflow.").

For reference files over ~100 lines, add a table of contents at the top so the agent can navigate or partially read effectively.

---

## Scripts and References

- **Scripts:** Pre-made scripts are often more reliable than generated code, save tokens, and ensure consistency. State whether the agent should **execute** the script (typical) or **read** it as reference.
- **Solve, don't punt:** Scripts should handle errors and edge cases explicitly; avoid "let the agent figure it out" on failure.
- **Paths:** Use forward slashes only (e.g. `scripts/helper.py`), including on Windows.
- **Dependencies:** List required packages or tools in the skill; do not assume they are installed.
- **MCP tools:** If the skill references MCP tools, use fully qualified names: `ServerName:tool_name`.

---

## Anti-Patterns

- **Windows-style paths:** Use `scripts/helper.py`, not `scripts\helper.py`.
- **Too many options:** Give one default path; add an escape hatch only when needed (e.g. "Use pdfplumber; for OCR use pdf2image with pytesseract.").
- **Time-sensitive text:** Avoid "Before August 2025 use X." Prefer a "Current method" section and an "Old patterns (deprecated)" section in `<details>` if needed.
- **Inconsistent terminology:** Pick one term per concept (e.g. "API endpoint" or "field") and use it throughout.
- **Vague skill names:** Prefer `processing-pdfs`, `analyzing-spreadsheets` over `helper`, `utils`, `tools`.
- **Deep reference chains:** Keep links one level deep from SKILL.md.

---

## Process and Quality

- **Creation workflow:** Discovery (purpose, triggers, location) → Design (name, description, sections) → Implementation (SKILL.md, references, scripts) → Verification (description, length, terminology, references).
- **Evaluation-first:** Define representative tasks and expected behavior before writing long docs; iterate so the skill fixes real gaps.
- **Iterate with the agent:** Use one instance to author/refine the skill and another to test it; refine based on where the agent struggles or mis-navigates.
- **Test across models:** If the skill will be used with multiple models (e.g. Haiku, Sonnet, Opus), test with each; balance clarity vs brevity.

---

## Checklist

Before publishing a skill, run through the full checklist:

- **Pre-publish checklist:** See [references/checklist.md](references/checklist.md) for a detailed verification list (core quality, structure, scripts, testing).
