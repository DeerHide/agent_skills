---
name: python
description: Python software engineering principles, coding standards, and best practices. Use when writing Python code, setting up development environments, or following Python project conventions including typing, async patterns, testing, and documentation.
metadata:
  author: Deerhide
  version: 1.0.0
---

# Python Software Engineering Principles

Use Python version defined in `pyproject.toml` when available.

## Core Principles

Follow these fundamental principles in all Python code:

- **Clean Architecture**: Separate concerns and maintain clear boundaries
- **Separation of Concerns**: Keep business logic separate from infrastructure
- **Dependency Injection**: Use dependency injection for loose coupling
- **Inversion of Control**: Let frameworks manage object lifecycle
- **Single Responsibility**: Each class/function should have one clear purpose
- **Least Privilege**: Grant minimum necessary permissions and access

## Quick Reference

### Development Environment

- Use Poetry for dependency management
- Create virtual environment in `.venv` directory
- Activate with `source .venv/bin/activate` (Linux/macOS) or `.venv\Scripts\activate` (Windows)
- Run commands with `poetry run` to use virtual environment

### Code Style

- Maximum line length: 120 characters
- Use Black and Ruff for formatting and linting
- 4 spaces for indentation (no tabs)
- Double quotes for strings
- Follow PEP 8, except where overridden by project configuration

### Import Organization

Organize imports in this order (blank lines between groups):
1. Standard library imports
2. Third-party imports
3. Local application/library imports

Sort alphabetically within each group. Use absolute imports from package root.

### Naming Conventions

- **Classes**: PascalCase (e.g., `AbstractRepository`)
- **Functions/methods**: snake_case (e.g., `get_config`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `DEFAULT_LOGGING_LEVEL`)
- **Private attributes**: Leading underscore (e.g., `_name`)
- **Type variables**: Descriptive names with Generic suffix (e.g., `DocumentGenericType`)

### Typing

- Always type everything (variables, functions, classes)
- Annotate all function parameters and return types
- Avoid `Any` unless absolutely necessary
- Use `TypeVar` for generic types with descriptive names
- Use `TypedDict` for structured dictionary data
- Use `collections.abc` types for abstract base classes

### Async/Await

- Use `async def` for all I/O operations
- Prefer async context managers (`async with`)
- Use `asyncio.TaskGroup` (Python 3.11+) for parallel operations
- Use `AsyncGenerator` for async generator functions
- Handle exceptions properly, ensuring cleanup

### Logging

- Use `structlog` for all logging operations
- Get logger using `get_logger()` from `structlog.stdlib`
- Use appropriate logging levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Use structured logging with context
- Integrate with OpenTelemetry spans when available

### Error Handling

- All custom exceptions should extend base exception class
- Use `TypedDict` with `Unpack` for exception parameters
- Log exceptions and integrate with OpenTelemetry
- Use proper exception chaining when re-raising

### Pydantic

- Use Pydantic v2 `BaseModel` for all data models
- Use `model_validate` and `model_validate_json` for validation
- Use `model_dump` and `model_dump_json` for serialization
- Use `Field` for advanced configuration

### Testing

- Use pytest for all tests
- Organize tests by functional scope in classes
- Prioritize unit tests over integration tests
- Use `pytest-asyncio` for async tests
- Use `pytest.mark.parametrize` for multiple scenarios
- Use `unittest.mock` for mocking dependencies

### Documentation

- Always add docstrings using Google Python docstring format
- Include module-level docstrings
- Document classes, functions, and methods
- Include Args, Returns, and Raises sections
- Add examples for complex functions

## Utility Scripts

The skill includes utility scripts for common development tasks:

- **`scripts/setup-dev-environment.sh`** - Setup Poetry and virtual environment
- **`scripts/format-code.sh`** - Format and lint code with Ruff
- **`scripts/lint-code.sh`** - Lint code with Ruff and Pylint
- **`scripts/type-check.sh`** - Run type checking with mypy
- **`scripts/run-tests.sh`** - Run tests with various options (coverage, parallel, etc.)
- **`scripts/setup-pre-commit.sh`** - Setup pre-commit hooks

See the detailed documentation below for script usage examples.

## Detailed Documentation

For comprehensive details on all topics, see:

- [Principles](references/principles.md) - Core software engineering principles (Clean Architecture, Separation of Concerns, Dependency Injection, etc.)
- [Development Environment](references/development-environment.md) - Virtual environment setup and Poetry dependency management
- [Code Style](references/code-style.md) - Code formatting, import organization, and naming conventions
- [Typing](references/typing.md) - Type annotations, generic types, TypedDict, and collections
- [Async Patterns](references/async-patterns.md) - Async/await patterns, context managers, parallel operations, and async generators
- [Logging](references/logging.md) - Structlog usage, logging levels, structured logging, and OpenTelemetry integration
- [Error Handling](references/error-handling.md) - Custom exception hierarchy, exception parameters, logging, and chaining
- [Pydantic](references/pydantic.md) - Pydantic v2 BaseModel usage, field configuration, and validation patterns
- [Testing](references/testing.md) - Test organization, structure, async tests, parametrized tests, and mocking
- [Running Tests](references/running-tests.md) - Commands for running tests, coverage, parallel execution, and test selection
- [Documentation](references/documentation.md) - Google-style docstring format for modules, classes, functions, and complex functions
- [Architecture Patterns](references/architecture-patterns.md) - Abstract base classes, plugin pattern, dependency injection, repository pattern, and service layer
- [File Structure](references/file-structure.md) - Module organization, package structure, and `__init__.py` patterns
- [Pre-commit](references/pre-commit.md) - Installing, running, and configuring pre-commit hooks

## Related Skills

- [python-lint](../python-lint/SKILL.md) - Linting configuration with Ruff, Pylint, Mypy
- [python-docstring](../python-docstring/SKILL.md) - Google-style docstring conventions
- [python-test](../python-test/SKILL.md) - Testing patterns with pytest
- [python-architecture](../python-architecture/SKILL.md) - Backend service architecture
- [software-architecture](../software-architecture/SKILL.md) - Design principles (SOLID, DDD, Clean Architecture)
- [fastapi-factory-utilities](../fastapi-factory-utilities/SKILL.md) - FastAPI microservice utilities
