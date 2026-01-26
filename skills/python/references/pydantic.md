# Pydantic Patterns

## BaseModel Usage

- Use Pydantic v2 `BaseModel` for all data models
- Use `model_validate` and `model_validate_json` for validation
- Use `model_dump` and `model_dump_json` for serialization

```python
from pydantic import BaseModel

class UserModel(BaseModel):
    """User model."""
    id: str
    name: str
    email: str

# Validation
user = UserModel.model_validate({"id": "1", "name": "John", "email": "john@example.com"})
user = UserModel.model_validate_json('{"id": "1", "name": "John", "email": "john@example.com"}')

# Serialization
data = user.model_dump()
json_data = user.model_dump_json()
```

## Field Configuration

Use Pydantic Field for advanced configuration:

```python
from pydantic import BaseModel, Field

class ConfigModel(BaseModel):
    """Configuration model."""
    timeout: float = Field(default=10.0, gt=0, description="Operation timeout in seconds")
    retries: int = Field(default=3, ge=0, le=10, description="Number of retry attempts")
```

## Validation Patterns

Implement custom validators when needed:

```python
from pydantic import BaseModel, BeforeValidator
from typing import Annotated

def ensure_logging_level(level: Any) -> int:
    """Ensure the logging level."""
    if isinstance(level, int):
        return level
    if isinstance(level, str):
        return getattr(logging, str(level).upper())
    raise ValueError(f"Invalid logging level: {level}")

class LoggingConfig(BaseModel):
    """Logging configuration."""
    level: Annotated[int, BeforeValidator(ensure_logging_level)]
```
