# Validated Types

## When to Use

- When you need **validated user input** in Pydantic models or FastAPI schemas.
- When storing or transmitting email addresses, usernames, phone numbers, names, or country codes.
- When you want automatic normalization and injection prevention on string inputs.

## Overview

Validated types are custom Pydantic-compatible types that enforce format, length, and normalization rules at validation time. They integrate seamlessly with FastAPI request/response models.

```python
from velmios.core.types import Email, Username, PhoneNumber, Name, Country
```

## Type Reference

### Email

Validates and normalizes email addresses using the `email-validator` library.

```python
from velmios.core.types import Email

email = Email("User@Example.COM")  # normalized
```

- Validates format via `email-validator`.
- Normalizes to lowercase domain.

### Username

Validates usernames with length and character constraints.

```python
from velmios.core.types import Username

username = Username("john_doe")
```

- Length: 3-32 characters.
- Allowed characters: alphanumeric, underscore (`_`), hyphen (`-`).
- Unicode NFD normalization applied.

### PhoneNumber

Validates phone numbers in E.164 international format using the `phonenumbers` library.

```python
from velmios.core.types import PhoneNumber

phone = PhoneNumber("+14155552671")
```

- Must be a valid E.164 phone number.
- Validated and parsed via `phonenumbers`.

### Name

Validates human names with normalization and injection prevention.

```python
from velmios.core.types import Name

name = Name("O'Brien")
```

- Length: 1-100 characters.
- Allowed characters: letters, apostrophe (`'`), hyphen (`-`), space, period (`.`).
- Unicode NFC normalization applied.
- Injection patterns are rejected.

### Country

Validates ISO 3166-1 country codes using the `pycountry` library.

```python
from velmios.core.types import Country

country = Country("US")   # alpha-2
country = Country("USA")  # alpha-3
```

- Accepts ISO 3166-1 alpha-2 or alpha-3 codes.
- Validated via `pycountry`.

## Error Handling

All validated types raise `ValueError` (wrapped by Pydantic as `ValidationError`) when input is invalid. In FastAPI, this automatically returns a `422 Unprocessable Entity` response.

## Best Practices

1. Always use these validated types in your Pydantic request/response models instead of raw `str`.
2. Do NOT re-validate values that have already been validated by these types.
3. Use `Email` and `Username` for all user-facing identifier fields across services.

## Reference

- `src/velmios/core/types/emails.py`
- `src/velmios/core/types/usernames.py`
- `src/velmios/core/types/phone_number.py`
- `src/velmios/core/types/names.py`
- `src/velmios/core/types/countries.py`
