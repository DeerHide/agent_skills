---
name: http-api-architecture
description: Guide for designing RESTful HTTP APIs including resource modeling, HTTP methods, status codes, webhooks, OAuth2 authentication, OpenID Connect, CORS, security headers, caching, rate limiting, and distributed tracing
metadata:
  author: Deerhide
  version: 1.0.0
---

# HTTP API Architecture (REST)

## When to use this skill?

- Use this skill when designing RESTful API endpoints and resource structures
- Use this skill when choosing appropriate HTTP methods for API operations
- Use this skill when determining HTTP status codes for API responses
- Use this skill when implementing webhook systems for event-driven communication
- Use this skill when selecting OAuth2 flows for API authentication
- Use this skill when configuring CORS policies for cross-origin requests
- Use this skill when implementing security headers for API protection
- Use this skill when designing caching strategies for API performance
- Use this skill when implementing rate limiting for API protection
- Use this skill when designing error response formats
- Use this skill when implementing distributed tracing with OpenTelemetry or B3

## REST Fundamentals

### What is REST?

REST (Representational State Transfer) is an architectural style for designing networked applications. RESTful APIs use HTTP requests to perform CRUD (Create, Read, Update, Delete) operations on resources.

**Core REST Principles:**

1. **Client-Server Separation**: Client and server evolve independently
2. **Statelessness**: Each request contains all information needed to process it
3. **Cacheability**: Responses must define themselves as cacheable or non-cacheable
4. **Uniform Interface**: Consistent way to interact with resources
5. **Layered System**: Client cannot tell if connected directly to server or intermediary
6. **Code on Demand (Optional)**: Server can extend client functionality

### Resource-Oriented Design

Resources are the fundamental concept in REST. Design your API around resources (nouns), not actions (verbs).

**Good Resource Design:**

| Pattern | Example | Description |
|---------|---------|-------------|
| Collection | `/orders` | List of resources |
| Singular | `/orders/{id}` | Single resource |
| Filtered | `/orders?user_id={id}` | Related resources via query filter |
| Sub-resource | `/orders/{id}/items` | Tightly coupled child resources |

**URI Naming Conventions:**

| Good | Bad | Reason |
|------|-----|--------|
| `/orders` | `/getOrders` | Use nouns, not verbs |
| `/orders/{id}` | `/order?id=123` | Use path parameters for identity |
| `/orders?user_id=123` | `/users/123/orders` | Use query filters for cross-service relationships |
| `/order-items` | `/orderItems` | Use kebab-case for multi-word |
| `/orders` | `/Orders` | Use lowercase |

### Microservices Resource Design

In microservices architectures, prefer query filters over nested paths for cross-service relationships:

**Query Filters (Recommended for Microservices):**

| Pattern | Example | Use Case |
|---------|---------|----------|
| Filter by parent | `/orders?user_id=123` | Orders belonging to a user |
| Filter by relation | `/invoices?order_id=456` | Invoices for an order |
| Multiple filters | `/orders?user_id=123&status=pending` | Combined filtering |

**Nested Paths (Use Sparingly):**

| Pattern | Example | Use Case |
|---------|---------|----------|
| Tightly coupled | `/orders/{id}/items` | Items exist only within order context |
| Same service | `/orders/{id}/status` | Sub-resource managed by same service |

**Why Query Filters for Microservices:**

| Aspect | Nested Paths | Query Filters |
|--------|--------------|---------------|
| Service coupling | Tight (implies ownership) | Loose (reference by ID) |
| API gateway routing | Complex (parse hierarchy) | Simple (route by resource) |
| Service independence | Low (needs parent context) | High (owns its resources) |
| Scalability | Limited (hierarchical) | Better (flat structure) |
| Cross-service queries | Difficult | Natural |

## HTTP Methods

