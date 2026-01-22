# Webhook Security Reference

This guide documents security measures for webhook implementations, including signature verification, timestamp validation, and secret management.

## Overview

Webhook security ensures that:
1. Payloads originate from the expected sender
2. Payloads have not been tampered with
3. Replay attacks are prevented
4. Secrets are managed securely

---

## Signature Verification

### HMAC-SHA256

The standard approach for webhook signatures is HMAC-SHA256 ([RFC 2104](https://datatracker.ietf.org/doc/html/rfc2104)).

**How HMAC Works:**

1. Sender creates a message (webhook payload)
2. Sender computes HMAC using shared secret and message
3. Sender includes signature in HTTP header
4. Receiver computes HMAC using same secret and received message
5. Receiver compares computed signature with received signature
6. If signatures match, message is authentic and unmodified

### Signature Header Format

**Common Header Names:**

| Provider Style | Header Name |
|----------------|-------------|
| Generic | `X-Webhook-Signature` |
| Stripe Style | `Stripe-Signature` |
| GitHub Style | `X-Hub-Signature-256` |

**Header Value Formats:**

```
# Simple format
X-Webhook-Signature: sha256=5d5b09f6dcb2d53a5fffc60c4ac0d55fabdf556069d6631545f42aa6e3500f2e

# Structured format (with timestamp)
X-Webhook-Signature: t=1706090400,v1=5d5b09f6dcb2d53a5fffc60c4ac0d55fabdf556069d6631545f42aa6e3500f2e
```

### Signature Generation Process

**Step 1: Prepare the Signed Payload**

Combine timestamp and payload body:

```
signed_payload = {timestamp}.{request_body}
```

Example:
```
signed_payload = "1706090400.{\"event_id\":\"evt_123\",\"event_type\":\"order.created\",...}"
```

**Step 2: Compute HMAC**

```
signature = HMAC-SHA256(webhook_secret, signed_payload)
```

**Step 3: Format Header**

```
X-Webhook-Signature: t=1706090400,v1={hex(signature)}
X-Webhook-Timestamp: 1706090400
```

### Signature Verification Process

**Step 1: Extract Components**

From headers, extract:
- Timestamp (`t` parameter or `X-Webhook-Timestamp`)
- Signature (`v1` parameter or signature value)

**Step 2: Reconstruct Signed Payload**

```
signed_payload = {extracted_timestamp}.{raw_request_body}
```

**Important**: Use the raw request body exactly as received, before any parsing or modification.

**Step 3: Compute Expected Signature**

```
expected_signature = HMAC-SHA256(stored_secret, signed_payload)
```

**Step 4: Compare Signatures**

Use constant-time comparison to prevent timing attacks:

```
is_valid = constant_time_compare(received_signature, expected_signature)
```

**Step 5: Validate Timestamp**

See Timestamp Validation section below.

### Signature Verification Failures

| Failure Reason | Response | Action |
|----------------|----------|--------|
| Missing signature header | 401 Unauthorized | Reject immediately |
| Invalid signature format | 400 Bad Request | Reject immediately |
| Signature mismatch | 401 Unauthorized | Reject, log attempt |
| Timestamp too old | 401 Unauthorized | Reject (replay attack) |
| Unknown webhook secret | 401 Unauthorized | Reject, log attempt |

---

## Timestamp Validation

### Purpose

Timestamp validation prevents replay attacks where an attacker captures a valid webhook and resends it later.

### Validation Rules

**Timestamp Header:**
```
X-Webhook-Timestamp: 1706090400
```

**Validation Steps:**

1. Extract timestamp from header
2. Calculate time difference: `diff = current_time - webhook_timestamp`
3. Reject if difference exceeds tolerance window

**Recommended Tolerance:**

| Scenario | Tolerance |
|----------|-----------|
| Standard | 5 minutes (300 seconds) |
| High Security | 1 minute (60 seconds) |
| Relaxed (debugging) | 15 minutes (900 seconds) |

### Clock Skew Considerations

Allow for clock differences between systems:

- Server clocks may not be perfectly synchronized
- Network latency can delay delivery
- Processing queues can add delay

**Best Practices:**

1. Use NTP to synchronize server clocks
2. Include tolerance for clock skew (±30 seconds)
3. Log timestamp rejections for monitoring

---

## Secret Management

### Secret Generation

**Requirements:**

| Property | Requirement |
|----------|-------------|
| Length | Minimum 32 bytes (256 bits) |
| Entropy | Cryptographically random |
| Format | Base64 or hex encoded |
| Prefix | Use identifying prefix (e.g., `whsec_`) |

**Secret Format Example:**
```
whsec_Kx2YhB8vP9mQ3wE7jR1nT6uZ4aD0gF5cL8iO
```

### Secret Storage

**Server-Side (API Provider):**

| Requirement | Description |
|-------------|-------------|
| Encryption | Encrypt secrets at rest |
| Access Control | Limit access to webhook service |
| Audit Logging | Log all secret access |
| Separate Storage | Store separately from other credentials |

**Client-Side (Webhook Consumer):**

| Requirement | Description |
|-------------|-------------|
| Environment Variables | Store in environment, not code |
| Secrets Manager | Use dedicated secrets management |
| Never Log | Never log or output secrets |
| Access Control | Limit access to webhook handler |

### Secret Rotation

**Rotation Process:**

1. **Generate New Secret**: Create new secret without invalidating old
2. **Transition Period**: Support both old and new secrets
3. **Update Clients**: Clients update to new secret
4. **Invalidate Old**: Remove old secret after transition

**Supporting Multiple Secrets:**

During rotation, verify against multiple secrets:

```
secrets = [current_secret, previous_secret]
for secret in secrets:
    if verify_signature(payload, received_signature, secret):
        return True
return False
```

**Rotation Schedule:**

| Scenario | Rotation Frequency |
|----------|-------------------|
| Standard | Every 90 days |
| High Security | Every 30 days |
| After Compromise | Immediately |

### Secret Exposure Response

If a webhook secret is compromised:

1. **Immediately** generate new secret
2. **Notify** affected client
3. **Invalidate** old secret
4. **Audit** for unauthorized deliveries
5. **Review** security practices

---

## HTTPS Requirements

### Mandatory HTTPS

**Production Requirements:**

| Requirement | Description |
|-------------|-------------|
| TLS 1.2+ | Minimum TLS version |
| Valid Certificate | Certificate from trusted CA |
| Certificate Chain | Complete chain provided |
| No Self-Signed | Reject self-signed certificates |

### Certificate Validation

When delivering webhooks, validate:

1. Certificate is not expired
2. Certificate is issued by trusted CA
3. Certificate hostname matches URL
4. Certificate chain is valid

### Development Exceptions

For local development only:

| Environment | HTTPS Requirement |
|-------------|-------------------|
| Production | Required |
| Staging | Required |
| Development | Optional (HTTP allowed) |
| Local Testing | Optional (localhost) |

---

## IP Allowlisting

### When to Use

IP allowlisting provides additional security layer but has limitations.

**Consider Using When:**

- High-security requirements
- Static infrastructure
- Compliance requirements

**Limitations:**

- IP addresses can change
- Doesn't protect against compromised IPs
- Complicates scaling and failover
- Not available from all providers

### Implementation

**Publish Webhook IP Ranges:**

```
GET /v1/webhook-ips HTTP/1.1
Host: api.example.com
```

```json
{
  "ipv4": [
    "203.0.113.0/24",
    "198.51.100.0/24"
  ],
  "ipv6": [
    "2001:db8::/32"
  ],
  "updated_at": "2026-01-23T00:00:00Z"
}
```

**Client Implementation:**

1. Fetch IP ranges periodically (daily)
2. Validate source IP of incoming webhooks
3. Reject requests from unknown IPs
4. Log rejected attempts

---

## Additional Security Measures

### Request ID Tracking

Include unique request ID for debugging and audit:

```
X-Request-ID: req_abc123xyz789
```

**Uses:**
- Correlate logs between systems
- Debug delivery issues
- Audit trail

### Payload Size Limits

Enforce maximum payload size:

| Component | Limit |
|-----------|-------|
| Request Body | 256 KB - 1 MB |
| Individual Field | 64 KB |
| Array Items | 1000 items |

### Rate Limiting

Protect webhook endpoints from abuse:

| Limit Type | Recommended |
|------------|-------------|
| Per Subscription | 1000/hour |
| Per Event Type | 100/minute |
| Burst | 10/second |

### Audit Logging

Log all webhook activity:

| Event | Log Fields |
|-------|------------|
| Delivery Attempt | timestamp, event_id, subscription_id, url, status |
| Signature Failure | timestamp, source_ip, subscription_id, reason |
| Secret Access | timestamp, accessor, action |
| Secret Rotation | timestamp, subscription_id, initiator |

---

## Security Checklist

### Sender (API Provider)

- [ ] Generate cryptographically random secrets
- [ ] Sign all payloads with HMAC-SHA256
- [ ] Include timestamp in signed payload
- [ ] Support secret rotation with overlap period
- [ ] Enforce HTTPS for webhook URLs
- [ ] Publish IP ranges if using allowlisting
- [ ] Include request ID for tracking
- [ ] Log all delivery attempts

### Receiver (Webhook Consumer)

- [ ] Verify signature on every request
- [ ] Use constant-time comparison for signatures
- [ ] Validate timestamp is within tolerance
- [ ] Store secrets securely
- [ ] Reject non-HTTPS in production
- [ ] Implement IP allowlisting (if available)
- [ ] Log signature verification failures
- [ ] Handle secret rotation gracefully

---

## Common Vulnerabilities

### Timing Attacks

**Vulnerability**: Using standard string comparison for signatures leaks timing information.

**Mitigation**: Use constant-time comparison function.

### Replay Attacks

**Vulnerability**: Attacker captures valid webhook and resends.

**Mitigation**: Validate timestamps and reject old requests.

### Secret Exposure

**Vulnerability**: Secrets logged, committed to source control, or exposed in errors.

**Mitigation**: 
- Never log secrets
- Use environment variables
- Rotate secrets after potential exposure

### Missing Signature Verification

**Vulnerability**: Webhook endpoints that don't verify signatures.

**Mitigation**: Always verify signatures; reject unsigned requests.

### HTTPS Downgrade

**Vulnerability**: Accepting HTTP webhooks allows interception.

**Mitigation**: Enforce HTTPS for all webhook URLs.

---

## Related Documentation

- [Webhooks Implementation Guide](webhooks-implementation-guide.md) - Full webhook implementation
- [OAuth2 Flows Reference](oauth2-flows.md) - API authentication
- [Security Headers Reference](security-headers.md) - Additional security measures
