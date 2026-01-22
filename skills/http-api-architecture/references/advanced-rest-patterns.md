# Advanced REST Patterns Reference

This guide documents advanced RESTful API patterns including HATEOAS, conditional requests, and rate limiting strategies.

## HATEOAS (Hypermedia as the Engine of Application State)

### Overview

HATEOAS is a REST constraint where clients interact with the API entirely through hypermedia provided dynamically by server responses. The client needs no prior knowledge of how to interact with the server beyond a generic understanding of hypermedia.

**Reference**: HATEOAS is part of the REST architectural style defined by Roy Fielding. Related standards include [RFC 5988](https://datatracker.ietf.org/doc/html/rfc5988) (Web Linking) and [RFC 8288](https://datatracker.ietf.org/doc/html/rfc8288) (Web Linking updated).

### Benefits

| Benefit | Description |
|---------|-------------|
| Discoverability | Clients discover available actions from responses |
| Evolvability | Server can change URIs without breaking clients |
| Self-Documentation | Responses describe what's possible |
| Reduced Coupling | Clients don't hardcode URIs |

### Link Relations

Standard link relations are defined by IANA ([Link Relations Registry](https://www.iana.org/assignments/link-relations/link-relations.xhtml)).

**Common Link Relations:**

| Relation | Description |
|----------|-------------|
| self | Link to the current resource |
| next | Next page in a collection |
| prev | Previous page in a collection |
| first | First page in a collection |
| last | Last page in a collection |
| collection | Parent collection |
| item | Item in a collection |
| edit | Editable version of resource |
| related | Related resource |

### Response Formats

**HAL (Hypertext Application Language):**

```json
{
  "id": "ord_123456",
  "status": "pending",
  "total": 99.99,
  "_links": {
    "self": {
      "href": "/orders/ord_123456"
    },
    "cancel": {
      "href": "/orders/ord_123456/cancel",
      "method": "POST"
    },
    "payment": {
      "href": "/orders/ord_123456/payment"
    },
    "customer": {
      "href": "/customers/cus_789"
    }
  },
  "_embedded": {
    "items": [
      {
        "id": "item_111",
        "name": "Product A",
        "_links": {
          "self": { "href": "/products/prod_111" }
        }
      }
    ]
  }
}
```

**JSON:API Format:**

```json
{
  "data": {
    "type": "orders",
    "id": "ord_123456",
    "attributes": {
      "status": "pending",
      "total": 99.99
    },
    "relationships": {
      "customer": {
        "links": {
          "related": "/orders/ord_123456/customer"
        },
        "data": { "type": "customers", "id": "cus_789" }
      }
    },
    "links": {
      "self": "/orders/ord_123456"
    }
  },
  "links": {
    "self": "/orders/ord_123456"
  }
}
```

**Collection with Pagination Links:**

```json
{
  "data": [...],
  "_links": {
    "self": { "href": "/orders?page=2&limit=20" },
    "first": { "href": "/orders?page=1&limit=20" },
    "prev": { "href": "/orders?page=1&limit=20" },
    "next": { "href": "/orders?page=3&limit=20" },
    "last": { "href": "/orders?page=10&limit=20" }
  },
  "_meta": {
    "total": 200,
    "page": 2,
    "limit": 20
  }
}
```

### State-Based Links

Only include links for valid actions based on current state:

**Order in "pending" state:**
```json
{
  "id": "ord_123456",
  "status": "pending",
  "_links": {
    "self": { "href": "/orders/ord_123456" },
    "cancel": { "href": "/orders/ord_123456/cancel" },
    "pay": { "href": "/orders/ord_123456/pay" }
  }
}
```

**Order in "shipped" state:**
```json
{
  "id": "ord_123456",
  "status": "shipped",
  "_links": {
    "self": { "href": "/orders/ord_123456" },
    "track": { "href": "/orders/ord_123456/tracking" }
  }
}
```

Note: "cancel" and "pay" links are not present because those actions are no longer valid.

---

## Conditional Requests

Conditional requests allow clients to make requests conditional on the state of the resource, reducing bandwidth and improving efficiency.

**References**: 
- [RFC 7232](https://datatracker.ietf.org/doc/html/rfc7232) - Conditional Requests
- [RFC 7234](https://datatracker.ietf.org/doc/html/rfc7234) - Caching

### ETags (Entity Tags)

ETags are opaque identifiers for specific versions of resources.

**Types of ETags:**

| Type | Format | Description |
|------|--------|-------------|
| Strong | `"abc123"` | Byte-for-byte identical |
| Weak | `W/"abc123"` | Semantically equivalent |

**Generating ETags:**

| Method | Description | Use Case |
|--------|-------------|----------|
| Content Hash | Hash of response body | Static content |
| Version Number | Resource version/revision | Versioned resources |
| Last Modified | Timestamp-based | Time-sensitive resources |
| Composite | Combination of above | Complex resources |

### Conditional Headers

**Request Headers:**

| Header | Purpose | Used With |
|--------|---------|-----------|
| If-Match | Proceed if ETag matches | PUT, PATCH, DELETE |
| If-None-Match | Proceed if ETag doesn't match | GET (caching) |
| If-Modified-Since | Proceed if modified after date | GET (caching) |
| If-Unmodified-Since | Proceed if not modified after date | PUT, PATCH, DELETE |

**Response Headers:**

| Header | Purpose |
|--------|---------|
| ETag | Entity tag for the resource |
| Last-Modified | Last modification timestamp |

### GET with Conditional Caching

**First Request:**
```
GET /orders/123 HTTP/1.1
Host: api.example.com
```

**Response:**
```
HTTP/1.1 200 OK
ETag: "v1-abc123"
Last-Modified: Thu, 23 Jan 2026 10:30:00 GMT
Cache-Control: private, max-age=60

{
  "id": "123",
  "status": "pending"
}
```

**Subsequent Request (Validation):**
```
GET /orders/123 HTTP/1.1
Host: api.example.com
If-None-Match: "v1-abc123"
If-Modified-Since: Thu, 23 Jan 2026 10:30:00 GMT
```

**Response (Not Modified):**
```
HTTP/1.1 304 Not Modified
ETag: "v1-abc123"
```

**Response (Modified):**
```
HTTP/1.1 200 OK
ETag: "v2-def456"
Last-Modified: Thu, 23 Jan 2026 11:00:00 GMT

{
  "id": "123",
  "status": "shipped"
}
```

### PUT/PATCH with Optimistic Concurrency

**Update Request:**
```
PUT /orders/123 HTTP/1.1
Host: api.example.com
If-Match: "v1-abc123"
Content-Type: application/json

{
  "status": "confirmed"
}
```

**Success Response:**
```
HTTP/1.1 200 OK
ETag: "v2-def456"

{
  "id": "123",
  "status": "confirmed"
}
```

**Conflict Response (ETag mismatch):**
```
HTTP/1.1 412 Precondition Failed
Content-Type: application/problem+json

{
  "type": "https://api.example.com/errors/precondition-failed",
  "title": "Precondition Failed",
  "status": 412,
  "detail": "Resource has been modified since last retrieval"
}
```

### DELETE with Precondition

```
DELETE /orders/123 HTTP/1.1
Host: api.example.com
If-Match: "v1-abc123"
```

**Success:**
```
HTTP/1.1 204 No Content
```

**Conflict:**
```
HTTP/1.1 412 Precondition Failed
```

---

## Rate Limiting

### Overview

Rate limiting protects APIs from abuse and ensures fair usage among clients.

**References**:
- [RFC 6585](https://datatracker.ietf.org/doc/html/rfc6585) - 429 Too Many Requests
- [IETF Draft: RateLimit Header Fields](https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/)

### Rate Limit Headers

**Standard Headers:**

| Header | Description | Example |
|--------|-------------|---------|
| X-RateLimit-Limit | Maximum requests per window | `1000` |
| X-RateLimit-Remaining | Requests remaining in window | `999` |
| X-RateLimit-Reset | Unix timestamp when window resets | `1706140800` |
| Retry-After | Seconds until rate limit resets | `60` |

**IETF Draft Headers:**

| Header | Description | Example |
|--------|-------------|---------|
| RateLimit-Limit | Maximum requests | `1000` |
| RateLimit-Remaining | Remaining requests | `999` |
| RateLimit-Reset | Seconds until reset | `3600` |

### Response Examples

**Normal Response:**
```
HTTP/1.1 200 OK
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1706140800
```

**Rate Limited Response:**
```
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1706140800
Retry-After: 3600
Content-Type: application/problem+json

{
  "type": "https://api.example.com/errors/rate-limit-exceeded",
  "title": "Rate Limit Exceeded",
  "status": 429,
  "detail": "You have exceeded the rate limit of 1000 requests per hour",
  "retry_after": 3600
}
```

### Rate Limiting Algorithms

**Fixed Window:**

| Property | Description |
|----------|-------------|
| Mechanism | Counter resets at fixed intervals |
| Pros | Simple to implement |
| Cons | Burst at window boundaries |
| Example | 1000 requests per hour, resets at :00 |

**Sliding Window Log:**

| Property | Description |
|----------|-------------|
| Mechanism | Track timestamp of each request |
| Pros | Smooth rate limiting |
| Cons | Memory intensive |
| Example | Last 1000 requests within rolling hour |

**Sliding Window Counter:**

| Property | Description |
|----------|-------------|
| Mechanism | Weighted average of current and previous window |
| Pros | Memory efficient, smooth |
| Cons | Slight approximation |
| Example | Interpolate between windows |

**Token Bucket:**

| Property | Description |
|----------|-------------|
| Mechanism | Tokens added at fixed rate, consumed per request |
| Pros | Allows controlled bursts |
| Cons | More complex |
| Example | 10 tokens/second, bucket holds 100 |

**Leaky Bucket:**

| Property | Description |
|----------|-------------|
| Mechanism | Fixed output rate, excess queued or dropped |
| Pros | Consistent output rate |
| Cons | May queue requests |
| Example | Process 10 requests/second |

### Rate Limit Scopes

| Scope | Description | Use Case |
|-------|-------------|----------|
| Global | Across entire API | Overall protection |
| Per User | Per authenticated user | Fair user allocation |
| Per API Key | Per API key/client | Client-level limits |
| Per Endpoint | Per specific endpoint | Protect expensive operations |
| Per IP | Per source IP | Anonymous/unauthenticated |

### Rate Limit Tiers

| Tier | Limit | Use Case |
|------|-------|----------|
| Free | 100/hour | Trial users |
| Basic | 1,000/hour | Standard users |
| Pro | 10,000/hour | Professional users |
| Enterprise | Custom | Large customers |

---

## Content Negotiation

### Accept Header

Clients specify preferred response formats:

```
GET /orders/123 HTTP/1.1
Accept: application/json
```

**Multiple Preferences with Quality:**
```
Accept: application/json;q=1.0, application/xml;q=0.8, text/plain;q=0.5
```

### Content-Type Header

Clients specify request body format:

```
POST /orders HTTP/1.1
Content-Type: application/json

{"item": "Product A"}
```

### Supported Media Types

| Media Type | Description |
|------------|-------------|
| application/json | Standard JSON |
| application/hal+json | HAL hypermedia |
| application/vnd.api+json | JSON:API |
| application/xml | XML format |
| application/problem+json | RFC 7807 errors |

### Versioning via Accept Header

```
Accept: application/vnd.api.v2+json
```

---

## Bulk Operations

### Batch Requests

Process multiple operations in a single request:

**Request:**
```
POST /batch HTTP/1.1
Content-Type: application/json

{
  "requests": [
    {
      "id": "req1",
      "method": "POST",
      "path": "/orders",
      "body": {"item": "Product A"}
    },
    {
      "id": "req2",
      "method": "GET",
      "path": "/orders/123"
    },
    {
      "id": "req3",
      "method": "DELETE",
      "path": "/orders/456"
    }
  ]
}
```

**Response:**
```json
{
  "responses": [
    {
      "id": "req1",
      "status": 201,
      "body": {"id": "ord_789", "item": "Product A"}
    },
    {
      "id": "req2",
      "status": 200,
      "body": {"id": "123", "status": "pending"}
    },
    {
      "id": "req3",
      "status": 204,
      "body": null
    }
  ]
}
```

### Bulk Create

```
POST /orders/bulk HTTP/1.1
Content-Type: application/json

{
  "items": [
    {"item": "Product A", "quantity": 1},
    {"item": "Product B", "quantity": 2},
    {"item": "Product C", "quantity": 1}
  ]
}
```

### Bulk Update

```
PATCH /orders/bulk HTTP/1.1
Content-Type: application/json

{
  "updates": [
    {"id": "ord_123", "status": "shipped"},
    {"id": "ord_456", "status": "shipped"},
    {"id": "ord_789", "status": "shipped"}
  ]
}
```

### Bulk Delete

```
DELETE /orders/bulk HTTP/1.1
Content-Type: application/json

{
  "ids": ["ord_123", "ord_456", "ord_789"]
}
```

---

## Long-Running Operations

### Async Processing Pattern

For operations that take too long for synchronous response:

**Initial Request:**
```
POST /reports/generate HTTP/1.1
Content-Type: application/json

{
  "type": "sales",
  "date_range": "2026-01"
}
```

**Response (202 Accepted):**
```
HTTP/1.1 202 Accepted
Location: /operations/op_abc123
Retry-After: 30

{
  "operation_id": "op_abc123",
  "status": "processing",
  "status_url": "/operations/op_abc123",
  "estimated_completion": "2026-01-23T10:35:00Z"
}
```

**Polling for Status:**
```
GET /operations/op_abc123 HTTP/1.1
```

**In Progress Response:**
```json
{
  "operation_id": "op_abc123",
  "status": "processing",
  "progress": 45,
  "estimated_completion": "2026-01-23T10:35:00Z"
}
```

**Completed Response:**
```json
{
  "operation_id": "op_abc123",
  "status": "completed",
  "result_url": "/reports/rpt_xyz789",
  "completed_at": "2026-01-23T10:34:30Z"
}
```

### Operation States

| State | Description |
|-------|-------------|
| pending | Queued, not started |
| processing | In progress |
| completed | Successfully finished |
| failed | Failed with error |
| cancelled | Cancelled by user |

---

## Idempotency

### Idempotency Keys

For non-idempotent operations (POST), use idempotency keys:

**Request:**
```
POST /payments HTTP/1.1
Idempotency-Key: pay_unique_key_123
Content-Type: application/json

{
  "amount": 99.99,
  "currency": "USD"
}
```

### Server Behavior

| Scenario | Response |
|----------|----------|
| First request | Process and store result with key |
| Duplicate (same key) | Return stored result |
| Different body (same key) | 409 Conflict or 422 Unprocessable |

### Key Requirements

| Property | Requirement |
|----------|-------------|
| Uniqueness | Unique per client/operation |
| Format | UUID recommended |
| Lifetime | Store for 24-72 hours |
| Scope | Per API key/user |

---

## Related Documentation

- [Caching Strategies Reference](caching-strategies.md) - Detailed caching patterns
- [Security Headers Reference](security-headers.md) - Security considerations
- [OAuth2 Flows Reference](oauth2-flows.md) - Authentication for rate limiting
