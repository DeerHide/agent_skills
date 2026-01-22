# Distributed Tracing Reference

This guide documents distributed tracing standards for HTTP APIs, including W3C Trace Context (OpenTelemetry) and B3 propagation formats.

## Overview

Distributed tracing enables tracking requests as they flow through multiple services in a distributed system. Trace context propagation ensures that all services participating in handling a request can correlate their logs and metrics.

### Key Concepts

| Concept | Description |
|---------|-------------|
| Trace | End-to-end request journey across services |
| Span | Single operation within a trace |
| Trace ID | Unique identifier for the entire trace |
| Span ID | Unique identifier for a single span |
| Parent Span ID | ID of the parent span (caller) |
| Sampling | Decision to record/export trace data |

### Trace Hierarchy

```
Trace (trace-id: abc123)
├── Span A (span-id: 001, parent: none) - API Gateway
│   ├── Span B (span-id: 002, parent: 001) - Order Service
│   │   ├── Span C (span-id: 003, parent: 002) - Database Query
│   │   └── Span D (span-id: 004, parent: 002) - Cache Lookup
│   └── Span E (span-id: 005, parent: 001) - Payment Service
│       └── Span F (span-id: 006, parent: 005) - External Payment API
```

---

## W3C Trace Context (OpenTelemetry)

