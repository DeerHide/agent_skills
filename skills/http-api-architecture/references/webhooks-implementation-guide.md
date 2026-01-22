# Webhook Implementation Guide

This guide provides detailed documentation for implementing webhook systems in RESTful APIs.

## Overview

Webhooks are HTTP callbacks that notify external systems when events occur. Instead of clients polling for changes, the server pushes data to registered endpoints when relevant events happen.

### Benefits of Webhooks

| Benefit | Description |
|---------|-------------|
| Real-time | Immediate notification when events occur |
| Efficiency | No wasted requests checking for changes |
| Decoupling | Event producers and consumers are loosely coupled |
| Scalability | Reduces server load from polling |

---

## Webhook Registration API

### Subscription Resource

Design webhook subscriptions as a REST resource.

**Resource Structure:**

```json
{
  "id": "whk_abc123def456",
  "url": "https://client.example.com/webhooks/receive",
  "events": ["order.created", "order.updated", "payment.completed"],
  "secret": "whsec_xxxxxxxxxxxxxxxxxxxxxxxx",
  "active": true,
  "created_at": "2026-01-23T10:00:00Z",
  "updated_at": "2026-01-23T10:00:00Z",
  "metadata": {
    "description": "Production order notifications"
  }
}
```

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /v1/webhooks | Create subscription |
| GET | /v1/webhooks | List subscriptions |
| GET | /v1/webhooks/{id} | Get subscription |
| PATCH | /v1/webhooks/{id} | Update subscription |
| DELETE | /v1/webhooks/{id} | Delete subscription |

### Create Subscription

**Request:**
```
POST /v1/webhooks HTTP/1.1
Host: api.example.com
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "url": "https://client.example.com/webhooks/receive",
  "events": ["order.created", "order.updated"],
  "metadata": {
    "description": "Order notifications"
  }
}
```

**Response:**
```json
{
  "id": "whk_abc123def456",
  "url": "https://client.example.com/webhooks/receive",
  "events": ["order.created", "order.updated"],
  "secret": "whsec_xxxxxxxxxxxxxxxxxxxxxxxx",
  "active": true,
  "created_at": "2026-01-23T10:00:00Z"
}
```

**Important**: The `secret` is only returned once during creation. Clients must store it securely for signature verification.

### URL Validation

Before accepting a webhook URL, validate it:

1. **HTTPS Required**: Only accept HTTPS URLs in production
2. **Reachability Check**: Optionally send a validation request
3. **Challenge-Response**: Send a challenge and verify the endpoint responds correctly

**Challenge-Response Pattern:**

```
POST {webhook_url} HTTP/1.1
Content-Type: application/json

{
  "type": "webhook.validation",
  "challenge": "abc123xyz789"
}
```

Expected response:
```json
{
  "challenge": "abc123xyz789"
}
```

---

## Event Types

### Naming Convention

Use the pattern: `resource.action`

**Standard Actions:**

| Action | Description |
|--------|-------------|
| created | Resource was created |
| updated | Resource was modified |
| deleted | Resource was removed |
| completed | Process finished successfully |
| failed | Process failed |

**Examples:**

| Event Type | Description |
|------------|-------------|
| order.created | New order placed |
| order.updated | Order modified |
| order.cancelled | Order cancelled |
| payment.completed | Payment successful |
| payment.failed | Payment failed |
| payment.refunded | Payment refunded |
| subscription.renewed | Subscription renewed |
| subscription.cancelled | Subscription cancelled |
| user.registered | New user signed up |
| user.updated | User profile updated |

### Event Hierarchy

Support wildcard subscriptions for flexibility:

| Pattern | Matches |
|---------|---------|
| `order.created` | Only order.created |
| `order.*` | All order events |
| `*` | All events |

---

## Webhook Delivery

### Request Format

**HTTP Request:**