Use HTTP methods according to their semantics as defined in [RFC 7231](https://datatracker.ietf.org/doc/html/rfc7231).

| Method | Purpose | Idempotent | Safe | Request Body | Response Body |
|--------|---------|------------|------|--------------|---------------|
| GET | Retrieve resource(s) | Yes | Yes | No | Yes |
| POST | Create resource | No | No | Yes | Yes |
| PUT | Replace resource entirely | Yes | No | Yes | Optional |
| PATCH | Partial update | No | No | Yes | Yes |
| DELETE | Remove resource | Yes | No | Optional | Optional |
| HEAD | Get headers only | Yes | Yes | No | No |
| OPTIONS | Get allowed methods | Yes | Yes | No | Yes |

### Method Usage Examples

**GET** - Retrieve resources:
- `GET /orders` - List all orders
- `GET /orders/123` - Get specific order
- `GET /orders?status=pending` - Filter orders

**POST** - Create new resource:
- `POST /orders` - Create new order
- Returns `201 Created` with `Location` header

**PUT** - Full replacement:
- `PUT /orders/123` - Replace entire order
- Client must send complete resource

**PATCH** - Partial update:
- `PATCH /orders/123` - Update specific fields
- Use JSON Patch ([RFC 6902](https://datatracker.ietf.org/doc/html/rfc6902)) or JSON Merge Patch ([RFC 7396](https://datatracker.ietf.org/doc/html/rfc7396))

**DELETE** - Remove resource:
- `DELETE /orders/123` - Delete order
- Returns `204 No Content` or `200 OK`

### Idempotency Keys

For non-idempotent operations (POST), use idempotency keys to prevent duplicate processing due to retries or network issues.

**Header:**
```
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
```

**How It Works:**

| Request | Server Action |
|---------|---------------|
| First request with key | Process and store result with key |
| Retry with same key | Return stored result (no reprocessing) |
| Same key, different body | Return `409 Conflict` or `422 Unprocessable Entity` |

**Implementation Requirements:**

| Aspect | Recommendation |
|--------|----------------|
| Key format | UUID v4 recommended |
| Key storage duration | 24-72 hours |
| Key scope | Per API key/client |
| Response | Include key in response for confirmation |

**Use Cases:**
- Payment processing (prevent double charges)
- Order creation (prevent duplicate orders)
- Any operation with side effects that shouldn't repeat

**Response Example:**
```json
{
  "id": "ord_123456",
  "idempotency_key": "550e8400-e29b-41d4-a716-446655440000",
  "status": "created"
}
```

For detailed patterns, see [references/advanced-rest-patterns.md](references/advanced-rest-patterns.md#idempotency).

## HTTP Status Codes

Use appropriate status codes as defined in [RFC 7231](https://datatracker.ietf.org/doc/html/rfc7231).

### Success Codes (2xx)

| Code | Name | Usage |
|------|------|-------|
| 200 | OK | Successful GET, PUT, PATCH, DELETE |
| 201 | Created | Successful POST creating resource |
| 202 | Accepted | Request accepted for async processing |
| 204 | No Content | Successful request with no response body |

### Redirection Codes (3xx)

| Code | Name | Usage |
|------|------|-------|
| 301 | Moved Permanently | Resource permanently moved |
| 302 | Found | Temporary redirect |
| 304 | Not Modified | Cached response still valid |

### Client Error Codes (4xx)

| Code | Name | Usage |
|------|------|-------|
| 400 | Bad Request | Malformed request syntax |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Authenticated but not authorized |
| 404 | Not Found | Resource does not exist |
| 405 | Method Not Allowed | HTTP method not supported |
| 409 | Conflict | Request conflicts with current state |
| 410 | Gone | Resource permanently removed |
| 415 | Unsupported Media Type | Content-Type not supported |
| 422 | Unprocessable Entity | Validation errors |
| 429 | Too Many Requests | Rate limit exceeded |

### Server Error Codes (5xx)

| Code | Name | Usage |
|------|------|-------|
| 500 | Internal Server Error | Unexpected server error |
| 501 | Not Implemented | Feature not implemented |
| 502 | Bad Gateway | Invalid upstream response |
| 503 | Service Unavailable | Server temporarily unavailable |
| 504 | Gateway Timeout | Upstream timeout |

## Error Response Format

Use a consistent error response format. We recommend [RFC 7807 Problem Details](https://datatracker.ietf.org/doc/html/rfc7807) for standardized error responses.

See [assets/error-response-example.json](assets/error-response-example.json) for a complete example.

**Standard Error Structure:**

```json
{
  "type": "https://api.example.com/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "The request body contains invalid fields",
  "instance": "/orders/123",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ]
}
```

**Error Response Fields:**

| Field | Required | Description |
|-------|----------|-------------|
| type | Yes | URI identifying error type |
| title | Yes | Human-readable error title |
| status | Yes | HTTP status code |
| detail | No | Human-readable explanation |
| instance | No | URI of specific occurrence |
| errors | No | Array of field-level errors |

## API Versioning

Choose a versioning strategy and apply it consistently.

| Strategy | Example | Pros | Cons |
|----------|---------|------|------|
| URI Path | `/v1/orders` | Clear, easy to route | URL changes |
| Query Parameter | `/orders?version=1` | Non-breaking URLs | Easy to miss |
| Header | `Accept: application/vnd.api+json;version=1` | Clean URLs | Hidden from view |
| Content Negotiation | `Accept: application/vnd.api.v1+json` | RESTful approach | Complex |

**Recommended**: URI Path versioning for public APIs due to clarity and discoverability.

### Versioning Best Practices

1. **Version from the start**: Always include version in initial release
2. **Maintain backwards compatibility**: Avoid breaking changes within a version
3. **Deprecation policy**: Announce deprecation well in advance (6-12 months)
4. **Support multiple versions**: Run at least N-1 versions concurrently
5. **Document changes**: Maintain changelog per version

## Request/Response Patterns

### Pagination

For collections that can return many items, implement pagination.

**Offset-Based Pagination:**
```
GET /orders?offset=20&limit=10
```

**Cursor-Based Pagination (Recommended):**
```
GET /orders?cursor=eyJpZCI6MTIzfQ&limit=10
```

**Pagination Response:**
```json
{
  "data": [...],
  "pagination": {
    "total": 100,
    "limit": 10,
    "offset": 20,
    "next": "/orders?offset=30&limit=10",
    "previous": "/orders?offset=10&limit=10"
  }
}
```

### Filtering

Support filtering via query parameters:
```
GET /orders?status=pending&created_after=2026-01-01
```

### Sorting

Support sorting via query parameters:
```
GET /orders?sort=created_at&order=desc
GET /orders?sort=-created_at,+status
```

### Field Selection

Allow clients to request specific fields:
```
GET /orders?fields=id,status,total
```

## Webhooks

Webhooks enable event-driven communication by pushing data to registered endpoints when events occur. This is the reverse of traditional polling where clients repeatedly request data.

### Webhooks vs Polling

| Aspect | Webhooks | Polling |
|--------|----------|---------|
| Latency | Real-time | Dependent on interval |
| Efficiency | Push on change only | Constant requests |
| Complexity | Higher (need endpoint) | Lower |
| Reliability | Requires retry logic | Built-in with retries |
| Use Case | Real-time notifications | Simple integrations |

### Webhook Event Types

Use a consistent naming convention for events: `resource.action`

| Event Type | Description |
|------------|-------------|
| `order.created` | New order created |
| `order.updated` | Order modified |
| `order.deleted` | Order removed |
| `payment.completed` | Payment successful |
| `payment.failed` | Payment failed |

### Webhook Payload Structure

Use an envelope pattern for consistent webhook payloads. See [assets/webhook-payload-example.json](assets/webhook-payload-example.json) for a complete example.

```json
{
  "event_id": "evt_1a2b3c4d5e6f",
  "event_type": "order.created",
  "api_version": "v1",
  "created_at": "2026-01-23T10:30:00Z",
  "data": {
    "id": "ord_123456",
    "status": "pending",
    "total": 99.99
  }
}
```

### Webhook Implementation Topics

For detailed implementation guidance, see:
- [references/webhooks-implementation-guide.md](references/webhooks-implementation-guide.md) - Registration, delivery, retry logic
- [references/webhook-security.md](references/webhook-security.md) - Signature verification, security best practices

**Key Implementation Considerations:**

1. **Registration API**: Allow clients to subscribe to specific events
2. **Retry Strategy**: Implement exponential backoff (1m, 5m, 15m, 1h, 6h, 24h)
3. **Idempotency**: Include unique event IDs for deduplication
4. **Timeouts**: Set reasonable connection timeouts (5-10 seconds)
5. **Security**: Sign payloads with HMAC-SHA256

## Authentication & Authorization

### OAuth2 Overview

OAuth2 ([RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)) is the industry standard for authorization. It enables secure delegated access without sharing credentials.

### Choosing the Right OAuth2 Flow

| Flow | Use Case | User Interaction | Tokens |
|------|----------|------------------|--------|
| Client Credentials | Server-to-server, M2M | None | Access only |
| Authorization Code + PKCE | Web apps, mobile apps | Yes | Access + Refresh |
| Device Flow | Smart TVs, CLI tools, IoT | Yes (separate device) | Access + Refresh |

**Decision Matrix:**

```
Is there a user context?
├─ No → Client Credentials Flow
└─ Yes → Does the client have a browser?
         ├─ Yes → Authorization Code Flow with PKCE
         └─ No → Device Flow
```

For detailed flow descriptions, see [references/oauth2-flows.md](references/oauth2-flows.md).

### OpenID Connect

OpenID Connect (OIDC) is an identity layer built on top of OAuth2. While OAuth2 handles authorization (what you can access), OIDC handles authentication (who you are).

**Key Differences:**

| Aspect | OAuth2 | OpenID Connect |
|--------|--------|----------------|
| Purpose | Authorization | Authentication + Authorization |
| Token | Access Token | Access Token + ID Token |
| User Info | Not standardized | Standardized claims |
| Discovery | Not defined | `.well-known/openid-configuration` |

**Provider Variance Note**: While OIDC is a standard, specific providers (Google, Microsoft, Auth0, Okta) may have variations in:
- Supported claims
- Token lifetimes
- Discovery endpoint structure
- Additional proprietary features

Always consult provider-specific documentation alongside the standard.

For detailed OIDC guidance, see [references/openid-connect.md](references/openid-connect.md).

## Security

### CORS (Cross-Origin Resource Sharing)

CORS ([RFC 6454](https://datatracker.ietf.org/doc/html/rfc6454)) controls which origins can access your API from browsers.

**Key CORS Headers:**

| Header | Purpose | Example |
|--------|---------|---------|
| `Access-Control-Allow-Origin` | Allowed origins | `https://example.com` |
| `Access-Control-Allow-Methods` | Allowed HTTP methods | `GET, POST, PUT, DELETE` |
| `Access-Control-Allow-Headers` | Allowed request headers | `Authorization, Content-Type` |
| `Access-Control-Allow-Credentials` | Allow cookies/auth | `true` |
| `Access-Control-Max-Age` | Preflight cache duration | `86400` |

**CORS Best Practices:**

1. **Never use `*` with credentials**: Browsers block this combination
2. **Whitelist specific origins**: Avoid wildcards in production
3. **Limit exposed headers**: Only expose necessary headers
4. **Set appropriate max-age**: Cache preflight requests

### Security Headers

Implement security headers to protect against common attacks.

| Header | Purpose | Recommended Value |
|--------|---------|-------------------|
| `Strict-Transport-Security` | Force HTTPS | `max-age=31536000; includeSubDomains` |
| `X-Content-Type-Options` | Prevent MIME sniffing | `nosniff` |
| `X-Frame-Options` | Prevent clickjacking | `DENY` or `SAMEORIGIN` |
| `Content-Security-Policy` | Control resource loading | App-specific |
| `X-XSS-Protection` | XSS filter (legacy) | `1; mode=block` |

For detailed security header guidance, see [references/security-headers.md](references/security-headers.md).

### Rate Limiting

Protect your API from abuse with rate limiting.

**Rate Limit Headers:**

| Header | Purpose | Example |
|--------|---------|---------|
| `X-RateLimit-Limit` | Max requests per window | `1000` |
| `X-RateLimit-Remaining` | Requests remaining | `999` |
| `X-RateLimit-Reset` | Window reset time (Unix) | `1706054400` |
| `Retry-After` | Seconds until retry (on 429) | `60` |

**Rate Limiting Strategies:**

| Strategy | Description | Use Case |
|----------|-------------|----------|
| Fixed Window | Reset at fixed intervals | Simple implementation |
| Sliding Window | Rolling time window | Smoother limiting |
| Token Bucket | Tokens replenish over time | Burst handling |
| Leaky Bucket | Constant output rate | Traffic shaping |

## Performance

### Caching Strategies

Implement caching to improve API performance. See [references/caching-strategies.md](references/caching-strategies.md) for detailed guidance.

**Cache-Control Header ([RFC 7234](https://datatracker.ietf.org/doc/html/rfc7234)):**

| Directive | Purpose |
|-----------|---------|
| `public` | Cacheable by any cache |
| `private` | Only browser cache |
| `no-cache` | Validate before use |
| `no-store` | Never cache |
| `max-age=N` | Cache for N seconds |
| `s-maxage=N` | Shared cache max age |

**ETags for Conditional Requests:**

```
GET /orders/123
Response: ETag: "abc123"

GET /orders/123
If-None-Match: "abc123"
Response: 304 Not Modified
```

### Advanced REST Patterns

For advanced patterns including HATEOAS and conditional requests, see [references/advanced-rest-patterns.md](references/advanced-rest-patterns.md).

## Distributed Tracing

Distributed tracing enables tracking requests across multiple services. Implement trace context propagation using standardized headers.

### Trace Context Standards

| Standard | Headers | Use Case |
|----------|---------|----------|
| W3C Trace Context (OpenTelemetry) | `traceparent`, `tracestate` | Modern standard, recommended |
| B3 Multi-Header | `X-B3-TraceId`, `X-B3-SpanId`, etc. | Zipkin compatibility |
| B3 Single | `b3` | Compact alternative |

### W3C Trace Context (Recommended)

**traceparent Header:**
```
traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
```

Format: `{version}-{trace-id}-{parent-id}-{trace-flags}`

**tracestate Header:**
```
tracestate: vendor1=value1,vendor2=value2
```

### B3 Multi-Header Format

| Header | Description | Example |
|--------|-------------|---------|
| `X-B3-TraceId` | 128-bit trace ID | `463ac35c9f6413ad48485a3953bb6124` |
| `X-B3-SpanId` | 64-bit span ID | `0020000000000001` |
| `X-B3-ParentSpanId` | Parent span ID | `0000000000000000` |
| `X-B3-Sampled` | Sampling decision | `1` (sampled) or `0` |
| `X-B3-Flags` | Debug flag | `1` (debug) |

### Implementation Guidelines

1. **Propagate Headers**: Forward trace headers to downstream services
2. **Generate if Missing**: Create new trace context for incoming requests without headers
3. **Include in Responses**: Return trace ID in responses for debugging
4. **Log Correlation**: Include trace ID in all log entries

**Response Header:**
```
X-Request-ID: req_abc123xyz789
X-Trace-ID: 463ac35c9f6413ad48485a3953bb6124
```

For detailed implementation guidance, see [references/distributed-tracing.md](references/distributed-tracing.md).

## Pre-Deployment Checklist

Legend: **[MANDATORY]** | **[RECOMMENDED]** | **[OPTIONAL]**

### Design Completeness

- [ ] **[MANDATORY]** Resources follow noun-based naming conventions
- [ ] **[MANDATORY]** HTTP methods used according to semantics
- [ ] **[MANDATORY]** Status codes match operation outcomes
- [ ] **[RECOMMENDED]** Error responses follow RFC 7807 format
- [ ] **[RECOMMENDED]** API versioning strategy implemented
- [ ] **[MANDATORY]** Pagination implemented for collections
- [ ] **[RECOMMENDED]** Filtering and sorting supported where needed

### Security Implementation

- [ ] **[MANDATORY]** Authentication mechanism implemented (OAuth2/API Keys)
- [ ] **[MANDATORY]** Authorization checks on all endpoints
- [ ] **[RECOMMENDED]** CORS configured for allowed origins (required for browser clients)
- [ ] **[RECOMMENDED]** Security headers configured
- [ ] **[RECOMMENDED]** Rate limiting implemented
- [ ] **[MANDATORY]** Input validation on all endpoints
- [ ] **[MANDATORY]** HTTPS enforced

### Webhook Implementation (if applicable)

- [ ] **[MANDATORY]** Webhook registration API available
- [ ] **[MANDATORY]** Event types documented
- [ ] **[MANDATORY]** Retry logic with exponential backoff
- [ ] **[MANDATORY]** Signature verification documented
- [ ] **[RECOMMENDED]** Idempotency keys included in payloads

### Performance

- [ ] **[OPTIONAL]** Caching headers configured
- [ ] **[OPTIONAL]** Response compression enabled
- [ ] **[RECOMMENDED]** Database queries optimized
- [ ] **[OPTIONAL]** Connection pooling configured

### Monitoring (Basic)

- [ ] **[MANDATORY]** Health check endpoint available (`/health`)
- [ ] **[RECOMMENDED]** Error rates tracked
- [ ] **[RECOMMENDED]** Response time metrics collected
- [ ] **[OPTIONAL]** Rate limit violations logged
- [ ] **[OPTIONAL]** Distributed tracing implemented (W3C Trace Context or B3)
- [ ] **[RECOMMENDED]** Trace IDs included in logs and responses

## Design-First Approach

Always design your API specification before implementation. This ensures consistency, enables parallel development, and improves API quality.

**Recommended Workflow:**

1. **Design** - Write OpenAPI specification first
2. **Review** - Validate design with stakeholders and consumers
3. **Mock** - Generate mock server for early integration testing
4. **Implement** - Build API matching the specification
5. **Validate** - Test implementation against specification

**Benefits:**

| Benefit | Description |
|---------|-------------|
| Consistency | Single source of truth for API contract |
| Parallel work | Frontend/backend can develop simultaneously |
| Documentation | Auto-generated, always up-to-date docs |
| Code generation | Generate SDKs, clients, server stubs |
| Testing | Contract testing against specification |

See [openapi](../openapi/SKILL.md) for detailed OpenAPI specification standards.

## Related Skills

- [openapi](../openapi/SKILL.md) - API specification standards using OpenAPI (design-first)
- [openapi-testing](../openapi-testing/SKILL.md) - API contract testing approaches
- [fastapi-factory-utilities](../fastapi-factory-utilities/SKILL.md) - FastAPI implementation of REST APIs
- [software-architecture](../software-architecture/SKILL.md) - Foundational architectural principles
