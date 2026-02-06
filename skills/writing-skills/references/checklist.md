# Skill Authoring Checklist

Use this checklist before publishing or sharing an Agent Skill. It combines requirements from the Agent Skills spec, Cursor create-skill, and Claude/Anthropic best practices.

## Contents

- [Core quality](#core-quality)
- [Structure and references](#structure-and-references)
- [Natural language and clarity](#natural-language-and-clarity)
- [Scripts and code](#scripts-and-code)
- [Testing and iteration](#testing-and-iteration)

---

## Core quality

- [ ] **Description is specific** and includes key terms (file types, actions, domain words)
- [ ] **Description includes both WHAT and WHEN** (capabilities + trigger scenarios)
- [ ] **Description is in third person** (no "I" or "You can use this")
- [ ] **SKILL.md body is under 500 lines**; extra content is in `references/`, `scripts/`, or `assets/`
- [ ] **No time-sensitive information** in the main flow (or deprecated content is in a separate "Old patterns" section)
- [ ] **Consistent terminology** throughout (one term per concept)
- [ ] **Examples are concrete** (real input/output), not abstract

---

## Structure and references

- [ ] **File references are one level deep** from SKILL.md (no SKILL → A → B chains)
- [ ] **Progressive disclosure** is used: essentials in SKILL.md, details in linked files
- [ ] **Workflows have clear steps** (numbered or checklist)
- [ ] **Long reference files** (~100+ lines) have a table of contents at the top
- [ ] **Directory and file names** are descriptive (e.g. `reference/finance.md`, not `doc2.md`)

---

## Natural language and clarity

- [ ] **Requirement strength is explicit** where it matters: MUST for hard requirements, SHOULD for recommendations, MAY for optional
- [ ] **Imperative phrasing** is used for steps ("Run X", "Always do Y") instead of vague suggestions
- [ ] **Callouts** (IMPORTANT, WARNING, NOTE, CRITICAL) are used for non-obvious or critical instructions where appropriate
- [ ] **RFC 2119 keywords** (MUST, SHOULD, MAY, etc.) are used sparingly and consistently

---

## Scripts and code

- [ ] **Scripts solve problems** rather than punting to the agent (explicit error handling, no "let the agent figure it out")
- [ ] **Error messages** from scripts are helpful and specific
- [ ] **Constants and config** are justified in comments (no unexplained "magic" values)
- [ ] **Required packages/tools** are listed in the skill and verified as available in the target environment
- [ ] **Execution vs reference** is clear: agent should "run" the script or "read" it as reference
- [ ] **No Windows-style paths** (use forward slashes only)
- [ ] **Validation or verification steps** are specified for critical or destructive operations
- [ ] **Feedback loops** (validate → fix → repeat) are included for quality-critical tasks
- [ ] **MCP tool references** use fully qualified names (`ServerName:tool_name`) when applicable

---

## Testing and iteration

- [ ] **At least a few evaluation scenarios** are defined (representative tasks + expected behavior)
- [ ] **Skill is tested with the model(s)** you plan to use (e.g. Haiku, Sonnet, Opus)
- [ ] **Skill is tested with real usage** (not only synthetic prompts)
- [ ] **Team or user feedback** is incorporated when applicable
- [ ] **Agent navigation** has been observed: correct files are read, critical steps are not skipped, links are followed as intended

---

## Frontmatter quick check

- [ ] `name`: 1–64 chars, lowercase letters, numbers, hyphens only; matches directory name; no reserved words ("anthropic", "claude")
- [ ] `description`: 1–1024 chars, non-empty, no XML tags
- [ ] Optional fields (`license`, `compatibility`, `metadata`, `allowed-tools`) are correct if present