```
POST {webhook_url} HTTP/1.1
Host: client.example.com
Content-Type: application/json
User-Agent: YourAPI-Webhook/1.0
X-Webhook-ID: whk_abc123def456
X-Webhook-Event: order.created
X-Webhook-Signature: sha256=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
X-Webhook-Timestamp: 1706090400
X-Request-ID: req_xyz789

{
  "event_id": "evt_1a2b3c4d5e6f",
  "event_type": "order.created",
  "api_version": "v1",
  "created_at": "2026-01-23T10:30:00Z",
  "data": {
    // Event-specific data
  }
}
```

### Required Headers

| Header | Description |
|--------|-------------|
| Content-Type | Always `application/json` |
| User-Agent | Identify your service |
| X-Webhook-ID | Subscription identifier |
| X-Webhook-Event | Event type |
| X-Webhook-Signature | HMAC signature for verification |
| X-Webhook-Timestamp | Unix timestamp of request |
| X-Request-ID | Unique request identifier |

### Payload Structure (Envelope Pattern)

```json
{
  "event_id": "evt_1a2b3c4d5e6f7g8h9i0j",
  "event_type": "order.created",
  "api_version": "v1",
  "created_at": "2026-01-23T10:30:00Z",
  "webhook_id": "whk_abc123def456",
  "attempt": 1,
  "data": {
    // Full resource or relevant subset
  },
  "metadata": {
    "correlation_id": "req_xyz789",
    "source": "api"
  }
}
```

**Envelope Fields:**

| Field | Description |
|-------|-------------|
| event_id | Unique identifier for idempotency |
| event_type | Type of event (resource.action) |
| api_version | API version for payload structure |
| created_at | When the event occurred |
| webhook_id | Subscription that triggered this delivery |
| attempt | Delivery attempt number (1, 2, 3...) |
| data | Event-specific payload |
| metadata | Additional context |

### Response Handling

**Success Responses (2xx):**

| Status | Meaning |
|--------|---------|
| 200 OK | Delivery successful |
| 201 Created | Delivery successful (resource created) |
| 202 Accepted | Accepted for async processing |
| 204 No Content | Delivery successful (no body) |

**Failure Responses (to retry):**

| Status | Meaning | Action |
|--------|---------|--------|
| 408 Request Timeout | Client timeout | Retry |
| 429 Too Many Requests | Rate limited | Retry with backoff |
| 500 Internal Server Error | Server error | Retry |
| 502 Bad Gateway | Gateway error | Retry |
| 503 Service Unavailable | Temporarily down | Retry |
| 504 Gateway Timeout | Gateway timeout | Retry |

**Permanent Failures (do not retry):**

| Status | Meaning | Action |
|--------|---------|--------|
| 400 Bad Request | Invalid request | Log error, don't retry |
| 401 Unauthorized | Auth required | Notify subscription owner |
| 403 Forbidden | Access denied | Notify subscription owner |
| 404 Not Found | Endpoint not found | Disable subscription |
| 410 Gone | Endpoint removed | Disable subscription |

---

## Retry Logic

### Exponential Backoff

Implement exponential backoff with jitter for retries.

**Retry Schedule:**

| Attempt | Delay | Cumulative |
|---------|-------|------------|
| 1 | Immediate | 0 |
| 2 | 1 minute | 1 min |
| 3 | 5 minutes | 6 min |
| 4 | 15 minutes | 21 min |
| 5 | 1 hour | 1h 21min |
| 6 | 6 hours | 7h 21min |
| 7 | 24 hours | 31h 21min |

**Backoff Formula:**

```
delay = min(base_delay * (2 ^ attempt) + random_jitter, max_delay)
```

**Configuration Parameters:**

| Parameter | Recommended Value |
|-----------|-------------------|
| Initial delay | 60 seconds |
| Maximum delay | 24 hours |
| Maximum attempts | 7 |
| Jitter range | 0-30 seconds |

### Retry Conditions

**Retry When:**
- Connection timeout
- Read timeout
- HTTP 5xx responses
- HTTP 429 (Too Many Requests)
- Network errors

**Do Not Retry When:**
- HTTP 2xx (success)
- HTTP 4xx (except 429)
- Signature verification fails on client
- Maximum attempts reached

