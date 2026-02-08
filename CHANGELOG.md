# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

---

## [1.5.0] - 2026-02-08

### Added

- **jira-cli** skill: Interact with Jira from the command line using ankitpokhrel/jira-cli (create, update, list, link, comment); references for commands and install/configure
- **story-driven-development** skill: Feature implementation from user story (branch, context, scenarios, contract, TDD, quality gate, commit, push, PR); Jira ticket comments for decisions

### Changed

- jira-epics-stories SKILL.md: updated to use jira-cli instead of Jira MCP

### Removed

- jira-epics-stories reference: `references/jira-mcp-tools.md` (replaced by jira-cli skill)

---

## [1.4.0] - 2026-02-08

### Added

- **fastapi-factory-utilities** reference: `references/jwt-authentication.md` for JWT Bearer validation, JWKS store, and custom verifiers

### Changed

- fastapi-factory-utilities SKILL.md: document JWT authentication reference and "When to use" guidance
- fastapi-factory-utilities references: aiohttp, hydra-service, kratos-service, repository-pattern updates

---

## [1.3.0] - 2026-02-08

### Added

- Install script syncs **agents** to `~/.claude/agents` (e.g. `analyst.md`)

### Changed

- Install script renamed from `install_or_update_skills.sh` to `install_or_update.sh`
- README: document agents in installation, installed paths (skills and agents), and new script URL

---

## [1.2.0] - 2026-02-08

### Added

- **jira-epics-stories** skill: Writing epics and user stories with acceptance criteria; creating or updating them in Jira via Jira MCP when available
- jira-epics-stories reference: `references/jira-mcp-tools.md` for MCP server variants and tool names
- jira-epics-stories assets: `assets/templates.md` for epic and story markdown templates
- **agents/analyst.md**: Business Analyst agent with Epic & User Story Writer subagent; references jira-epics-stories skill

### Changed

- README: document jira-epics-stories in available skills table

---

## [1.1.0] - 2026-02-06

### Added

- **writing-skills** skill: Authoring Agent Skills (SKILL.md), structure, MUST/SHOULD/MAY phrasing, and checklists
- writing-skills reference: `references/checklist.md` for skill authoring

### Changed

- README: document writing-skills in available skills table

---

## [1.0.0] - 2026-02-06

### Added

- Initial skill collection for agentic software delivery
- **git** skill: Commit conventions, branch naming, semantic versioning, and pre-commit hooks
- **http-api-architecture** skill: REST patterns, caching, distributed tracing, OAuth2/OIDC, and webhooks
- **openapi** skill: OpenAPI 3.1 specification design and Spectral validation
- **openapi-testing** skill: Contract testing with Portman and Newman
- **python-architecture** skill: Clean architecture patterns for FastAPI services
- **python-docstring** skill: Python documentation standards
- **python-lint** skill: Pylint configuration and code quality
- **python-starter** skill: Python project bootstrapping
- **python-test** skill: Pytest, fixtures, mocks, and Testcontainers
- **software-architecture** skill: Clean Architecture, DDD, SOLID, and microservices
- Skill template for creating new skills
- Install script (`scripts/install_or_update.sh`) for one-line install and update alias
- Repository README with comprehensive documentation

### Changed

### Deprecated

### Removed

### Fixed

### Security

---

[Unreleased]: https://github.com/DeerHide/agent_skills/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/DeerHide/agent_skills/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/DeerHide/agent_skills/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/DeerHide/agent_skills/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/DeerHide/agent_skills/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/DeerHide/agent_skills/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/DeerHide/agent_skills/releases/tag/v1.0.0
