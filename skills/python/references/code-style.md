# Code Style and Formatting

## Formatting and Linting Scripts

Use the provided scripts to format and lint code:

**Format code:**
```bash
./scripts/format-code.sh
```

**Format code (check only, no changes):**
```bash
./scripts/format-code.sh --check
```

**Lint code:**
```bash
./scripts/lint-code.sh
```

**Lint specific files:**
```bash
./scripts/lint-code.sh --files src/my_module.py
```

**Use specific linting tool:**
```bash
./scripts/lint-code.sh --tool ruff
./scripts/lint-code.sh --tool pylint
```

## Code Style Rules

- Maximum line length: 120 characters (as configured in `pyproject.toml`)
- Use Black for code formatting (configured in `pyproject.toml`)
- Use Ruff for linting and additional formatting (configured in `pyproject.toml`)
- Use 4 spaces for indentation (no tabs)
- Use double quotes for strings (as configured in Ruff)
- Follow PEP 8 style guide, except where overridden by project configuration

## Import Organization

Organize imports in the following order, with blank lines between groups:

1. Standard library imports
2. Third-party imports
3. Local application/library imports

Within each group, sort imports alphabetically. Use absolute imports from the package root.

Example:
```python
import json
from http import HTTPStatus
from typing import Any, Generic, TypeVar

import aiohttp
from fastapi import Depends
from pydantic import BaseModel

from fastapi_factory_utilities.core.app import DependencyConfig
from fastapi_factory_utilities.core.exceptions import FastAPIFactoryUtilitiesError
```

## Naming Conventions

- **Classes**: PascalCase (e.g., `AbstractRepository`, `HydraIntrospectService`)
- **Functions and methods**: snake_case (e.g., `get_config`, `on_startup`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `DEFAULT_LOGGING_LEVEL`, `INTROSPECT_ENDPOINT`)
- **Private attributes**: Leading underscore (e.g., `_name`, `_queue`, `_consumer_tag`)
- **Type variables**: Descriptive names with Generic suffix (e.g., `DocumentGenericType`, `EntityGenericType`)
- **Modules**: snake_case (e.g., `exceptions.py`, `services.py`)
