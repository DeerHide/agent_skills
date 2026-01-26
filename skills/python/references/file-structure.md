# File Structure

## Module Organization

- Organize code by feature/domain, not by technical layer
- Keep related functionality together
- Use clear, descriptive module names

## Package Structure

```
src/
  fastapi_factory_utilities/
    core/
      app/
        __init__.py
        application.py
      exceptions.py
      services/
        hydra/
          __init__.py
          services.py
          exceptions.py
```

## `__init__.py` Patterns

Use `__init__.py` to expose public API:

```python
"""Package description."""

from .application import ApplicationAbstract
from .config import RootConfig

__all__ = ["ApplicationAbstract", "RootConfig"]
```

## Separation of Concerns

- Keep business logic separate from infrastructure code
- Separate interfaces (abstract classes) from implementations
- Keep configuration separate from application code
- Separate exceptions into their own modules when they grow large
