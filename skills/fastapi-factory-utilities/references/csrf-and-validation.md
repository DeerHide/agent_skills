# CSRF protection and validation error handling

CSRF protection (via `fastapi-csrf-protect`) and centralized request-validation error handling shipped with the FFU application framework.

## When to use

- Hardening browser-facing FastAPI applications against CSRF.
- Returning a structured 422 envelope for request validation failures.
- Layering Velmios security exception handlers on top of the FFU defaults.

## Validation handler

```python
from fastapi import FastAPI
from fastapi_factory_utilities.core.app.handlers import register_exception_handlers


app = FastAPI()
register_exception_handlers(app)
```

The handler binds `RequestValidationError → 422`. Response body:

```json
{
  "detail": [
    {
      "loc": ["body", "email"],
      "msg": "value is not a valid email address",
      "type": "value_error.email"
    }
  ]
}
```

The handler also emits a structured `warning` log (`Validation error`) with `method`, `path`, and `errors_count`. Log payloads do not include the request body, so sensitive payloads are not leaked.

`ApplicationAbstract.__init__()` calls `register_exception_handlers(self)` automatically, so manual wiring is only required when you build the FastAPI app outside the framework.

## CSRF configuration

CSRF is opt-in. Provide a `CsrfSettings` model (typically a `pydantic.BaseSettings`) and wire it via `ApplicationAbstract.configure_csrf()`:

```python
from pydantic_settings import BaseSettings


class CsrfSettings(BaseSettings):
    secret_key: str
    cookie_samesite: str = "lax"
    cookie_secure: bool = True
    cookie_key: str = "csrf_token"
    header_name: str = "X-CSRF-Token"


class App(ApplicationAbstract):
    def __init__(self, ...):
        super().__init__(...)
        self.configure_csrf(settings_cls=CsrfSettings)
```

`configure_csrf` installs the `CsrfProtect` config loader, registers the protection extension, and stores the resolved `CsrfProtect` instance on `app.state` so dependencies can read it.

### Dependency injection

```python
from fastapi_csrf_protect import CsrfProtect
from fastapi_factory_utilities.core.app.csrf import depends_csrf_protect


@router.post("/sensitive")
async def sensitive_action(request: Request, csrf: CsrfProtect = Depends(depends_csrf_protect)) -> None:
    await csrf.validate_csrf(request)
    ...
```

`DependsCsrfProtect.import_to_state(state, csrf_protect)` stores the configured `CsrfProtect`; `export_from_state(state)` returns it. The callable form (`depends_csrf_protect(request)`) is what you use in `Depends(...)`.

### Exception handler

```python
from fastapi_factory_utilities.core.app.csrf import register_csrf_protect_exception_handler


register_csrf_protect_exception_handler(app)
```

The handler maps every `CsrfProtectError` to:

```json
{
  "detail": "CSRF token is invalid"
}
```

with HTTP status **403 Forbidden**. A structured `warning` log (`CSRF error`) accompanies each rejection so security dashboards can monitor abuse attempts. Velmios `velmios_configure()` calls this helper as part of the standard configure chain.

## Velmios layering

Velmios builds on top of these handlers via `register_security_exception_handlers(app)` (see Velmios Exception handling (`velmios-lib` in laelidona/velmios-skills)). Order of registration inside `velmios_configure()`:

1. FFU `register_exception_handlers(app)` (validation → 422). Inherited from `ApplicationAbstract.__init__()`.
2. FFU `register_csrf_protect_exception_handler(app)` (CSRF → 403).
3. Velmios `register_security_exception_handlers(app)` (authentication / authorization → 401 / 403 with OTel telemetry).

Because FastAPI keeps a per-exception-type registry, each handler routes the specific exception class it was registered for; the Velmios handler does not override the FFU validation or CSRF handlers.

## Error mapping summary

| Exception | Handler | Status | Notes |
|---|---|---|---|
| `RequestValidationError` | `validation_exception_handler` | 422 | Structured `detail` list. |
| `CsrfProtectError` | `csrf_protect_exception_handler` | 403 | Logged as a warning. |
| Velmios `VelmiosNotAuthenticatedError` | Velmios security handler | 401 | Increments `velmios.security.auth_failures`. |
| Velmios `VelmiosSecurityError` (catch-all) | Velmios security handler | 403 | Increments `velmios.security.auth_failures`. |
| Velmios `PermissionsRequiredError` | Velmios security handler | 403 | Logs the required expression. |

## Best practices

1. Always register validation and CSRF handlers — they make API misuse visible and easy to debug.
2. Pair CSRF protection with `cookie_secure=True` and `samesite="strict"` for production deployments.
3. Surface validation errors with `detail` as-is to clients — Pydantic's structure is consistent and machine-friendly.
4. When extending validation behavior, prefer composing custom Pydantic validators instead of replacing the handler.

## Reference

- `src/fastapi_factory_utilities/core/app/handlers.py`
- `src/fastapi_factory_utilities/core/app/csrf.py`
- `src/fastapi_factory_utilities/core/app/application.py` (`configure_csrf`)
- See also: [Application framework](application-framework.md), Velmios Exception handling (`velmios-lib` in laelidona/velmios-skills).
