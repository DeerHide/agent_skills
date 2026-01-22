# Caching Strategies Reference

This guide documents HTTP caching strategies for RESTful APIs, including Cache-Control directives, ETags, and CDN patterns.

**Primary Reference**: [RFC 7234](https://datatracker.ietf.org/doc/html/rfc7234) - HTTP/1.1 Caching

## Overview

HTTP caching improves performance by storing responses and reusing them for subsequent requests, reducing latency and server load.

### Caching Benefits

| Benefit | Description |
|---------|-------------|
| Reduced Latency | Serve from cache instead of origin |
| Lower Server Load | Fewer requests reach backend |
| Bandwidth Savings | Smaller responses (304 Not Modified) |
| Improved Reliability | Serve stale content during outages |

### Cache Locations

| Location | Description | Controlled By |
|----------|-------------|---------------|
| Browser Cache | User's browser | Cache-Control, Expires |
| Proxy Cache | Intermediate proxies | Cache-Control, Vary |
| CDN Cache | Content delivery network | Cache-Control, s-maxage |
| Application Cache | Application-level cache | Application logic |

---

## Cache-Control Header

The `Cache-Control` header is the primary mechanism for controlling caching behavior.

### Request Directives

| Directive | Description |
|-----------|-------------|
| no-cache | Validate with origin before using cached response |
| no-store | Do not cache this request/response |
| max-age=N | Accept cached response up to N seconds old |
| max-stale[=N] | Accept stale response (optionally up to N seconds) |
| min-fresh=N | Response must be fresh for at least N seconds |
| only-if-cached | Only return cached response, fail if none |

### Response Directives

| Directive | Description |
|-----------|-------------|
| public | Response can be cached by any cache |
| private | Response only for single user (browser cache only) |
| no-cache | Cache but validate before use |
| no-store | Do not cache response |
| max-age=N | Response is fresh for N seconds |
| s-maxage=N | Shared cache max age (overrides max-age) |
| must-revalidate | Must revalidate after becoming stale |
| proxy-revalidate | Proxy must revalidate after stale |
| immutable | Response will never change |
| stale-while-revalidate=N | Serve stale while revalidating for N seconds |
| stale-if-error=N | Serve stale if error for N seconds |

### Common Patterns

**Static Assets (Immutable):**
```
Cache-Control: public, max-age=31536000, immutable
```
- Cache for 1 year
- Used for versioned assets (e.g., `/app.v2.js`)

**API Responses (Short TTL):**
```
Cache-Control: private, max-age=60
```
- Cache for 1 minute
- Browser cache only

**User-Specific Data:**
```
Cache-Control: private, no-cache
```
- Don't cache in shared caches
- Validate on each request

**Sensitive Data:**
```
Cache-Control: no-store
```
- Never cache
- Used for passwords, tokens, PII

**CDN Optimization:**
```
Cache-Control: public, max-age=60, s-maxage=3600, stale-while-revalidate=60
```
- Browser: 1 minute
- CDN: 1 hour
- Serve stale while revalidating

**Resilient Caching:**
```
Cache-Control: public, max-age=300, stale-if-error=86400
```
- Fresh for 5 minutes
- Serve stale for up to 24 hours on error

---

## ETags and Validation

### ETag Header

ETags provide resource version identifiers for cache validation.

**Strong ETag:**
```
ETag: "abc123def456"
```
- Byte-for-byte identical
- Use for Range requests

**Weak ETag:**
```
ETag: W/"abc123def456"
```
- Semantically equivalent
- Minor differences acceptable

### Generating ETags

| Method | Description | Pros | Cons |
|--------|-------------|------|------|
| Content Hash | MD5/SHA of response body | Accurate | CPU intensive |
| Version Field | Database version/revision | Fast | Requires schema |
| Timestamp | Last-Modified as string | Simple | Second resolution |
| Composite | Combine multiple fields | Flexible | Complex |

### Last-Modified Header

```
Last-Modified: Thu, 23 Jan 2026 10:30:00 GMT
```

**When to Use:**

| Scenario | ETag | Last-Modified |
|----------|------|---------------|
| Dynamic content | Preferred | Optional |
| Static files | Optional | Preferred |
| High precision needed | Required | Optional |
| Multiple representations | Required | Not sufficient |

### Validation Requests

**If-None-Match (ETag validation):**
```
GET /orders/123 HTTP/1.1
If-None-Match: "abc123def456"
```

**If-Modified-Since (Timestamp validation):**
```
GET /orders/123 HTTP/1.1
If-Modified-Since: Thu, 23 Jan 2026 10:30:00 GMT
```

**Server Response:**

| Condition | Response |
|-----------|----------|
| Not modified | 304 Not Modified (no body) |
| Modified | 200 OK (full response) |

---

## Vary Header

The `Vary` header indicates which request headers affect the response, enabling proper cache key generation.

### Usage

```
Vary: Accept, Accept-Encoding, Authorization
```

### Common Vary Headers

| Header | When to Include |
|--------|-----------------|
| Accept | Content negotiation (JSON/XML) |
| Accept-Encoding | Compression (gzip/br) |
| Accept-Language | Localized content |
| Authorization | User-specific responses |
| Origin | CORS responses |

### Cache Key Impact

With `Vary: Accept`:
- `GET /orders` + `Accept: application/json` → Cache key A
- `GET /orders` + `Accept: application/xml` → Cache key B

### Best Practices

1. **Minimize Vary headers**: More headers = more cache variants
2. **Avoid Vary: *** : Effectively disables caching
3. **Normalize headers**: Consistent header values improve hit rates
4. **Consider CDN behavior**: Some CDNs handle Vary differently

---

## Age Header

The `Age` header indicates how long a response has been in cache.

```
Age: 120
```

This response has been cached for 120 seconds.

### Freshness Calculation

```
response_is_fresh = (max-age - Age) > 0
```

---

## Expires Header (Legacy)

The `Expires` header specifies an absolute expiration time.

```
Expires: Thu, 23 Jan 2026 12:00:00 GMT
```

**Note**: `Cache-Control: max-age` takes precedence over `Expires`.

### When to Use

| Scenario | Recommendation |
|----------|----------------|
| Modern clients | Use Cache-Control |
| Legacy support | Include both |
| CDN compatibility | Check CDN documentation |

---

## Caching Strategies by Resource Type

### Static Assets

**Versioned Files** (app.v2.js, style.abc123.css):
```
Cache-Control: public, max-age=31536000, immutable
```

**Unversioned Files** (logo.png):
```
Cache-Control: public, max-age=86400
ETag: "abc123"
```

### API Responses

**Collection Endpoints** (GET /orders):
```
Cache-Control: private, max-age=30, stale-while-revalidate=60
ETag: "collection-v123"
Vary: Authorization, Accept
```

**Single Resource** (GET /orders/123):
```
Cache-Control: private, max-age=60
ETag: "v1-abc123"
Vary: Authorization
```

**User-Specific Data** (GET /me/profile):
```
Cache-Control: private, no-cache
ETag: "profile-v456"
Vary: Authorization
```

**Public Data** (GET /products):
```
Cache-Control: public, max-age=300, s-maxage=3600
ETag: "products-v789"
Vary: Accept
```

### Real-Time Data

**Stock Prices, Live Scores:**
```
Cache-Control: no-store
```

**Frequently Updated:**
```
Cache-Control: private, max-age=5, stale-while-revalidate=10
```

---

## CDN Caching

### CDN-Specific Headers

**Surrogate-Control** (Varnish, Fastly):
```
Surrogate-Control: max-age=3600
Cache-Control: max-age=60
```
- CDN uses Surrogate-Control (1 hour)
- Browser uses Cache-Control (1 minute)

**CDN-Cache-Control** (Cloudflare):
```
CDN-Cache-Control: max-age=3600
Cache-Control: max-age=60
```

### Cache Invalidation

**Purge Strategies:**

| Strategy | Description | Use Case |
|----------|-------------|----------|
| Single URL | Purge specific URL | Content update |
| Tag-based | Purge by cache tag | Related content |
| Prefix | Purge URL prefix | Section update |
| Full | Purge entire cache | Emergency |

**Cache Tags:**
```
Cache-Tag: product, product-123, category-electronics
Surrogate-Key: product product-123 category-electronics
```

### Edge-Side Includes (ESI)

Compose pages from cached fragments:

```html
<esi:include src="/fragments/header" />
<main>
  Page-specific content
</main>
<esi:include src="/fragments/footer" />
```

---

## Cache Busting

### URL Versioning

**Query String:**
```
/app.js?v=2.0.0
/style.css?hash=abc123
```

**Filename:**
```
/app.v2.0.0.js
/style.abc123.css
```

**Path:**
```
/v2/app.js
/assets/2.0.0/style.css
```

### Comparison

| Method | Pros | Cons |
|--------|------|------|
| Query String | Simple | Some caches ignore |
| Filename | Reliable | Requires build process |
| Path | Clear versioning | URL structure change |

---

## Conditional Requests for Updates

### Optimistic Concurrency

**Request:**
```
PUT /orders/123 HTTP/1.1
If-Match: "v1-abc123"
Content-Type: application/json

{"status": "shipped"}
```

**Responses:**

| Condition | Status | Description |
|-----------|--------|-------------|
| ETag matches | 200 OK | Update successful |
| ETag mismatch | 412 Precondition Failed | Conflict |
| No If-Match | 200 OK | Update without check |

### Lost Update Prevention

1. Client A reads order (ETag: "v1")
2. Client B reads order (ETag: "v1")
3. Client A updates with If-Match: "v1" → Success (ETag: "v2")
4. Client B updates with If-Match: "v1" → 412 Precondition Failed

---

## Caching Anti-Patterns

### Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Cache everything | Stale data issues | Appropriate max-age |
| Cache nothing | Performance issues | Enable caching |
| Vary: * | Disables caching | Specific headers |
| No ETag on dynamic | No validation | Generate ETags |
| Long TTL without versioning | Stale assets | Use cache busting |
| Cache POST responses | Unexpected behavior | Only cache GET/HEAD |

### Security Considerations

**Never Cache:**
- Responses with `Authorization` header (unless Vary: Authorization)
- Sensitive personal data
- Authentication tokens in response body
- Error responses with sensitive info

**Always Validate:**
- User-specific data
- Permission-controlled resources
- Time-sensitive information

---

## Monitoring and Debugging

### Debug Headers

**Request Headers for Debugging:**
```
Cache-Control: no-cache
Pragma: no-cache
```

**CDN Debug Headers:**

| CDN | Header | Values |
|-----|--------|--------|
| Cloudflare | CF-Cache-Status | HIT, MISS, EXPIRED, BYPASS |
| Fastly | X-Cache | HIT, MISS |
| Akamai | X-Cache | TCP_HIT, TCP_MISS |

### Metrics to Track

| Metric | Description | Target |
|--------|-------------|--------|
| Cache Hit Ratio | Requests served from cache | >80% |
| Origin Traffic | Requests reaching origin | Minimize |
| Cache Latency | Time to serve from cache | <50ms |
| Validation Rate | 304 vs 200 responses | Depends on TTL |

---

## Related Documentation

- [Advanced REST Patterns Reference](advanced-rest-patterns.md) - Conditional requests
- [Security Headers Reference](security-headers.md) - Cache security
- [Webhooks Implementation Guide](webhooks-implementation-guide.md) - Cache invalidation via webhooks
