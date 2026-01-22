# Security Headers Reference

This guide documents HTTP security headers for protecting RESTful APIs, including CORS, HSTS, CSP, and other security-related headers.

## Overview

Security headers provide defense-in-depth by instructing browsers and clients how to handle responses securely.

### Defense Layers

| Layer | Headers |
|-------|---------|
| Transport | Strict-Transport-Security |
| Content | Content-Security-Policy, X-Content-Type-Options |
| Framing | X-Frame-Options, Content-Security-Policy |
| Cross-Origin | CORS headers, Cross-Origin-* headers |
| Information | X-Powered-By (remove), Server (minimize) |

---

## CORS (Cross-Origin Resource Sharing)

**Reference**: [RFC 6454](https://datatracker.ietf.org/doc/html/rfc6454) (Origin), [Fetch Standard](https://fetch.spec.whatwg.org/#http-cors-protocol)

### Overview

CORS controls which origins can access your API from browsers. Without proper CORS headers, browsers block cross-origin requests.

### Preflight Requests

For non-simple requests, browsers send a preflight OPTIONS request.

**Preflight Request:**
```
OPTIONS /api/orders HTTP/1.1
Host: api.example.com
Origin: https://app.example.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, Authorization
```

**Preflight Response:**
```
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Max-Age: 86400
```

### CORS Headers

**Response Headers:**

| Header | Description | Example |
|--------|-------------|---------|
| Access-Control-Allow-Origin | Allowed origin(s) | `https://app.example.com` or `*` |
| Access-Control-Allow-Methods | Allowed HTTP methods | `GET, POST, PUT, DELETE` |
| Access-Control-Allow-Headers | Allowed request headers | `Content-Type, Authorization` |
| Access-Control-Expose-Headers | Headers client can access | `X-Request-ID, X-RateLimit-Remaining` |
| Access-Control-Allow-Credentials | Allow cookies/auth | `true` |
| Access-Control-Max-Age | Preflight cache duration (seconds) | `86400` |

### CORS Configurations

**Public API (No Credentials):**
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

**Specific Origin with Credentials:**
```
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 86400
```

**Multiple Origins (Dynamic):**

Cannot use multiple origins in header. Server must:
1. Check `Origin` header against allowlist
2. Return matching origin in `Access-Control-Allow-Origin`
3. Include `Vary: Origin` header

### CORS Best Practices

| Practice | Reason |
|----------|--------|
| Never use `*` with credentials | Browsers block this combination |
| Whitelist specific origins | Avoid wildcards in production |
| Set appropriate Max-Age | Reduce preflight requests |
| Limit exposed headers | Minimize information disclosure |
| Validate Origin header | Prevent unauthorized access |

### CORS Errors

| Error | Cause | Solution |
|-------|-------|----------|
| No 'Access-Control-Allow-Origin' | Missing header | Add CORS headers |
| Origin not allowed | Origin not in allowlist | Add origin to allowlist |
| Credentials with wildcard | `*` with credentials | Use specific origin |
| Header not allowed | Missing in Allow-Headers | Add header to list |
| Method not allowed | Missing in Allow-Methods | Add method to list |

---

## Strict-Transport-Security (HSTS)

**Reference**: [RFC 6797](https://datatracker.ietf.org/doc/html/rfc6797)

### Overview

HSTS tells browsers to only access the site over HTTPS, preventing protocol downgrade attacks.

### Header Format

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

### Directives

| Directive | Description | Recommended |
|-----------|-------------|-------------|
| max-age | Duration in seconds | 31536000 (1 year) |
| includeSubDomains | Apply to all subdomains | Include if all subdomains support HTTPS |
| preload | Eligible for preload list | Include for maximum protection |

### Deployment Stages

| Stage | Configuration | Duration |
|-------|---------------|----------|
| Testing | `max-age=300` | 5 minutes |
| Initial | `max-age=86400` | 1 day |
| Production | `max-age=31536000` | 1 year |
| Preload | `max-age=31536000; includeSubDomains; preload` | 1 year+ |

### HSTS Preload

Submit to [hstspreload.org](https://hstspreload.org) to be included in browser preload lists.

**Requirements:**
1. Valid HTTPS certificate
2. Redirect HTTP to HTTPS
3. Serve HSTS header with:
   - `max-age` ≥ 31536000
   - `includeSubDomains`
   - `preload`

### Best Practices

| Practice | Reason |
|----------|--------|
| Start with short max-age | Easier to recover from mistakes |
| Test all subdomains first | includeSubDomains affects all |
| Consider preload carefully | Difficult to undo |
| Include on all responses | Not just HTML pages |

---

## Content-Security-Policy (CSP)

**Reference**: [W3C CSP Level 3](https://www.w3.org/TR/CSP3/)

### Overview

CSP controls which resources the browser can load, preventing XSS and data injection attacks.

### Header Format

```
Content-Security-Policy: directive1 value1; directive2 value2
```

### Common Directives

| Directive | Description | Example |
|-----------|-------------|---------|
| default-src | Default for all resource types | `'self'` |
| script-src | JavaScript sources | `'self' 'unsafe-inline'` |
| style-src | CSS sources | `'self' 'unsafe-inline'` |
| img-src | Image sources | `'self' data: https:` |
| font-src | Font sources | `'self' https://fonts.googleapis.com` |
| connect-src | XHR, WebSocket, fetch | `'self' https://api.example.com` |
| frame-src | Frame/iframe sources | `'none'` |
| object-src | Plugin sources (Flash) | `'none'` |
| base-uri | Allowed base URIs | `'self'` |
| form-action | Form submission targets | `'self'` |
| frame-ancestors | Who can embed this page | `'none'` |
| upgrade-insecure-requests | Upgrade HTTP to HTTPS | (no value) |

### Source Values

| Value | Description |
|-------|-------------|
| `'self'` | Same origin |
| `'none'` | Block all |
| `'unsafe-inline'` | Allow inline scripts/styles (avoid) |
| `'unsafe-eval'` | Allow eval() (avoid) |
| `'strict-dynamic'` | Trust scripts loaded by trusted scripts |
| `https:` | Any HTTPS URL |
| `data:` | Data URIs |
| `https://example.com` | Specific origin |
| `nonce-{base64}` | Specific inline script/style |
| `sha256-{hash}` | Script/style with matching hash |

### API-Specific CSP

For JSON APIs, a restrictive CSP is recommended:

```
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
```

### CSP Reporting

**Report-Only Mode:**
```
Content-Security-Policy-Report-Only: default-src 'self'; report-uri /csp-report
```

**Reporting Endpoint:**
```
Content-Security-Policy: default-src 'self'; report-uri /csp-report; report-to csp-endpoint
Report-To: {"group":"csp-endpoint","max_age":86400,"endpoints":[{"url":"/csp-report"}]}
```

### Best Practices

| Practice | Reason |
|----------|--------|
| Start with report-only | Monitor before enforcing |
| Avoid unsafe-inline | Major XSS vector |
| Use nonces or hashes | For necessary inline scripts |
| Set frame-ancestors | Prevent clickjacking |
| Review reports regularly | Identify issues |

---

## X-Content-Type-Options

**Reference**: [Fetch Standard](https://fetch.spec.whatwg.org/#x-content-type-options-header)

### Overview

Prevents MIME type sniffing, forcing browsers to use declared Content-Type.

### Header

```
X-Content-Type-Options: nosniff
```

### Effect

| Scenario | Without nosniff | With nosniff |
|----------|-----------------|--------------|
| JS served as text/plain | May execute | Blocked |
| HTML served as image | May render | Blocked |
| CSS served incorrectly | May apply | Blocked |

### Best Practice

Always include on all responses:

```
X-Content-Type-Options: nosniff
```

---

## X-Frame-Options

**Reference**: [RFC 7034](https://datatracker.ietf.org/doc/html/rfc7034)

### Overview

Controls whether the page can be embedded in frames, preventing clickjacking.

**Note**: CSP `frame-ancestors` is the modern replacement.

### Header Values

| Value | Description |
|-------|-------------|
| DENY | Cannot be framed by any site |
| SAMEORIGIN | Only same origin can frame |
| ALLOW-FROM uri | Specific origin can frame (deprecated) |

### Recommended

```
X-Frame-Options: DENY
```

Or with CSP:
```
Content-Security-Policy: frame-ancestors 'none'
```

---

## Cross-Origin Headers

### Cross-Origin-Opener-Policy (COOP)

Controls window.opener relationship.

```
Cross-Origin-Opener-Policy: same-origin
```

| Value | Description |
|-------|-------------|
| unsafe-none | Default, allow opener |
| same-origin-allow-popups | Isolate but allow popups |
| same-origin | Full isolation |

### Cross-Origin-Embedder-Policy (COEP)

Controls embedding of cross-origin resources.

```
Cross-Origin-Embedder-Policy: require-corp
```

| Value | Description |
|-------|-------------|
| unsafe-none | Default |
| require-corp | Require CORP/CORS on all resources |

### Cross-Origin-Resource-Policy (CORP)

Controls who can embed this resource.

```
Cross-Origin-Resource-Policy: same-origin
```

| Value | Description |
|-------|-------------|
| same-site | Same site only |
| same-origin | Same origin only |
| cross-origin | Any origin |

---

## Information Disclosure Headers

### Headers to Remove or Minimize

| Header | Risk | Action |
|--------|------|--------|
| Server | Reveals server software | Remove or genericize |
| X-Powered-By | Reveals framework | Remove |
| X-AspNet-Version | Reveals ASP.NET version | Remove |
| X-AspNetMvc-Version | Reveals MVC version | Remove |

### Recommended Server Header

Instead of:
```
Server: Apache/2.4.41 (Ubuntu)
```

Use:
```
Server: API
```

Or remove entirely.

---

## Referrer-Policy

Controls Referer header sent with requests.

```
Referrer-Policy: strict-origin-when-cross-origin
```

| Value | Description |
|-------|-------------|
| no-referrer | Never send |
| no-referrer-when-downgrade | Don't send on HTTPS→HTTP |
| origin | Send origin only |
| origin-when-cross-origin | Full URL same-origin, origin cross-origin |
| same-origin | Only for same-origin |
| strict-origin | Origin, but not on downgrade |
| strict-origin-when-cross-origin | Recommended default |
| unsafe-url | Always send full URL |

---

## Permissions-Policy (Feature-Policy)

Controls browser features available to the page.

```
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

### Common Permissions

| Permission | Description |
|------------|-------------|
| geolocation | Location access |
| microphone | Microphone access |
| camera | Camera access |
| payment | Payment API |
| usb | USB access |
| fullscreen | Fullscreen API |

### API Recommendation

For APIs that don't need browser features:

```
Permissions-Policy: accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()
```

---

## Complete API Security Headers

### Recommended Set for APIs

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()
Cache-Control: no-store
```

### With CORS (for browser clients)

Add CORS headers as appropriate:

```
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 86400
```

---

## Security Headers Checklist

### Essential (Always Include)

- [ ] Strict-Transport-Security
- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options or CSP frame-ancestors

### Recommended

- [ ] Content-Security-Policy
- [ ] Referrer-Policy
- [ ] Permissions-Policy

### CORS (If Needed)

- [ ] Access-Control-Allow-Origin (specific origins)
- [ ] Access-Control-Allow-Methods
- [ ] Access-Control-Allow-Headers
- [ ] Access-Control-Max-Age
- [ ] Vary: Origin (for dynamic CORS)

### Remove

- [ ] Server (or minimize)
- [ ] X-Powered-By
- [ ] Other framework-specific headers

---

## Testing Security Headers

### Online Tools

| Tool | URL |
|------|-----|
| SecurityHeaders.com | https://securityheaders.com |
| Mozilla Observatory | https://observatory.mozilla.org |
| CSP Evaluator | https://csp-evaluator.withgoogle.com |

### Command Line

```bash
curl -I https://api.example.com/health
```

### What to Check

| Header | Expected |
|--------|----------|
| Strict-Transport-Security | Present with max-age ≥ 31536000 |
| X-Content-Type-Options | nosniff |
| X-Frame-Options | DENY or SAMEORIGIN |
| Content-Security-Policy | Restrictive policy |
| Server | Minimal or absent |
| X-Powered-By | Absent |

---

## Related Documentation

- [OAuth2 Flows Reference](oauth2-flows.md) - Authentication security
- [Webhook Security Reference](webhook-security.md) - Webhook protection
- [Caching Strategies Reference](caching-strategies.md) - Cache security
