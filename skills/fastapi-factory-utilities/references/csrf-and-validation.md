# CSRF protection and validation error handling

CSRF protection (via `fastapi-csrf-protect`) and centralized request-validation error handling shipped with the FFU application framework.

## When to use

- Hardening browser-facing FastAPI applications against CSRF.
- Returning a structured 422 envelope for request validation failures.
- Layering Velmios security exception handlers on top of the FFU defaults.

## Validation handler

Handlers are **not** registered automatically. Call them from your `configure()` implementation (or when you build a bare `FastAPI` app outside the framework):

```python
from fastapi import FastAPI
from fastapi_factory_utilities.core.app import register_exception_handlers


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

## CSRF configuration

CSRF is opt-in. Put an `AppCsrfConfig` under `csrf:` in `application.yaml` (or build an equivalent `RootConfig`), then call the zero-arg helper from `configure()`:

```yaml
csrf:
  secret: "${CSRF_SECRET}"
  cookie_samesite: Strict   # Lax | Strict | None
  cookie_secure: true
```

```python
from fastapi_factory_utilities.core.app import (
    ApplicationAbstract,
    register_csrf_protect_exception_handler,
    register_exception_handlers,
)


class App(ApplicationAbstract):
    def configure(self) -> None:
        self.configure_csrf()  # reads config.csrf; raises if csrf is None
        register_csrf_protect_exception_handler(self.get_asgi_app())
        register_exception_handlers(self.get_asgi_app())
```

`configure_csrf()` maps `AppCsrfConfig` fields onto `fastapi-csrf-protect`:

| Config field | Protect setting |
|---|---|
| `secret` | `secret_key` |
| `cookie_samesite` (lowercased) | `cookie_samesite` |
| `cookie_secure` | `cookie_secure` |

It then stores the resolved `CsrfProtect` instance on `app.state` via `DependsCsrfProtect.import_to_state`.

### Dependency injection

```python
from fastapi import Depends, Request
from fastapi_csrf_protect import CsrfProtect
from fastapi_factory_utilities.core.app import depends_csrf_protect


@router.post("/sensitive")
async def sensitive_action(request: Request, csrf: CsrfProtect = Depends(depends_csrf_protect)) -> None:
    await csrf.validate_csrf(request)
    ...
```

`DependsCsrfProtect.import_to_state(state, csrf_protect)` stores the configured `CsrfProtect`; `export_from_state(state)` returns it. The callable form (`depends_csrf_protect(request)`) is what you use in `Depends(...)`.

### Exception handler

```python
from fastapi_factory_utilities.core.app import register_csrf_protect_exception_handler


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

1. FFU `register_exception_handlers(app)` (validation → 422) — call explicitly in `configure()`.
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

1. Always register validation and CSRF handlers in `configure()` — they are not installed by `ApplicationAbstract.__init__`.
2. Pair CSRF protection with `cookie_secure=True` and `cookie_samesite: Strict` for production deployments.
3. Surface validation errors with `detail` as-is to clients — Pydantic's structure is consistent and machine-friendly.
4. When extending validation behavior, prefer composing custom Pydantic validators instead of replacing the handler.

## Reference

- `src/fastapi_factory_utilities/core/app/handlers.py`
- `src/fastapi_factory_utilities/core/app/csrf.py`
- `src/fastapi_factory_utilities/core/app/config.py` (`AppCsrfConfig`)
- `src/fastapi_factory_utilities/core/app/application.py` (`configure_csrf`)
- See also: [Application framework](application-framework.md), Velmios Exception handling (`velmios-lib` in laelidona/velmios-skills).
