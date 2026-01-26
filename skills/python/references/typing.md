# Typing

Always type everything you can (variables, functions, classes, etc.).

## Type Checking Script

Use the type checking script to verify type annotations:

```bash
./scripts/type-check.sh
```

**Check specific files:**
```bash
./scripts/type-check.sh --files src/my_module.py
```

## Type Annotations

- Annotate all function parameters and return types
- Annotate all class attributes
- Annotate all variables when the type is not obvious from context
- Avoid using `Any` unless absolutely necessary
- Use `Self` for return type annotations when returning the instance (Python 3.11+)

## Generic Types

Use `TypeVar` for generic types with descriptive names:

```python
from typing import Generic, TypeVar

DocumentGenericType = TypeVar("DocumentGenericType", bound=BaseDocument)
EntityGenericType = TypeVar("EntityGenericType", bound=BaseModel)

class AbstractRepository(ABC, Generic[DocumentGenericType, EntityGenericType]):
    ...
```

## TypedDict

Use `TypedDict` for structured dictionary data with type safety:

```python
from typing import NotRequired, TypedDict, Unpack

class ExceptionParameters(TypedDict):
    """Parameters for the exception."""
    message: NotRequired[str]
    level: NotRequired[int]

def __init__(self, *args: object, **kwargs: Unpack[ExceptionParameters]) -> None:
    ...
```

## Collections

Use `collections.abc` types for abstract base classes:

```python
from collections.abc import AsyncGenerator, Awaitable, Callable, Mapping
```
