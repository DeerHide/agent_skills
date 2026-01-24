---
name: python-architecture
description: Best practices and patterns for building Python backend services using FastAPI, Poetry, and Cloud Native Buildpacks. Based on fastapi_factory_utilities library and clean architecture principles.
metadata:
  author: Deerhide
  version: 1.0.0
---
# Python Architecture

## When to use this skill?

- Use this skill when creating a new Python backend service or microservice.
- Use this skill when setting up a FastAPI-based application with proper architecture.
- Use this skill when configuring Poetry for Python package management.
- Use this skill when containerizing Python applications with Cloud Native Buildpacks.
- Use this skill when implementing plugin-based architectures in Python.
- Use this skill when setting up observability, configuration management, or security patterns.
- Use this skill when developing applications in python that require scalability, maintainability, and adherence to best practices.
- Use this skill when following Clean Architecture, SOLID principles, and DDD concepts in Python applications.

---

## Overview

This skill provides architectural patterns for building production-ready Python backend services. It leverages:

- **[fastapi_factory_utilities](https://github.com/DeerHide/fastapi_factory_utilities)** - A comprehensive library for building microservices with FastAPI
- **Poetry** - Modern Python dependency management and packaging
- **Pack (Buildpacks)** - Cloud Native Buildpacks for containerization with Paketo Buildpacks

The architecture follows principles defined in the [software-architecture skill](../software-architecture/SKILL.md), particularly Clean Architecture, SOLID principles, and DDD concepts.

## How to build a python microservice ?

For a step-by-step guide on building a Python microservice using this architecture, refer to the following document:

[How to Build a Python Microservice](references/how-to-build-python-microservice.md)

## Project Structure

For a detailed breakdown of the recommended directory structure following Clean Architecture principles, including layer descriptions, code examples, and best practices:

[Project Structure](references/project-structure.md)


## Naming Conventions

- **Project Structure**: Follow standard Python project structures with clear separation of concerns (e.g., `app`, `tests`, `config`, `docs`).
- **Module and Package Names**: Use lowercase with underscores (e.g., `my_module`).
- **Class Names**: Use CamelCase (e.g., `MyClass`).
- **Function and Variable Names**: Use lowercase with underscores (e.g., `my_function`).
- **Constant Names**: Use uppercase with underscores (e.g., `MY_CONSTANT`).
- **Private Members**: Prefix with a single underscore (e.g., `_my_private_variable`).

## Modules

### File Module

Use simple file-based modules for small concepts or utilities that do not require complex structure and can be contained within a single file.

### Directory Module

Use directory-based modules for larger concepts that require multiple files and submodules for better organization and separation of concerns.
Always include an `__init__.py` file to define the module.
Use the `__init__.py` file to expose the public API of the module and keep internal implementations private.
Use the __all__ variable in `__init__.py` to explicitly define the public interface of the module.

## Exception Handling

- Use custom exception classes to represent specific error conditions.
- Use FastAPI's exception handlers to manage HTTP exceptions and return appropriate responses.
- Log Message must be static and avoid dynamic data to prevent log injection attacks.
- Use structured logging for better log management and analysis.
- Add attributes to exceptions for additional context (e.g., error codes, user IDs).
- Avoid exposing sensitive information in error messages.

## Logging

- Use structured logging libraries like Structlog for better log management.
- Use the stdlib logging module for basic logging needs.
- Log at appropriate levels (DEBUG, INFO, WARNING, ERROR, CRITICAL).
- Include contextual information in logs as attributes. (e.g., request IDs, user IDs).
- Never log sensitive information (e.g., passwords, personal data).
- Use correlation IDs to trace requests across services (must be done through a structlog processor).

## Configuration Management

- Use environment variables for configuration settings.
- Use Pydantic models to validate and manage configuration data.
- Separate configuration between different functional areas (e.g., database, API, security).

---

## Main Technology Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| **Python** | >= 3.12 | Runtime |
| **FastAPI** | >= 0.115.13 | Web framework |
| **Poetry** | >= 1.8.0 | Package management |
| **Pydantic** | ^2.8.2 | Data validation |
| **Uvicorn** | >= 0.24.0 | ASGI server |
| **Structlog** | >= 22.1.0 | Structured logging |

Additional libraries and tools may be included based on the plugin use.

---

## References

### Skill References

| Document | Description |
|----------|-------------|
| [Dependency Injection](references/dependency-injection.md) | Dependency injection patterns using FastAPI's Depends system |
| [How to Build a Python Microservice](references/how-to-build-python-microservice.md) | Step-by-step guide for building and containerizing a Python microservice |
| [Project Structure](references/project-structure.md) | Recommended directory structure following Clean Architecture principles |
| [Use Cases Pattern](references/usecases-pattern.md) | Patterns for implementing use cases with setter/property approach |

### External References

| Document | Description |
|----------|-------------|
| [software-architecture](../software-architecture/SKILL.md) | Software architecture principles (SOLID, DDD, Clean Architecture) |
| [fastapi_factory_utilities](https://github.com/DeerHide/fastapi_factory_utilities) | Core library documentation |
| [Poetry Documentation](https://python-poetry.org/docs/) | Package management |
| [Paketo Buildpacks](https://paketo.io/docs/howto/python/) | Python buildpack documentation |
| [FastAPI Documentation](https://fastapi.tiangolo.com/) | Web framework documentation |
