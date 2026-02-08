---
name: jira-cli
description: Interact with Jira from the command line using ankitpokhrel/jira-cli. Use when the user wants to create, update, list, link, or comment on Jira issues via the CLI, or when installing or configuring jira-cli.
metadata:
  author: Deerhide
  version: 1.0.0
---

# Jira CLI

This skill guides the agent to interact with Jira using [ankitpokhrel/jira-cli](https://github.com/ankitpokhrel/jira-cli), a Go-based command-line tool. All actions are performed by running `jira` commands in the terminal. For scripts or non-interactive use, prefer `--plain` for list output and `--no-input` for create/edit where applicable.

**NOTE:** This skill is for terminal/script usage with jira-cli. For writing epics and user stories (content and structure), use [jira-epics-stories](../jira-epics-stories/SKILL.md); that skill uses jira-cli to create/update issues in Jira.

## When to Use

- User or agent wants to create, update, list, link, or comment on Jira issues from the command line.
- User or agent asks to install or configure jira-cli.
- Trigger terms: jira-cli, jira CLI, ankitpokhrel jira, create Jira issue, list Jira issues, comment on Jira ticket, link Jira issues, configure jira-cli.

## Quick Orientation

- **List issues:** `jira issue list` (add flags like `-s "To Do"`, `-a $(jira me)`, `--plain` for scriptable output).
- **View single issue:** `jira issue view ISSUE-KEY` — fetch issue details by key.
- **Create issue:** `jira issue create` (interactive) or with `-t`, `-s`, `-b` and `--no-input`.
- **Edit issue:** `jira issue edit ISSUE-KEY` with field flags.
- **Comment:** `jira issue comment add ISSUE-KEY "body"`.
- **Link issues:** `jira issue link ISSUE-1 ISSUE-2 <link type>` (e.g. Blocks).

## References

- **Installation and configuration:** [references/install-and-configure.md](references/install-and-configure.md) — install options (Docker, Homebrew, Scoop, etc.) and setup (Cloud/On-premise, `jira init`, config file, multiple projects).
- **Commands (create, update, comment, link, list):** [references/commands.md](references/commands.md) — exact commands and flags for listing, creating, editing, commenting, and linking issues.
