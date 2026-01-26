---
name: git
description: Provide recommendations and best practices for git commit messages, branch naming, semantic versioning, changelog maintenance, and pre-commit validation using industry standards.
metadata:
  author: Deerhide
  version: 1.0.0
---
# Git Conventions Skill

## When to use this skill?

- Use this skill when writing commit messages.
- Use this skill when creating version tags following Semantic Versioning.
- Use this skill when naming branches with JIRA ticket integration.
- Use this skill when maintaining `CHANGELOG.md` files.
- Use this skill when writing release documentation.
- Use this skill when setting up pre-commit hooks for commit message validation.
- Use this skill when reviewing commit history for consistency.

## Commit Message Format

We follow the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification with JIRA ticket integration.

### Format Structure

```
[TICKET-ID] <type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### JIRA Ticket Integration

Every commit **SHOULD** start with a JIRA ticket reference in the format `[PROJECT-NUMBER]`, but it is not required.:

```
[TIC-001] feat: add user authentication
[API-123] fix(auth): resolve token expiration issue
[PROJ-456] docs: update API documentation
```

The ticket pattern follows: `[A-Z]+-\d+` (any uppercase letters followed by a hyphen and numbers).
The ticket is not required, but it is recommended to include it for better traceability.
The ticket can be extract from the branch name.

### Commit Types

| Type | Description | SemVer Impact |
|------|-------------|---------------|
| `feat` | New feature | MINOR |
| `fix` | Bug fix | PATCH |
| `docs` | Documentation only changes | - |
| `style` | Code style (formatting, whitespace) | - |
| `refactor` | Code change that neither fixes a bug nor adds a feature | - |
| `perf` | Performance improvement | PATCH |
| `test` | Adding or updating tests | - |
| `build` | Build system or external dependencies | - |
| `ci` | CI configuration changes | - |
| `chore` | Maintenance tasks | - |
| `revert` | Reverting a previous commit | PATCH |

### Recommended Scopes

Scopes are optional but recommended for clarity. Use lowercase with hyphens:

| Scope | Description |
|-------|-------------|
| `api` | API-related changes |
| `ui` | User interface changes |
| `db` | Database-related changes |
| `auth` | Authentication/authorization |
| `config` | Configuration changes |
| `deps` | Dependency updates |
| `infra` | Infrastructure changes |
| `test` | Test-specific changes |
| `core` | Core functionality |
| `utils` | Utility functions |
| `ci` | Continuous integration |
| `docs` | Documentation |

### Breaking Changes

Breaking changes **MUST** be indicated in one of two ways:

1. **Using `!` after type/scope:**
```
[TIC-001] feat(api)!: change authentication endpoint response format
```

2. **Using `BREAKING CHANGE` footer:**
```
[TIC-001] feat(api): change authentication endpoint response format

BREAKING CHANGE: The /auth/login endpoint now returns a different JSON structure.
Old: { token: string }
New: { access_token: string, refresh_token: string, expires_in: number }
```

### Commit Message Examples

#### Simple fix
```
[TIC-042] fix: prevent racing of requests
```

#### Feature with scope
```
[API-101] feat(auth): add OAuth2 support for Google login
```

#### Breaking change with body and footer
```
[TIC-200] feat(api)!: migrate to v2 authentication

Implement new JWT-based authentication system with refresh tokens.
This replaces the legacy session-based authentication.

BREAKING CHANGE: All API endpoints now require Bearer token authentication.
Clients must update their authentication flow.

Refs: #123, #124
Reviewed-by: John Doe
```

#### Documentation update
```
[DOCS-015] docs(readme): add installation instructions for Windows
```

#### Multiple footers
```
[TIC-055] fix(db): resolve connection pooling memory leak

Identified that connections were not being properly released back to
the pool after timeout errors.

Fixes: #789
Co-authored-by: Jane Smith <jane@example.com>
```

## Branch Naming Convention

### Format

```
TICKET-ID/type/short-description
```

### Examples

| Branch Name | Description |
|-------------|-------------|
| `TIC-001/feat/user-authentication` | Feature branch for user auth |
| `TIC-042/fix/login-redirect-loop` | Bug fix branch |
| `TIC-100/refactor/api-client` | Refactoring branch |
| `DOCS-015/docs/api-documentation` | Documentation branch |

### Branch Type Prefixes

Use the same type prefixes as commit types:
- `feat/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation
- `refactor/` - Refactoring
- `test/` - Test additions
- `chore/` - Maintenance

