---
name: commit
description: >
  Orchestrates preparing and creating one or more logical commits: inspects
  unstaged and staged changes, groups them into atomic commits with
  Conventional Commit messages, updates the CHANGELOG Unreleased section for
  the work, activates any virtualenv, and MUST install git hooks via
  `pre-commit install` before commit or push so local verification matches CI.
  Use when the user asks to commit work, prepare commits, push, or update the
  changelog for current changes without cutting a release.
metadata:
  tags:
    - git
    - commit
    - changelog
    - pre-commit
    - workflow
---

# Commit workflow

This skill defines a repeatable workflow for preparing and creating commits:
inspect the current git state, group changes into atomic logical commits with
Conventional Commit messages, update `CHANGELOG.md` under the `[Unreleased]`
section to describe the work, activate any local virtualenv, and **install**
pre-commit git hooks (not merely assume they exist) so commit-msg / lint /
format checks run locally before anything is pushed. Commit messages, changelog
structure, and mapping from commits to changelog entries follow the
[git](/home/miragecentury/.claude/skills/git/SKILL.md) skill. Version bumping,
comparison links, and tagging remain the responsibility of the `release` skill.

## When to use

- User asks to commit, save work, or prepare commits from the current branch.
- User wants help splitting changes into one or more logical commits with
  Conventional Commit messages.
- User asks to push (or create a PR that pushes) — still run Phase 3 + Phase 6
  so hooks are installed and local verification runs before CI.
- User wants `CHANGELOG.md` updated under `[Unreleased]` to reflect new work,
  without bumping the version or creating a tag.
- Before running the `release` workflow, to ensure current work is committed
  and reflected in the Unreleased changelog section.

**Trigger terms:** commit, prepare commits, stage and commit, push, update
changelog, unreleased, pre-commit, virtualenv.

---

## Phase 1: Inspect git state

**Objective:** Provide a clear picture of which files are unstaged vs staged
before deciding on logical commits.

### Steps

1. Run `git status` (short and/or long) to list:
   - Untracked files.
   - Modified but unstaged files.
   - Staged files.

2. Optionally run:
   - `git diff --stat` to understand the size and scope of unstaged changes.
   - `git diff --cached --stat` to understand the size and scope of staged
     changes.

3. Summarize:
   - Which paths are unstaged.
   - Which paths are staged.
   - Any obvious groupings by directory, feature area, or type (e.g. `api`,
     `docs`, `tests`, configuration).

**Exit condition:** Clear view of current untracked, unstaged, and staged
changes so they can be grouped into logical commits.

---

## Phase 2: Plan logical commits

**Objective:** Decide how to split changes into one or more atomic, logical
commits.

### Steps

1. Group changes logically, following the same guidance as the `release` skill:
   - By scope such as `api`, `docs`, `deps`, `tests`, or a specific feature.
   - By type such as feature vs fix vs refactor vs chore.
   - Prefer **one logical change per commit** when practical.

2. For each planned commit group:
   - List the files (and, if helpful, a short description of the change) that
     will be included.
   - Determine the appropriate Conventional Commit **type** and optional
     **scope** using the [git](/home/miragecentury/.claude/skills/git/SKILL.md)
     skill (e.g. `feat`, `fix`, `chore`, `docs`, `refactor`, `test`).
   - Draft a tentative commit message summary (short description), and when
     applicable include a `[TICKET-ID]` prefix (e.g. inferred from branch name).

3. If operating interactively with the user, present the planned groups and
   messages and allow small adjustments (merging, splitting, or renaming
   groups).

**Exit condition:** Concrete list of one or more commit groups, each with:
files to include and a planned Conventional Commit message.

---

## Phase 3: Ensure virtualenv and install pre-commit hooks

**Objective:** Activate the correct Python environment and **install** git hooks
so local commit / push verification matches CI. A present `.pre-commit-config.yaml`
does **not** mean hooks are wired into `.git/hooks` — that only happens after
`pre-commit install`.

> **CRITICAL:** Never assume hooks are installed. Never commit or push when
> `.pre-commit-config.yaml` exists but git hooks are missing. Missing local
> hooks is a common cause of CI failures (especially commitlint / commit-msg
> checks). **MUST NOT** use `--no-verify` / `--no-gpg-sign` to bypass hooks.

### Steps

1. Detect whether a virtualenv exists at the repository root:
   - Check for `.venv/bin/activate`.

2. If `.venv/bin/activate` exists:
   - Ensure that commit-related commands run in a shell where
     `source .venv/bin/activate` has been executed in the repository.
   - Keep this environment active for all subsequent `pre-commit`, `git commit`,
     and `git push` operations in this workflow.

3. If `.venv/bin/activate` does not exist:
   - Prefer `poetry run pre-commit …` when the repo uses Poetry and lists
     `pre-commit` as a dependency; otherwise use `pre-commit` from `PATH`.

4. If `.pre-commit-config.yaml` is present, **MUST** install hooks before any
   `git commit` or `git push`:
   1. Ensure the `pre-commit` CLI is available (`pre-commit --version` or
      `poetry run pre-commit --version`). If missing, install it into the active
      venv / via Poetry (do not skip this phase).
   2. Run (idempotent; safe to re-run every workflow):
      ```bash
      pre-commit install --hook-type pre-commit --hook-type commit-msg
      ```
   3. If `.pre-commit-config.yaml` declares any hook with `stages: [pre-push]`
      (or equivalent), also run:
      ```bash
      pre-commit install --hook-type pre-push
      ```
   4. Verify wiring: `.git/hooks/pre-commit` and `.git/hooks/commit-msg` exist
      and reference pre-commit (e.g. contain `pre-commit`). If verification
      fails, stop and fix before committing.
   5. Optionally warm hook environments with `pre-commit install-hooks` when
      the first run would otherwise be slow.