**References**: 
- [W3C Trace Context Specification](https://www.w3.org/TR/trace-context/)
- [OpenTelemetry Specification](https://opentelemetry.io/docs/specs/otel/)

W3C Trace Context is the modern standard for distributed tracing, adopted by OpenTelemetry.

### Headers

| Header | Required | Description |
|--------|----------|-------------|
| traceparent | Yes | Core trace context |
| tracestate | No | Vendor-specific trace data |

### traceparent Header

**Format:**
```
traceparent: {version}-{trace-id}-{parent-id}-{trace-flags}
```

**Example:**
```
traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
```

**Field Breakdown:**

| Field | Length | Description | Example |
|-------|--------|-------------|---------|
| version | 2 hex | Version number (always 00) | `00` |
| trace-id | 32 hex | 128-bit trace identifier | `0af7651916cd43dd8448eb211c80319c` |
| parent-id | 16 hex | 64-bit parent span identifier | `b7ad6b7169203331` |
| trace-flags | 2 hex | Trace flags (sampling) | `01` |

**Version:**
- Current version: `00`
- If version is unknown, treat entire header as invalid

**Trace ID:**
- 128-bit (32 hex characters)
- Must not be all zeros (`00000000000000000000000000000000`)
- Generate using cryptographically random source

**Parent ID (Span ID):**
- 64-bit (16 hex characters)
- Must not be all zeros (`0000000000000000`)
- Represents the calling span

**Trace Flags:**

| Bit | Flag | Description |
|-----|------|-------------|
| 0 | sampled | `01` = sampled, `00` = not sampled |
| 1-7 | reserved | Reserved for future use |

### tracestate Header

**Format:**
```
tracestate: vendor1=value1,vendor2=value2
```

**Example:**
```
tracestate: rojo=00f067aa0ba902b7,congo=t61rcWkgMzE
```

**Rules:**
- Key-value pairs separated by commas
- Maximum 32 entries
- Keys: lowercase letters, digits, `_`, `-`, `*`, `/`
- Values: printable ASCII except `,` and `=`
- Rightmost entry is oldest, leftmost is newest

**Use Cases:**
- Vendor-specific trace identifiers
- Application-specific metadata
- Multi-tenant trace correlation

### Propagation Rules

**Incoming Request (No Context):**
1. Generate new trace-id (128-bit random)
2. Generate new span-id (64-bit random)
3. Set trace-flags based on sampling decision

**Incoming Request (With Context):**
1. Parse traceparent header
2. Extract trace-id (preserve)
3. Use received parent-id as parent
4. Generate new span-id for current span
5. Preserve trace-flags (or modify based on policy)
6. Preserve tracestate entries

**Outgoing Request:**
1. Create traceparent with:
   - Same trace-id
   - Current span-id as parent-id
   - Current trace-flags
2. Forward tracestate (add/update vendor entry if needed)

---

## B3 Propagation

**Reference**: [OpenZipkin B3 Propagation](https://github.com/openzipkin/b3-propagation)

B3 is a trace context propagation format originated from Zipkin. It has two variants: multi-header and single-header.

### B3 Multi-Header Format

**Headers:**

| Header | Required | Description |
|--------|----------|-------------|
| X-B3-TraceId | Yes | Trace identifier |
| X-B3-SpanId | Yes | Current span identifier |
| X-B3-ParentSpanId | No | Parent span identifier |
| X-B3-Sampled | No | Sampling decision |
| X-B3-Flags | No | Debug flag |

**Example:**
```
X-B3-TraceId: 463ac35c9f6413ad48485a3953bb6124
X-B3-SpanId: 0020000000000001
X-B3-ParentSpanId: 0000000000000000
X-B3-Sampled: 1
```

### Header Details

**X-B3-TraceId:**
- 128-bit (32 hex) or 64-bit (16 hex) identifier
- 128-bit recommended for modern systems
- Must be propagated unchanged

```
# 128-bit (recommended)
X-B3-TraceId: 463ac35c9f6413ad48485a3953bb6124

# 64-bit (legacy)
X-B3-TraceId: 0020000000000001
```

**X-B3-SpanId:**
- 64-bit (16 hex characters)
- Unique within the trace
- Generated for each new span

```
X-B3-SpanId: 0020000000000001
```

**X-B3-ParentSpanId:**
- 64-bit (16 hex characters)
- ID of the parent span
- Absent for root spans

```
X-B3-ParentSpanId: b7ad6b7169203331
```

**X-B3-Sampled:**
- Sampling decision
- Values: `0` (not sampled), `1` (sampled)
- Absent means defer decision to receiver

```
# Sampled - record this trace
X-B3-Sampled: 1

# Not sampled - do not record
X-B3-Sampled: 0

# Absent - receiver decides
(no header)
```

**X-B3-Flags:**
- Debug flag
- Value: `1` (debug mode)
- When set, implies sampled

```
# Debug mode - always sample, add debug info
X-B3-Flags: 1
```

### B3 Single-Header Format

**Format:**
```
b3: {TraceId}-{SpanId}-{SamplingState}-{ParentSpanId}
```

**Examples:**
```
# Full format
b3: 80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-1-05e3ac9a4f6e3b90

# Without parent span
b3: 80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-1

# Sampling only (deny)
b3: 0

# Debug
b3: 80f198ee56343ba864fe8b2a57d3eff7-e457b5a2e4d86bd1-d
```

**Sampling State Values:**

| Value | Meaning |
|-------|---------|
| `0` | Not sampled (deny) |
| `1` | Sampled (accept) |
| `d` | Debug |
| (absent) | Defer |

### B3 Propagation Rules

**Root Span (No Incoming Context):**
1. Generate new TraceId (128-bit recommended)
2. Generate new SpanId
3. No ParentSpanId
4. Make sampling decision

**Child Span (With Context):**
1. Preserve TraceId
2. Generate new SpanId
3. Set ParentSpanId to received SpanId
4. Preserve sampling decision

---

## Format Comparison

### Header Comparison

| Aspect | W3C Trace Context | B3 Multi | B3 Single |
|--------|-------------------|----------|-----------|
| Headers | 2 (traceparent + tracestate) | 4-5 | 1 |
| Trace ID | 128-bit only | 64 or 128-bit | 64 or 128-bit |
| Span ID | 64-bit | 64-bit | 64-bit |
| Vendor Data | tracestate | Custom headers | No |
| Standard | W3C Recommendation | De facto (Zipkin) | De facto (Zipkin) |

### Feature Comparison

| Feature | W3C Trace Context | B3 |
|---------|-------------------|-----|
| Standardization | W3C Standard | Community standard |
| Versioning | Built-in (version field) | No |
| Vendor State | Native (tracestate) | Requires custom headers |
| Adoption | OpenTelemetry, modern systems | Zipkin, legacy systems |
| Interoperability | High (standard) | Medium (de facto) |

### When to Use

| Scenario | Recommended Format |
|----------|-------------------|
| New systems | W3C Trace Context |
| OpenTelemetry integration | W3C Trace Context |
| Zipkin ecosystem | B3 |
| Legacy system integration | B3 (check existing format) |
| Multi-vendor environment | W3C Trace Context |
| Maximum compatibility | Support both |

---

## Implementation Guidelines

### HTTP Request Handling

**Incoming Request Processing:**

1. Check for trace context headers (W3C first, then B3)
2. Parse and validate header format
3. Extract trace ID, span ID, sampling decision
4. Create new span with received context as parent
5. Store context for propagation to downstream calls

**Outgoing Request Processing:**

1. Retrieve current trace context
2. Generate new span ID for the call
3. Format headers (match incoming format or use preferred)
4. Add headers to outgoing request
5. Record span timing and metadata

### Sampling Decisions

**Sampling Strategies:**

| Strategy | Description | Use Case |
|----------|-------------|----------|
| Always | Sample all traces | Development, debugging |
| Never | Sample no traces | High-volume, cost-sensitive |
| Probabilistic | Sample percentage | Production (1-10%) |
| Rate Limited | Sample N per second | Consistent overhead |
| Parent-Based | Follow parent decision | Distributed consistency |

**Sampling Best Practices:**

1. **Respect Parent Decisions**: If parent is sampled, child should be sampled
2. **Consistent Sampling**: Use same rate across services
3. **Head-Based Sampling**: Decide at trace start
4. **Tail-Based Sampling**: Decide after trace completes (for error traces)

### Response Headers

Include trace information in responses for debugging:

```
X-Request-ID: req_abc123xyz789
X-Trace-ID: 463ac35c9f6413ad48485a3953bb6124
```

**Standard Response Headers:**

| Header | Description |
|--------|-------------|
| X-Request-ID | Application request identifier |
| X-Trace-ID | Trace identifier for correlation |
| X-Span-ID | Current span identifier |

### Logging Correlation

Include trace context in all log entries:

**Structured Log Format:**
```json
{
  "timestamp": "2026-01-23T10:30:00Z",
  "level": "INFO",
  "message": "Order created",
  "trace_id": "463ac35c9f6413ad48485a3953bb6124",
  "span_id": "0020000000000001",
  "parent_span_id": "b7ad6b7169203331",
  "service": "order-service",
  "order_id": "ord_123456"
}
```

### Error Handling

**Invalid Header Handling:**

| Scenario | Action |
|----------|--------|
| Missing headers | Generate new trace context |
| Malformed traceparent | Generate new trace context |
| Invalid trace-id (all zeros) | Generate new trace context |
| Unknown version | Best effort parse or regenerate |
| Invalid B3 format | Generate new trace context |

**Never fail a request due to invalid trace headers.** Generate new context and continue.

---

## Multi-Format Support

### Supporting Both Standards

For maximum interoperability, support both W3C and B3 formats:

**Detection Priority:**
1. Check for `traceparent` (W3C)
2. Check for `X-B3-TraceId` (B3 Multi)
3. Check for `b3` (B3 Single)
4. Generate new context if none found

**Propagation Strategy:**
- Propagate in the same format received
- Or propagate in both formats for downstream compatibility

**Header Translation:**

| W3C Field | B3 Field |
|-----------|----------|
| trace-id | X-B3-TraceId |
| parent-id | X-B3-SpanId (of parent) |
| trace-flags (sampled bit) | X-B3-Sampled |

---

## Webhook Trace Context

### Including Traces in Webhooks

Include trace context in webhook deliveries for end-to-end tracing:

**Webhook Headers:**
```
POST /webhooks/receive HTTP/1.1
Host: client.example.com
Content-Type: application/json
traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
X-Webhook-ID: whk_abc123
X-Request-ID: req_xyz789

{
  "event_id": "evt_123",
  "event_type": "order.created",
  "trace_id": "0af7651916cd43dd8448eb211c80319c",
  ...
}
```

**Benefits:**
- Correlate webhook delivery with original request
- Debug webhook processing issues
- End-to-end latency tracking

---

## Security Considerations

### Trace Context Security

| Risk | Mitigation |
|------|------------|
| Information disclosure | Don't include sensitive data in tracestate |
| Trace injection | Validate header formats |
| Sampling bypass | Enforce server-side sampling decisions |
| DoS via tracing | Rate limit trace generation |

### Best Practices

1. **Validate Input**: Always validate trace header formats
2. **Sanitize Tracestate**: Don't blindly forward unknown vendor data
3. **Limit Tracestate Size**: Enforce maximum entries (32)
4. **Don't Trust Sampling**: Server can override client sampling
5. **Secure Trace Data**: Treat trace data as potentially sensitive

---

## Trace Context Checklist

### Implementation

- [ ] Parse W3C traceparent header
- [ ] Parse B3 multi-header format
- [ ] Generate valid trace/span IDs
- [ ] Propagate context to downstream services
- [ ] Include trace ID in response headers
- [ ] Correlate logs with trace context
- [ ] Handle invalid/missing headers gracefully

### Observability

- [ ] Export traces to tracing backend
- [ ] Configure appropriate sampling rate
- [ ] Include span attributes/tags
- [ ] Record span timing
- [ ] Capture errors in spans

---

## Related Documentation

- [Webhook Security Reference](webhook-security.md) - Webhook tracing integration
- [Advanced REST Patterns Reference](advanced-rest-patterns.md) - Request tracking
- [Security Headers Reference](security-headers.md) - HTTP header security
