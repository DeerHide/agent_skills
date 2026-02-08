---
name: jira-epics-stories
description: Writes epics and user stories with acceptance criteria; creates or updates them in Jira via jira-cli. Use when the user or agent requests epics, user stories, backlog refinement, story breakdown, acceptance criteria, or mentions Jira, story points, or "As a… I want… So that…".
metadata:
  author: Deerhide
  version: 1.0.0
---

# Writing Epics and User Stories (Jira)

This skill guides agents in writing well-structured epics and user stories and in creating or updating them in Jira using [jira-cli](../jira-cli/SKILL.md).

## When to Use

- User or parent agent asks for epics, user stories, backlog refinement, story breakdown, or acceptance criteria.
- User or agent mentions Jira in the context of planning, backlog, or issue creation.
- Trigger terms: epic, user story, task, backlog, acceptance criteria, story points, Jira, jira-cli, "As a… I want… So that…".

## Epic Structure

Each epic **SHOULD** be scoped to a single theme or outcome. Use this structure:

- **Title:** Short, clear epic title.
- **Goal:** One-sentence goal for the epic.
- **Scope:** What is in scope and out of scope.
- **Success outcomes:** List of measurable outcomes.
- **Stories:** Optional list of story titles or Jira keys (after stories are defined).

## User Story Structure

Each user story **MUST** have at least one acceptance criterion. Use this structure:

- **Title:** Short story title.
- **As a** [role], **I want** [action/capability] **so that** [benefit].
- **Acceptance criteria:** Testable conditions (see below).
- **Story points:** Optional, only if requested.

## Acceptance Criteria

- Acceptance criteria **MUST** be testable and verifiable.
- **SHOULD** use Given/When/Then or checklist form where useful.

**IMPORTANT:** Acceptance criteria must be testable. Avoid vague or subjective wording; each criterion should be demonstrably pass/fail.

Examples:

- Given [context], when [action], then [observable result].
- Checklist: "User can save draft"; "Saved draft appears in list".

## Jira Concepts

- **Project key:** Taken from current context or project config. All created/updated issues belong to this project.
- **Issue types:** Use the type that matches the artifact:
  - **Epic** for epics.
  - **Story** for user stories.
  - **Task** for tasks (sub-items of stories when your workflow uses them).

When creating issues via jira-cli, use the issue type appropriate to the hierarchy (epic → story → task).

## Jira CLI Integration

When **jira-cli** is installed and configured:

- Use it to **create** and **update** issues (epics, stories, tasks) in the project specified for the current context. See [jira-cli](../jira-cli/SKILL.md) and its references: [jira-cli/references/commands.md](../jira-cli/references/commands.md) (create, edit, list, comment, link) and [jira-cli/references/install-and-configure.md](../jira-cli/references/install-and-configure.md) (setup).

When jira-cli is **not** available:

- Produce the full epic/story/task content in the agreed format (epic structure and user story structure above) so the user can create or update issues manually or via another integration.

**IMPORTANT:** When jira-cli is configured, use it to create and update epics, stories, and tasks in the project specified for the context.

## Output Format

Use a consistent structure for each epic and user story.

**Epic:**

- **Title:** [Short epic title]
- **Goal:** [One sentence goal]
- **Scope:** [What is in/out of scope]
- **Success outcomes:** [List of measurable outcomes]
- **Stories:** [List of story titles or keys]

**User story:**

- **Title:** [Short story title]
- **As a** [role], **I want** [action/capability] **so that** [benefit].
- **Acceptance criteria:**
  - Given [context], when [action], then [observable result].
  - [Or checklist form.]
- **Story points:** [Optional, if requested]

For copy-paste templates, see [assets/templates.md](assets/templates.md).

## Callouts

- **IMPORTANT:** Acceptance criteria must be testable.
- **IMPORTANT:** When jira-cli is configured, use it to create/update epics, stories, and tasks in the project specified for the context.
