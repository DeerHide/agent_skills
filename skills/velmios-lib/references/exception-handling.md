# Exception handling

## When to use

- Standardizing **401 / 403 / 422 / 500** response envelopes across Velmios microservices.
- Emitting telemetry for **authentication and authorization failures**.
- Adding **service-specific detail enrichment** without losing shared telemetry.

## Overview

Velmios ships a small handler stack that layers on top of FastAPI / FFU error handling:

```python
from velmios.core.security import (
    HTTPExceptionDetailEnricher,
    register_security_exception_handlers,
    VelmiosNotAuthenticatedError,
    VelmiosSecurityError,
)
```

CSRF and request-validation handlers come from `fastapi-factory-utilities` (`register_csrf_protect_exception_handler`, `register_exception_handlers`). The Velmios application abstract registers all three sets in `velmios_configure()` (see [Application](application.md)).

## register_security_exception_handlers(app, *, http_exception_detail_enricher=None)

Registers four handlers on the FastAPI app:

| Exception | Status | Notes |
|---|---|---|
| `VelmiosNotAuthenticatedError` | **401** | Plain `JSONResponse(detail=str(exc))`. |
| `VelmiosSecurityError` | **401** | Same plain envelope. |
| `PermissionsRequiredError` | **403** | Delegated to the global `HTTPException` handler with `detail=HTTPStatus.FORBIDDEN.phrase`. |
| `HTTPException` (catch-all) | exc.status_code | Wrapped via `create_http_exception_handler(detail_enricher)`; emits auth-failure telemetry for 401 / 403. |

The global `HTTPException` handler:

1. Reads `exc.detail`; defaults to `HTTPStatus(status_code).phrase` when the detail is not a string (e.g. validation arrays).
2. Calls `detail_enricher(request, exc, detail)` when provided.
3. For 401 / 403, calls `_emit_http_auth_failure_telemetry(...)`.
4. Returns `JSONResponse(status_code=status_code, content=jsonable_encoder({"detail": detail}))`.

## HTTPExceptionDetailEnricher

```python
HTTPExceptionDetailEnricher: TypeAlias = Callable[[Request, HTTPException, str], str]
```

Override on the application via `get_http_exception_detail_enricher()` to add service-specific hints (e.g. include the missing scope name or a docs link) while keeping the central telemetry intact. The same enricher receives every `HTTPException` flowing through the central handler — gate on `exc.status_code` to scope the change.

## Telemetry

For 401 / 403 responses, the handler:

- **Counter** `velmios.security.auth_failures` (unit `1`) incremented with labels:
  - `http.status_code`
  - `http.method`
  - `http.route`
  - `service.name` (from `request.app.state.config.application.service_name`; falls back to `"velmios-backend"`)
  - `auth.failure_type` — `authentication` for 401, `authorization` for 403.
- Structured **log** `security_auth_failure` with method, URL path, status, detail, `auth_failure_type`, user agent, and client host.
- Active **span** decoration when recording: records the exception, sets `security.event=auth_failure`, `http.status_code`, `http.method`, `http.route`, and `auth.failure_type`.

## Mapping table

| Source | Result | Status |
|---|---|---|
| `VelmiosNotAuthenticatedError` (resolver / hooks) | `{"detail": "..."}` | 401 |
| `VelmiosSecurityError` (custom security flows) | `{"detail": "..."}` | 401 |
| `PermissionsRequiredError` (composable permissions) | `{"detail": "Forbidden"}` | 403 |
| `HTTPException(403)` raised by resource APIs / use cases (`USE_CASE_NOT_ALLOWED_ERROR`, `USE_CASE_SEGMENTATION_ERROR`) | `{"detail": "..."}` | 403 |
| `HTTPException(404)` (resource API not-found mapping) | `{"detail": "..."}` | 404 |
| Request body / pagination validation (`RequestValidationError`, JSON parse) | structured `detail` list | 422 |
| CSRF rejection (`CsrfProtectError`) | structured `detail` | 403 |
| Unmapped `HTTPException` | `{"detail": "..."}` | exc.status_code |

Validation handlers (HTTP 422) and CSRF handlers (HTTP 403) come from `fastapi-factory-utilities` — see the [FFU CSRF & validation reference](../../fastapi-factory-utilities/references/csrf-and-validation.md). The Velmios security counter only fires on the 401 / 403 paths.

## Best practices

1. Always call `register_security_exception_handlers(app, http_exception_detail_enricher=...)` after `register_exception_handlers` and `register_csrf_protect_exception_handler` so the central handler "wins" on `HTTPException`.
2. Keep enrichers idempotent and cheap; they run inside the response path.
3. Use the OpenTelemetry counter and structured log to wire dashboards/alerts on `auth_failure_type=authentication` (login problems) vs `authorization` (RBAC misconfiguration).
4. Don't translate `PermissionsRequiredError` to `HTTPException` manually — let the registered handler do it so telemetry and envelope stay consistent.
5. Surface validation errors as 422 (FFU default); reserve 400 for genuinely malformed protocol-level requests.

## Reference

- `src/velmios/core/security/handlers.py`
- `src/velmios/core/security/exceptions.py`
- `src/velmios/core/app/applications.py`
- See also: [Authentication](authentication.md), [Authorization dependencies](authorization-dependencies.md), [Permissions](permissions.md), [FFU CSRF & validation](../../fastapi-factory-utilities/references/csrf-and-validation.md).
