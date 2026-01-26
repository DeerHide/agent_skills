---
name: python-lint
description: A skill for linting Python code.
metadata:
  author: Deerhide
  version: 1.0.0
---

# Python Lint Skill

## When to use this skill?

- Use this skill when you want to check Python code for potential errors, coding standard violations, and other issues.
- This skill is useful for developers who want to ensure their Python code adheres to best practices and is free of common mistakes.
- It can be used during code reviews, continuous integration pipelines, or as part of a development workflow.

# Which Tools Does This Skill Use ?

- **pylint**: A popular Python linting tool that checks for errors in Python code, enforces a coding standard, and looks for code smells.
- **ruff**: A fast Python linter that checks for style violations and potential errors in Python code.
- **mypy**: A static type checker for Python that checks for type consistency in Python code.

# Why use Pylint ?

- Pylint provides comprehensive checks for Python code, including error detection, coding standard enforcement, and code quality analysis.
- It is highly configurable, allowing developers to customize the checks according to their project's needs.
- Pylint generates detailed reports that help developers identify and fix issues in their code.
- We use [pylintrc](assets/pylintrc) file to have a consistent configuration across the team.

## Pylint Configuration Example

```toml (in pyproject.toml)
[tool.pylint]
line-length = 120
max-args = 10 # Increased the maximum number of arguments allowed for DI functions
```

# Why use Ruff ?

- Ruff is known for its speed and efficiency, making it suitable for large codebases.
- It supports a wide range of linting rules and can be easily integrated into development workflows.
- Ruff is designed to be extensible, allowing developers to add custom linting rules as needed

## Which Rules Does we Use with Ruff ?

- D: Docstring related rules
- F: Pyflakes rules for detecting errors
- E: Pycodestyle error rules
- W: Pycodestyle warning rules
- I: Import related rules
- UP: Pyupgrade rules for modernizing Python syntax
- PL: Pylint compatible rules
- N: Naming convention rules
- RUF: Ruff specific rules
- TRY: Try/Except related rules (tryceratops)
- B: Bugbear rules for common bugs and design problems
- C4: Comprehension rules for better list/dict/set comprehensions
- SIM: Simplify rules for code simplification
- PTH: Pathlib rules for preferring pathlib over os.path
- S: Security rules (Bandit) for detecting security issues
- A: Builtins rules to avoid shadowing Python builtins
- C90: McCabe complexity rules
- ARG: Unused arguments detection
- RET: Return statement rules
- TCH: Type-checking import rules for optimizing imports
- PERF: Performance rules for detecting performance anti-patterns
- ERA: Eradicate rules for detecting commented-out code

## pyproject.toml Configuration for Ruff

```toml (in pyproject.toml)
[tool.ruff]
# Same as Black.
line-length = 120
indent-width = 4

[tool.ruff.lint]
select = ["D", "F", "E", "W", "I", "UP", "PL", "N", "RUF", "TRY", "B", "C4", "SIM", "PTH", "S", "A", "C90", "ARG", "RET", "TCH", "PERF", "ERA"]

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = ["S101"]
"**/*.py" = ["TRY003"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
docstring-code-format = true
docstring-code-line-length = 120

[tool.ruff.lint.pydocstyle]
convention = "google"
```

# Why use Mypy ?

- Mypy helps catch type-related errors early in the development process, reducing runtime errors.
- It supports gradual typing, allowing developers to add type annotations incrementally to their codebase.
- Mypy integrates well with existing Python code and can be used alongside other linting tools.

## Mypy Configuration

```toml (in pyproject.toml)
[tool.mypy]
python_version = "3.12"
warn_unused_configs = true
packages = "velmios.app"
mypy_path = "src:tests"
namespace_packages = true
plugins = ["pydantic.mypy"]
follow_imports = "silent"
follow_untyped_imports = true
warn_redundant_casts = true
warn_unused_ignores = true
disallow_any_generics = true
check_untyped_defs = true
no_implicit_reexport = true
# for strict mypy: (this is the tricky one :-))
disallow_untyped_defs = true

[tool.pydantic-mypy]
init_forbid_extra = true
init_typed = true
warn_required_dynamic_aliases = true
```

# Pre-commit Integration

To ensure code quality is maintained consistently, it's recommended to integrate these linting tools with pre-commit hooks. This allows automatic linting checks before each commit, preventing code with linting errors from being committed.

## Pre-commit Configuration

Add the following to your `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: ruff-check
        name: ruff check
        entry: ruff check --fix
        language: system
        types: [python]

      - id: mypy
        name: mypy
        entry: mypy
        language: system
        types: [python]

      - id: pylint
        name: pylint
        entry: pylint
        language: system
        types: [python]
        args: [--rcfile=pylintrc]
```

# Running the Linters

## Running Ruff

```bash
# Check for linting issues
ruff check .

# Check and format code and auto-fix issues
ruff check --fix .
```

## Running Pylint

```bash
# Lint a specific file
pylint src/module.py

# Lint entire package
pylint src/

# Lint with custom config
pylint --rcfile=pylintrc src/
```

## Running Mypy

```bash
# Type check a file
mypy src/module.py

# Type check entire package
mypy src/

# Type check with strict mode
mypy --strict src/
```

# Handling Tool Conflicts

Since Pylint and Ruff have overlapping rules, here are recommendations to avoid conflicts:

1. **Prefer Ruff for style checks** - Ruff is faster and covers most Pycodestyle/Pyflakes rules
2. **Use Pylint for deeper analysis** - Pylint excels at detecting complex issues like unused variables in specific contexts
3. **Disable overlapping rules in Pylint** - The provided pylintrc already disables many rules covered by Ruff
4. **Run in order**: Ruff → Mypy → Pylint (fastest to slowest)

## Related Skills

- [git](../git/SKILL.md) - Pre-commit hooks setup
- [python](../python/SKILL.md) - Python coding standards
- [python-docstring](../python-docstring/SKILL.md) - Docstring conventions enforced by Ruff
