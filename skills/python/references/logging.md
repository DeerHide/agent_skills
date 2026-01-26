# Logging Patterns

## Structlog Usage

- Use `structlog` for all logging operations
- Get logger using `get_logger()` from `structlog.stdlib`
- Use `BoundLogger` type for logger variables

```python
from structlog.stdlib import BoundLogger, get_logger

_logger: BoundLogger = get_logger()
```

## Logging Levels

Use appropriate logging levels:
- `DEBUG`: Detailed information for diagnosing problems
- `INFO`: General informational messages
- `WARNING`: Warning messages for potentially harmful situations
- `ERROR`: Error messages for serious problems
- `CRITICAL`: Critical errors that may cause the application to stop

## Structured Logging

Use structured logging with context:

```python
_logger.log(level=logging.ERROR, event="Operation failed", operation="create_user", user_id=user_id)
```

## OpenTelemetry Integration

Integrate logging with OpenTelemetry spans when available:

```python
from opentelemetry.trace import Span, get_current_span

span: Span = get_current_span()
if span.is_recording():
    span.record_exception(exception)
    span.set_attribute("key", value)
```