5. After install, treat hook failures as blocking:
   - On `git commit`, if a hook fails, surface the failure, fix it, and retry.
   - **MUST NOT** bypass with `--no-verify`.

**Exit condition:** Virtualenv activated when present; if the repo has
`.pre-commit-config.yaml`, `pre-commit` CLI works and git hooks for
`pre-commit` + `commit-msg` (and `pre-push` when configured) are installed and
verified.

---

## Phase 4: Execute commits following conventions

**Objective:** Commit each logical group of changes with Conventional Commit
messages, using the planned grouping.

### Steps

1. For each planned commit group:
   - Stage exactly the files that belong to this group:
     - Use `git add <paths>` or an equivalent interactive selection to avoid
       mixing unrelated changes in a single commit.
   - Compose the commit message following the
     [git](/home/miragecentury/.claude/skills/git/SKILL.md) skill:
     - Format: `[TICKET-ID] type(scope): short description` (with `[TICKET-ID]`
       optional).
     - Ensure `type` and `scope` accurately describe the change and match
       repository conventions.
   - Run `git commit` in the environment prepared in Phase 3 so installed
     pre-commit / commit-msg hooks execute.
   - If hooks fail, resolve the reported issues and rerun `git commit` for this
     group. Do not skip hooks.

2. Repeat for all planned groups until:
   - The working tree is clean for all non-changelog files.
   - Any remaining uncommitted changes are limited to `CHANGELOG.md` edits that
     will be handled in Phase 5.

**Exit condition:** All non-changelog changes are committed in one or more
well-scoped commits with Conventional Commit messages.

---

## Phase 5: Update `CHANGELOG.md` `[Unreleased]` entries

**Objective:** Reflect the new changes in the changelog under the `[Unreleased]`
section, without creating a new version or tag.

### Steps

1. Ensure `CHANGELOG.md` exists in the repository root:
   - If missing, create it using the same Keep a Changelog structure as in the
     `release` skill, with at least:
     - A header describing the format.
     - A top-level `## [Unreleased]` section ready for entries.
     - Optional initial comparison links. **Do not** create a versioned section
       or tag here; that is reserved for the `release` skill.

2. Focus only on the `[Unreleased]` section:
   - **Do not** create a new version section.
   - **Do not** modify comparison links or tags.

3. Derive or update changelog entries for this change set:
   - Use the planned and actual commits and their types to decide which
     subsections to use (`Added`, `Changed`, `Fixed`, `Removed`, `Security`,
     etc.) following the mapping in the
     [git](/home/miragecentury/.claude/skills/git/SKILL.md) skill.
   - Append or refine bullet points that describe the user-facing impact of the
     changes, not just file names.
   - Optionally include ticket identifiers when present in commit messages.

4. Stage and commit the changelog updates:
   - Either:
     - Include `CHANGELOG.md` edits in the associated logical commit group when
       they are tightly coupled, **or**
     - Create a dedicated `chore(changelog):` commit if that better matches
       repository practice.
   - In all cases, keep changes inside `[Unreleased]` only; no version bump or
     tag.

**Exit condition:** `CHANGELOG.md` exists and has up-to-date entries under
`[Unreleased]` that accurately describe the just-committed work, and those
entries are themselves committed.

---

## Phase 6: Gate before push

**Objective:** Ensure local verification is wired (and preferably re-run) before
any push that would hit CI.

### Steps

1. This phase **MUST** run whenever the user asks to push, or when this workflow
   is about to run `git push` / open a PR that pushes.
2. Re-run Phase 3 install/verify (hooks can be missing after a fresh clone,
   worktree, or `git init` copy). Do not skip because commits already succeeded
   earlier in the session on another machine/worktree.
3. If `.pre-commit-config.yaml` exists, **SHOULD** run a full local check before
   push so CI is not the first verifier:
   ```bash
   pre-commit run --all-files
   ```
   Fix any failures before pushing.
4. Only then run `git push` (when the user requested a push). Still **MUST NOT**
   use `--no-verify`.

**Exit condition:** Hooks installed and verified; optional full `pre-commit run`
passed (or failures fixed); push proceeds only after that gate.

---

## Phase 7: Summarize results

**Objective:** Provide a clear summary of what the commit workflow did.

### Steps

1. Summarize for the user:
   - How many commits were created and their final commit messages.
   - Which files were included in each commit group.
   - Any updates made to `CHANGELOG.md` under `[Unreleased]`.
   - Whether `.venv` was activated, which hook types were installed
     (`pre-commit`, `commit-msg`, `pre-push`), and whether hooks /
     `pre-commit run --all-files` succeeded (or required fixes).

2. Optionally suggest useful git commands for inspection, such as:
   - `git log --oneline -n <k>` to see recent commits.
   - `git show <commit>` to inspect a particular commit.

**Exit condition:** User understands the commits that were created, how the
changelog was updated, and the environment/pre-commit behavior applied during
the workflow.

---

## Separation of responsibilities

- The **commit** skill:
  - Prepares and records day-to-day commits.
  - Maintains `CHANGELOG.md` under the `[Unreleased]` section to describe new
    work.
  - **Installs** and verifies pre-commit git hooks before commit and before push
    so local checks match CI.

- The **release** skill:
  - Consumes `[Unreleased]`, creates a new version section.
  - Updates comparison links.
  - Commits the changelog for the new version.
  - Creates an annotated version tag.

For commit format, changelog mapping, and any future versioning rules, always
follow the [git](/home/miragecentury/.claude/skills/git/SKILL.md) skill.

