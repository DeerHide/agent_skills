# Safe URL types

## When to use

- Validating configuration or API fields that MUST be **HTTPS** and hosted on a **Velmios-controlled domain** (`*.velmios.io`).

## Overview

**`VelmiosSafeUrl`** (`str` subclass) validates:

- URL parses as HTTP(S) via Pydantic **`HttpUrl`** semantics exposed through validation.
- Scheme is **`https`**.
- Host ends with **`.velmios.io`**.

Specialized aliases narrow intent for documentation and typing:

| Type | Typical use |
|---|---|
| **`VelmiosSafeUrl`** | Base validated URL |
| **`VelmiosApiSafeUrl`** | API base URLs |
| **`VelmiosAuthSafeUrl`** | Auth / OIDC-related URLs |
| **`VelmiosPortalSafeUrl`** | Portal or UI URLs |

All are imported from **`velmios.core.types`**.

```python
from velmios.core.types import VelmiosApiSafeUrl

api_base = VelmiosApiSafeUrl("https://api.example.velmios.io/")
```

## Reference

- `src/velmios/core/types/safe_url.py`
- `src/velmios/core/types/__init__.py`
