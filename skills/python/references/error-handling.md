# Error Handling

## Custom Exception Hierarchy

All custom exceptions should extend `FastAPIFactoryUtilitiesError`:

```python
from fastapi_factory_utilities.core.exceptions import FastAPIFactoryUtilitiesError

class CustomError(FastAPIFactoryUtilitiesError):
    """Description of the custom error."""
    DEFAULT_LOGGING_LEVEL: int = logging.ERROR
    DEFAULT_MESSAGE: str | None = None
```

## Exception Parameters

Use `TypedDict` with `Unpack` for exception parameters:

```python
from typing import NotRequired, TypedDict, Unpack

class ExceptionParameters(TypedDict):
    """Parameters for the exception."""
    message: NotRequired[str]
    level: NotRequired[int]

def __init__(self, *args: object, **kwargs: Unpack[ExceptionParameters]) -> None:
    ...
```

## Exception Logging and OpenTelemetry

Exceptions should:
- Log themselves using the configured logger
- Integrate with OpenTelemetry spans when available
- Include relevant context in span attributes

## Exception Chaining

Use proper exception chaining when re-raising exceptions:

```python
try:
    result = await operation()
except ValueError as e:
    raise CustomError("Operation failed") from e
```
