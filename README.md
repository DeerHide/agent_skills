# Agent Skills

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A curated collection of **Agent Skills** for Agentic Software Delivery, following the [SKILL.md](https://agentskills.io/home) Specification.

## Overview

This repository provides reusable skill modules that enhance AI coding agents with domain-specific knowledge, best practices, and automation scripts. Each skill contains documentation, scripts, references, and assets to help you implement specific functionalities in your agentic software delivery projects.

## Installation

### Quick install (download and run)

Download and run the install script directly from GitHub (clones the repo to `~/.deerhide/repositories/agent_skills`, copies skills to `~/.claude/skills` and agents to `~/.claude/agents`, and adds the `deerhide_agents_skills_update` alias to your shell rc):

```bash
curl -fsSL https://raw.githubusercontent.com/DeerHide/agent_skills/main/scripts/install_or_update.sh | bash
```

Afterwards you can update skills and agents anytime with:

```bash
deerhide_agents_skills_update
```

Installed paths:

- **Skills:** `~/.claude/skills` — one directory per skill (e.g. `git`, `python-architecture`).
- **Agents:** `~/.claude/agents` — agent definition files (e.g. `analyst.md` for the Business Analyst agent).

## Available Skills

| Skill | Description |
|-------|-------------|
| **[git](skills/git/SKILL.md)** | Git commit conventions, branch naming, semantic versioning, changelog maintenance, and pre-commit hooks |
| **[http-api-architecture](skills/http-api-architecture/SKILL.md)** | REST API design patterns, caching strategies, distributed tracing, OAuth2/OIDC flows, and webhook security |
| **[jira-epics-stories](skills/jira-epics-stories/SKILL.md)** | Writing epics and user stories with acceptance criteria; creating or updating them in Jira via Jira MCP when available |
| **[openapi](skills/openapi/SKILL.md)** | OpenAPI 3.1 specification design, validation with Spectral, and best practices |
| **[openapi-testing](skills/openapi-testing/SKILL.md)** | API testing with Portman and Newman for contract testing |
| **[python-architecture](skills/python-architecture/SKILL.md)** | Clean architecture patterns for Python/FastAPI services with Poetry and Cloud Native Buildpacks |
| **[python-docstring](skills/python-docstring/SKILL.md)** | Python documentation standards and docstring conventions |
| **[python-lint](skills/python-lint/SKILL.md)** | Python linting configuration with Pylint and code quality tools |
| **[python-starter](skills/python-starter/SKILL.md)** | Python project bootstrapping and initial setup |
| **[python-test](skills/python-test/SKILL.md)** | Python testing with pytest, fixtures, mocks, and Testcontainers |
| **[software-architecture](skills/software-architecture/SKILL.md)** | Clean Architecture, DDD, SOLID principles, and microservices patterns |
| **[writing-skills](skills/writing-skills/SKILL.md)** | How to write Agent Skills: structure, descriptions, natural language strength (MUST/SHOULD/MAY), and checklists |

## Skill Structure

Each skill follows a consistent structure:

```
skills/<skill-name>/
├── SKILL.md          # Main skill documentation with metadata and instructions
├── assets/           # Static files, templates, and configuration examples
├── references/       # Detailed reference documentation and guides
└── scripts/          # Automation scripts for setup and execution
```

## Usage

### With AI Coding Agents

Reference the skill in your agent's context or instructions:

```markdown
Use the skills from https://github.com/DeerHide/agent_skills for:
- Git conventions: skills/git/SKILL.md
- Python architecture: skills/python-architecture/SKILL.md
```

### Manual Reference

Browse the skill documentation directly for best practices and implementation guides.

## Creating New Skills

Use the [template](template/SKILL.md) as a starting point:

1. Copy the `template/` directory
2. Rename it to your skill name
3. Update `SKILL.md` with your skill's metadata and documentation
4. Add assets, references, and scripts as needed

## Contributing

Contributions are welcome! Please ensure your skills follow the established structure and include comprehensive documentation.

## Authors & Maintainers

- **DeerHide** - *Initial work & maintenance* - [@DeerHide](https://github.com/DeerHide)

See also the list of [contributors](https://github.com/DeerHide/agent_skills/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ by [DeerHide](https://github.com/DeerHide)