### Guidelines

- Keep branch names lowercase with hyphens
- Use short, descriptive names (3-5 words max)
- Always include the JIRA ticket reference
- Delete branches after merging

## Semantic Versioning

We follow [Semantic Versioning 2.0.0](https://semver.org/) for version tags.

### Version Format

```
MAJOR.MINOR.PATCH
```

Example: `1.2.3`

### Version Increment Rules

| Version | When to Increment | Commit Types |
|---------|-------------------|--------------|
| **MAJOR** (X.y.z) | Incompatible/breaking API changes | `BREAKING CHANGE`, `!` suffix |
| **MINOR** (x.Y.z) | New backward-compatible functionality | `feat` |
| **PATCH** (x.y.Z) | Backward-compatible bug fixes | `fix`, `perf`, `revert` |

### Pre-release Versions

Use hyphen followed by identifiers:

```
1.0.0-alpha
1.0.0-alpha.1
1.0.0-beta
1.0.0-beta.2
1.0.0-rc.1
```

### Build Metadata

Use plus sign followed by identifiers:

```
1.0.0+20260122
1.0.0+build.123
1.0.0-beta+exp.sha.5114f85
```

### Version Precedence

```
1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-rc.1 < 1.0.0
```

## Git Tags

### Tag Format

Use `v` prefix for version tags:

```
v1.0.0
v1.2.3
v2.0.0-beta.1
```

### Creating Tags

```bash
# Create annotated tag (recommended)
git tag -a v1.0.0 -m "Release version 1.0.0"

# Create tag for specific commit
git tag -a v1.0.0 -m "Release version 1.0.0" abc1234

# Push tag to remote
git push origin v1.0.0

# Push all tags
git push origin --tags
```

### Listing Tags

```bash
# List all tags
git tag

# List tags matching pattern
git tag -l "v1.*"

# Show tag details
git show v1.0.0
```

### Tag Guidelines

- Always use annotated tags (`-a`) for releases
- Include a meaningful message describing the release
- Tag after merging to main/master branch
- Never move or delete published tags

## Changelog

We follow [Keep a Changelog v1.1.0](https://keepachangelog.com/en/1.1.0/) format.

### File Location

Create `CHANGELOG.md` in the repository root.

### Changelog Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature description [TIC-001]

### Changed
- Modified behavior description [TIC-002]

## [1.1.0] - 2026-01-22

### Added
- OAuth2 authentication support [API-101]
- User profile API endpoints [API-102]

### Fixed
- Login redirect loop issue [TIC-042]

### Security
- Updated dependencies to patch CVE-2026-1234 [SEC-001]

## [1.0.0] - 2026-01-01

### Added
- Initial release
- Basic authentication system
- User management API

[Unreleased]: https://github.com/owner/repo/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/owner/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/owner/repo/releases/tag/v1.0.0
```

### Change Types

| Type | Description |
|------|-------------|
| `Added` | New features |
| `Changed` | Changes in existing functionality |
| `Deprecated` | Soon-to-be removed features |
| `Removed` | Now removed features |
| `Fixed` | Bug fixes |
| `Security` | Vulnerability fixes |

### Changelog Guidelines

1. **Keep an `[Unreleased]` section** at the top for upcoming changes
2. **Use ISO 8601 date format**: `YYYY-MM-DD`
3. **Include JIRA ticket references** in square brackets
4. **Group changes by type** within each version
5. **Write for humans**, not machines - be descriptive
6. **Link versions** to Git comparison URLs at the bottom
7. **Latest version first** - reverse chronological order

### Mapping Commits to Changelog

| Commit Type | Changelog Section |
|-------------|-------------------|
| `feat` | Added |
| `fix` | Fixed |
| `perf` | Changed |
| `refactor` | Changed |
| `docs` | Changed (if user-facing) |
| `security fix` | Security |
| `BREAKING CHANGE` | Changed (highlight breaking) |
| Deprecation notice | Deprecated |
| Feature removal | Removed |

## Release Documentation

### Release Notes Structure

For each release, create or update release notes with:

```markdown
# Release v1.1.0

**Release Date:** 2026-01-22

## Highlights

- 🚀 OAuth2 authentication support for Google and GitHub
- 🐛 Critical login redirect loop fix
- 🔒 Security patches for dependency vulnerabilities

## Breaking Changes

### Authentication API Response Format

The `/auth/login` endpoint response structure has changed:

**Before (v1.0.x):**
```json
{ "token": "..." }
```

**After (v1.1.0):**
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_in": 3600
}
```

## Migration Guide

1. Update your authentication client to handle the new response format
2. Implement refresh token logic for seamless session renewal
3. Update token storage to accommodate both tokens

## New Features

### OAuth2 Support [API-101]
Added support for OAuth2 authentication with Google and GitHub providers.

## Bug Fixes

### Login Redirect Loop [TIC-042]
Fixed an issue where users were caught in an infinite redirect loop.

## Security

### Dependency Updates [SEC-001]
Updated vulnerable dependencies to address CVE-2026-1234.

## Contributors

- @developer1
- @developer2
```

### Release Documentation Guidelines

1. **Always document breaking changes** with before/after examples
2. **Provide migration guides** for breaking changes
3. **Highlight important changes** with emoji indicators
4. **Reference JIRA tickets** for traceability
5. **Credit contributors** who participated in the release

## Pre-commit Validation

We use [pre-commit](https://pre-commit.com/) framework with [commitlint](https://commitlint.js.org/) for commit message validation.

### Installation

1. **Install pre-commit:**
```bash
pip install pre-commit
```

2. **Install commitlint:**
```bash
npm install -g @commitlint/cli @commitlint/config-conventional
```

3. **Install git hooks:**
```bash
pre-commit install --hook-type commit-msg
```

### Configuration Files

#### `.pre-commit-config.yaml`

```yaml
repos:
  - repo: local
    hooks:
      - id: commitlint
        name: Lint commit message
        entry: npx --no -- commitlint --edit
        language: system
        stages: [commit-msg]
        always_run: true
```

#### `commitlint.config.js`

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  parserPreset: {
    parserOpts: {
      headerPattern: /^\[([A-Z]+-\d+)\]\s(\w+)(?:\(([^)]+)\))?!?:\s(.+)$/,
      headerCorrespondence: ['ticket', 'type', 'scope', 'subject'],
    },
  },
  rules: {
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert'],
    ],
    'subject-empty': [2, 'never'],
    'type-empty': [2, 'never'],
  },
};
```

### Pre-commit Commands

| Command | Description |
|---------|-------------|
| `pre-commit install --hook-type commit-msg` | Install commit-msg hook |
| `pre-commit run --all-files` | Run all hooks on all files |
| `pre-commit run commitlint --hook-stage commit-msg` | Run commitlint manually |
| `pre-commit autoupdate` | Update hooks to latest versions |
| `pre-commit uninstall` | Remove pre-commit hooks |

### Commitlint Commands

| Command | Description |
|---------|-------------|
| `npx commitlint --from HEAD~1 --to HEAD` | Lint last commit |
| `npx commitlint --from origin/main` | Lint all commits since main |
| `echo "message" \| npx commitlint` | Lint a message directly |

### Bypassing Hooks (Emergency Only)

```bash
# Skip pre-commit hooks (use sparingly)
git commit --no-verify -m "[TIC-999] fix: emergency hotfix"
```

## Quick Reference

### Commit Message Template

```
[TICKET-ID] type(scope): description

Body explaining the what and why (not how).

Footer(s):
BREAKING CHANGE: description
Refs: #issue
Co-authored-by: Name <email>
```

### Common Workflows

#### Starting a new feature
```bash
git checkout -b TIC-001/feat/new-feature
# ... make changes ...
git add .
git commit -m "[TIC-001] feat: add new feature"
git push -u origin TIC-001/feat/new-feature
```

#### Creating a release
```bash
# Update CHANGELOG.md with release notes
git add CHANGELOG.md
git commit -m "[REL-001] chore: prepare release v1.1.0"
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin main --tags
```

#### Fixing a bug
```bash
git checkout -b TIC-042/fix/login-bug
# ... fix the bug ...
git add .
git commit -m "[TIC-042] fix(auth): resolve login redirect loop"
git push -u origin TIC-042/fix/login-bug
```

## Related Skills

- [python-lint](../python-lint/SKILL.md) - Pre-commit integration with linting tools
- [python](../python/SKILL.md) - Pre-commit hooks setup