### Dead Letter Queue

After maximum retries, events should be:
1. Stored in a dead letter queue
2. Flagged for manual review
3. Made available via API for client retrieval

**Dead Letter API:**

```
GET /v1/webhooks/{id}/failed-events HTTP/1.1
Host: api.example.com
Authorization: Bearer {access_token}
```

---

## Idempotency

### Event ID

Every webhook delivery includes a unique `event_id`. Consumers must use this for idempotency.

**Consumer Responsibilities:**

1. Store processed event IDs
2. Check if event was already processed before handling
3. Return success if already processed (don't reprocess)

**Idempotency Window:**

Store event IDs for a reasonable period (7-30 days) to handle delayed retries.

### Idempotent Processing

Consumers should design event handlers to be idempotent:

| Event Type | Idempotent Handling |
|------------|---------------------|
| order.created | Check if order exists before creating |
| order.updated | Use timestamp/version to prevent stale updates |
| payment.completed | Check payment status before processing |

---

## Delivery Monitoring

### Webhook Logs

Provide clients access to delivery logs:

```
GET /v1/webhooks/{id}/deliveries HTTP/1.1
Host: api.example.com
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "data": [
    {
      "id": "dlv_abc123",
      "event_id": "evt_1a2b3c4d5e6f",
      "event_type": "order.created",
      "status": "delivered",
      "response_code": 200,
      "response_time_ms": 245,
      "attempts": 1,
      "delivered_at": "2026-01-23T10:30:01Z"
    },
    {
      "id": "dlv_def456",
      "event_id": "evt_7g8h9i0j1k2l",
      "event_type": "order.updated",
      "status": "failed",
      "response_code": 503,
      "attempts": 3,
      "next_attempt_at": "2026-01-23T11:30:00Z",
      "last_error": "Service Unavailable"
    }
  ],
  "pagination": {
    "total": 150,
    "limit": 20,
    "offset": 0
  }
}
```

### Delivery Status

| Status | Description |
|--------|-------------|
| pending | Awaiting delivery |
| delivered | Successfully delivered |
| retrying | Failed, will retry |
| failed | All retries exhausted |

### Metrics to Track

| Metric | Description |
|--------|-------------|
| delivery_success_rate | Percentage of successful deliveries |
| average_response_time | Mean response time in ms |
| retry_rate | Percentage of deliveries requiring retry |
| failure_rate | Percentage of permanent failures |
| average_attempts | Mean attempts per delivery |

---

## Testing

### Test Endpoints

Provide endpoints for testing webhook integrations:

**Send Test Event:**
```
POST /v1/webhooks/{id}/test HTTP/1.1
Host: api.example.com
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "event_type": "order.created"
}
```

**Replay Event:**
```
POST /v1/webhooks/{id}/replay HTTP/1.1
Host: api.example.com
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "event_id": "evt_1a2b3c4d5e6f"
}
```

### Testing Checklist

- [ ] Endpoint responds with 2xx for valid webhooks
- [ ] Signature verification works correctly
- [ ] Idempotency handling prevents duplicate processing
- [ ] Timeout handling is appropriate
- [ ] Error responses are handled gracefully

---

## Versioning

### API Version in Payload

Include API version in webhook payloads to handle schema changes:

```json
{
  "event_id": "evt_123",
  "event_type": "order.created",
  "api_version": "v1",
  "data": { ... }
}
```

### Version Negotiation

Allow subscribers to specify preferred API version:

```json
{
  "url": "https://client.example.com/webhooks",
  "events": ["order.created"],
  "api_version": "v2"
}
```

### Deprecation Strategy

1. Announce new version availability
2. Continue supporting old version for transition period
3. Send deprecation warnings in webhook headers
4. Disable old version after transition period

---

## Related Documentation

- [Webhook Security Reference](webhook-security.md) - Signature verification and security
- [OAuth2 Flows Reference](oauth2-flows.md) - Authentication for webhook API
- [Advanced REST Patterns](advanced-rest-patterns.md) - API design patterns
