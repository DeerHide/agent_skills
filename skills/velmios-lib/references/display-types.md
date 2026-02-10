# Display Types

## When to Use

- When you need to store or validate **hex color codes** for UI theming.
- When you need to store or validate **icon codes** referencing Heroicons.

## Overview

Display types are validated string types for UI-related data. They integrate with Pydantic models for automatic validation in FastAPI schemas.

```python
from velmios.core.types import ColorHexCode, IconCode
```

## Type Reference

### ColorHexCode

Validated hex color code in `#RRGGBB` format.

```python
from velmios.core.types import ColorHexCode

color = ColorHexCode("#ff5733")
```

- Must be in `#RRGGBB` format (7 characters including `#`).
- Stored as lowercase.

### IconCode

Validated icon code referencing Heroicons naming convention.

```python
from velmios.core.types import IconCode

icon = IconCode("arrow-right")
```

- Length: 1-30 characters.
- Allowed characters: lowercase alphanumeric and hyphens.
- Follows Heroicons naming format.

## Reference

- `src/velmios/core/types/color_hex_code.py`
- `src/velmios/core/types/icon_code.py`
