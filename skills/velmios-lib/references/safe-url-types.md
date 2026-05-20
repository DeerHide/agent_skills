# Safe URL types

## When to use

- Validating configuration or API fields that MUST be **HTTPS** and hosted on a **Velmios-controlled domain** (`*.velmios.io`).
- Constraining specific URLs to the `api.`, `auth.`, or `portal.` subdomains.

## Overview

`VelmiosSafeUrl` is a `str` subclass that validates each value:

- URL parses as HTTP(S) via Pydantic `HttpUrl` semantics.
- Scheme MUST be `https`.
- Host MUST end with `.velmios.io`.

Specialized subclasses narrow the host further:

| Type | Additional host constraint |
|---|---|
| `VelmiosSafeUrl` | none beyond `*.velmios.io` |
| `VelmiosApiSafeUrl` | host MUST start with `api.` |
| `VelmiosAuthSafeUrl` | host MUST start with `auth.` |
| `VelmiosPortalSafeUrl` | host MUST start with `portal.` |

All four are imported from `velmios.core.types`.

```python
from velmios.core.types import VelmiosApiSafeUrl

api_base = VelmiosApiSafeUrl("https://api.example.velmios.io/")
```

`HttpUrl` validation lets each subclass reuse pydantic's schema while keeping the type a plain `str` subclass for use on entities, config models, and FastAPI request/response schemas.

## Reference

- `src/velmios/core/types/safe_url.py`
- `src/velmios/core/types/__init__.py`
