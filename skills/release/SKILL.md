---
name: release
description: >
  Orchestrates cutting a release: detects CHANGELOG and git state, commits
  working-tree changes in atomic logical commits, updates CHANGELOG from commits
  since last tag, then commits the changelog and creates an annotated version
  tag. Use when the user asks to release, cut a release, tag a version, or
  update CHANGELOG and tag.
metadata:
  tags:
    - release
    - changelog
    - semver
    - tag
---

# Release workflow

This skill defines a repeatable workflow for cutting a release: ensure the
changelog exists and gather git state, commit any unstaged or staged changes in
atomic logical commits, update `CHANGELOG.md` from commits since the last tag,
then commit the changelog and create an annotated version tag. Commit messages,
SemVer, and changelog format follow the [git](/home/miragecentury/.claude/skills/git/SKILL.md) skill.

## When to use

- User asks to release, cut a release, tag a version, or run a release workflow.
- User wants to update the changelog and create a version tag from the current
  branch.
- After merging to main (or default branch), when preparing an official release.

**Trigger terms:** release, changelog, version tag, semver, cut release, prepare
release.

---

## Phase 1: Detect changelog and git state

**Objective:** Know whether a changelog exists, what the last release tag is, what
is uncommitted, and what commits exist since that tag.

### Steps

1. **Changelog**
   - Check for `CHANGELOG.md` in the repository root.
   - If missing: create it per [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) with at least the header, "Unreleased" section, and comparison links. Use the structure and guidelines from the git skill (Changelog section).
   - If present: proceed.

2. **Last release tag**
   - Resolve the latest version tag, e.g.:
     - `git describe --tags --abbrev=0 2>/dev/null` or
     - `git tag -l 'v*' --sort=-v:refname | head -1`
   - If no tag exists: treat all history as "since last release" and plan for a first version (e.g. `1.0.0`).

3. **Working tree**
   - Run `git status` to list unstaged and staged changes (paths).
   - Run `git log --oneline PREV_TAG..HEAD` (or `git log --oneline HEAD` if there is no previous tag) to list commits since the last release.

4. **Summarize**
   - Report: changelog present or created; last tag or "none"; list of unstaged/staged paths; list of commits since last tag.

**Exit condition:** Clear picture of changelog, last tag, uncommitted changes, and commits since last tag. Proceed to Phase 2.

---

## Phase 2: Commit working tree in atomic, logical commits

**Objective:** No uncommitted changes before updating the changelog. All
unstaged and staged changes are committed in one or more atomic commits with
Conventional Commit messages.

### Steps

1. If there are no unstaged or staged changes, skip to Phase 3.

2. Group changes logically (e.g. by scope: `api`, `docs`, `deps`, `test`; or by
   type: feature vs fix vs chore). Prefer one logical change per commit.

3. For each group:
   - Stage only the paths that belong to this logical change: `git add <paths>`.
   - Commit with a message that follows the [git](/home/miragecentury/.claude/skills/git/SKILL.md) skill: type, optional scope, short description; optional `[TICKET-ID]` prefix (e.g. from branch name or user input).
   - Example: `git commit -m "[TIC-001] feat(api): add orders filter endpoint"`.

4. Repeat until the working tree is clean (no unstaged or staged changes), except
   for `CHANGELOG.md` if it will be edited in Phase 3.

**WARNING:** Do not commit `CHANGELOG.md` in this phase. The changelog is
committed in Phase 4.

**Exit condition:** Working tree clean except for any pending changelog edits.
Proceed to Phase 3.

---

## Phase 3: Update the changelog

**Objective:** Add a new version section to `CHANGELOG.md` from commits since the
last tag and from any new commits created in Phase 2.

### Inputs

- Commits since last tag (from Phase 1 and Phase 2).
- Next version number (MAJOR.MINOR.PATCH) per [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and the git skill: `feat` → MINOR; `fix`, `perf`, `revert` → PATCH; breaking change → MAJOR.

### Steps

1. **Determine next version**
   - Parse the last tag (e.g. `v1.2.3`) or use `1.0.0` if there is no tag.
   - Bump PATCH, MINOR, or MAJOR based on commit types and any `BREAKING CHANGE` footers.

2. **New version section**
   - Add a section: `## [X.Y.Z] - YYYY-MM-DD` (date in ISO 8601).
   - If `[Unreleased]` already has entries: move them into this new section under the appropriate subsections (`Added`, `Changed`, `Fixed`, etc.).
   - If `[Unreleased]` is empty: derive entries from commit messages since last tag, mapping commit type to changelog section per the git skill:

     | Commit type / footer | Changelog section |
     |---------------------|-------------------|
     | `feat`              | Added             |
     | `fix`               | Fixed             |
     | `perf`              | Changed           |
     | `refactor`          | Changed           |
     | `docs` (user-facing)| Changed           |
     | Security-related    | Security          |
     | BREAKING CHANGE     | Changed (note breaking) |
     | Deprecation         | Deprecated        |
     | Removal             | Removed           |

   - Include optional `[TICKET-ID]` in entries when present in commits. Write for humans; be descriptive.

3. **Comparison links**
   - At the bottom of the file, add the comparison link for the new version, e.g. `[X.Y.Z]: https://github.com/owner/repo/compare/vPREV...vX.Y.Z`.
   - Update the `[Unreleased]` link to compare from the new tag to `HEAD`, e.g. `[Unreleased]: https://github.com/owner/repo/compare/vX.Y.Z...HEAD`.

4. **Keep [Unreleased]**
   - Leave the `[Unreleased]` section in place (empty or with a short placeholder) for future changes.

**Exit condition:** `CHANGELOG.md` contains the new version and updated links.
Proceed to Phase 4.

---

## Phase 4: Commit changelog and create tag

**Objective:** Record the release in git and create an annotated tag on the
changelog commit.

### Steps

1. Stage only `CHANGELOG.md`: `git add CHANGELOG.md`.

2. Commit with a conventional message, e.g.:
   - `git commit -m "chore(release): prepare release vX.Y.Z"`
   - Optional: add a ticket prefix if applicable, e.g. `[REL-001] chore(release): prepare release vX.Y.Z`.

3. Create an annotated tag on the current (changelog) commit:
   - `git tag -a vX.Y.Z -m "Release version X.Y.Z"`

**IMPORTANT:** The tag **MUST** be created on the commit that contains the
changelog update so the tag points at the release state.

4. **Push (optional)**
   - Pushing the branch and the tag is a separate step, e.g.:
     - `git push origin <branch>`
     - `git push origin vX.Y.Z`
   - The user may run these manually or in a follow-up.

**Exit condition:** Changelog committed and tag `vX.Y.Z` created. Release
workflow complete.

---

## Quick reference

| Phase | Outcome |
|-------|---------|
| 1     | Changelog present; last tag known; unstaged/staged and commits since tag summarized |
| 2     | Working tree committed in atomic logical commits (changelog not committed) |
| 3     | `CHANGELOG.md` updated with new version and links |
| 4     | Changelog committed; annotated tag `vX.Y.Z` created on that commit |

For commit format, SemVer rules, changelog structure, and tag format, use the [git](/home/miragecentury/.claude/skills/git/SKILL.md) skill.
