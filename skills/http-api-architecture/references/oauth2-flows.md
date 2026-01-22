# OAuth2 Flows Reference

This document provides detailed descriptions of OAuth2 authorization flows as defined in [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749).

## Overview

OAuth2 defines several authorization flows (grant types) for different use cases. Each flow is optimized for specific client types and security requirements.

## Flow Comparison Matrix

| Flow | Client Type | User Interaction | Refresh Token | Security Level |
|------|-------------|------------------|---------------|----------------|
| Client Credentials | Confidential | None | No | High |
| Authorization Code + PKCE | Public/Confidential | Required | Yes | Highest |
| Device Flow | Public (input-limited) | Required (separate device) | Yes | High |

---

## Client Credentials Flow

**RFC Reference**: [RFC 6749 Section 4.4](https://datatracker.ietf.org/doc/html/rfc6749#section-4.4)

### Use Cases

- Server-to-server (machine-to-machine) communication
- Backend service authentication
- Microservices communication
- Scheduled jobs and batch processes
- API integrations without user context

### Flow Description

The Client Credentials flow is the simplest OAuth2 flow. The client authenticates directly with the authorization server using its own credentials to obtain an access token.

```
┌─────────┐                                  ┌─────────────────────┐
│         │──(1) Client Authentication ────▶ │                     │
│ Client  │      + scope request             │  Authorization      │
│         │                                  │     Server          │
│         │◀──(2) Access Token ───────────── │                     │
└─────────┘                                  └─────────────────────┘
```

### Request Format

**Token Request:**

```
POST /oauth/token HTTP/1.1
Host: authorization-server.example.com
Content-Type: application/x-www-form-urlencoded
Authorization: Basic {base64(client_id:client_secret)}

grant_type=client_credentials&scope=api:read api:write
```

**Request Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| grant_type | Yes | Must be `client_credentials` |
| scope | No | Space-delimited list of requested scopes |
| client_id | Yes* | Client identifier (*if not in Authorization header) |
| client_secret | Yes* | Client secret (*if not in Authorization header) |

### Response Format

**Success Response:**

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "api:read api:write"
}
```

**Response Fields:**

| Field | Description |
|-------|-------------|
| access_token | The token to use for API requests |
| token_type | Always `Bearer` for OAuth2 |
| expires_in | Token lifetime in seconds |
| scope | Granted scopes (may differ from requested) |

### Security Considerations

1. **Client Secret Protection**: Store client secrets securely; never expose in client-side code
2. **Token Lifetime**: Use short-lived tokens (1-24 hours recommended)
3. **Scope Limitation**: Request minimum necessary scopes
4. **Secret Rotation**: Implement regular secret rotation procedures
5. **Transport Security**: Always use HTTPS

---

## Authorization Code Flow with PKCE

**RFC References**: 
- [RFC 6749 Section 4.1](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1) (Authorization Code)
- [RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE)

### Use Cases

- Web applications (server-rendered and SPAs)
- Mobile applications
- Desktop applications
- Any application where users grant access to their resources

### What is PKCE?

PKCE (Proof Key for Code Exchange) is an extension that protects the authorization code from interception attacks. It's now recommended for ALL clients, not just public clients.

**PKCE Parameters:**

| Parameter | Description |
|-----------|-------------|
| code_verifier | Random string (43-128 characters) |
| code_challenge | Base64URL-encoded SHA256 hash of code_verifier |
| code_challenge_method | Always `S256` (SHA256) |

### Flow Description

```
┌──────────┐                                 ┌─────────────────────┐
│          │──(1) Authorization Request ───▶ │                     │
│          │      + code_challenge           │                     │
│  User    │                                 │   Authorization     │
│  Agent   │◀──(2) Authorization Code ────── │      Server         │
│          │                                 │                     │
│          │──(3) Token Request ───────────▶ │                     │
│          │      + code_verifier            │                     │
│          │◀──(4) Access + Refresh Tokens ─ │                     │
└──────────┘                                 └─────────────────────┘
```

### Step 1: Generate PKCE Parameters

Before initiating the flow, generate PKCE parameters:

1. Generate a random `code_verifier` (43-128 characters, unreserved URI characters)
2. Calculate `code_challenge` = BASE64URL(SHA256(code_verifier))
3. Store `code_verifier` securely for later use

### Step 2: Authorization Request

**Request Format:**

```
GET /oauth/authorize HTTP/1.1
Host: authorization-server.example.com

Parameters:
  response_type=code
  client_id=your_client_id
  redirect_uri=https://your-app.com/callback
  scope=openid profile email
  state=abc123xyz789
  code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM
  code_challenge_method=S256
```

**Request Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| response_type | Yes | Must be `code` |
| client_id | Yes | Client identifier |
| redirect_uri | Yes | Callback URL (must be pre-registered) |
| scope | No | Space-delimited scopes |
| state | Recommended | Random string for CSRF protection |
| code_challenge | Yes (PKCE) | BASE64URL(SHA256(code_verifier)) |
| code_challenge_method | Yes (PKCE) | Must be `S256` |

### Step 3: User Authorization

The authorization server:
1. Authenticates the user (if not already authenticated)
2. Presents consent screen with requested scopes
3. Upon approval, redirects to `redirect_uri` with authorization code

**Callback Response:**

```
HTTP/1.1 302 Found
Location: https://your-app.com/callback?code=AUTH_CODE_HERE&state=abc123xyz789
```

### Step 4: Token Exchange

**Token Request:**

```
POST /oauth/token HTTP/1.1
Host: authorization-server.example.com
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code
&code=AUTH_CODE_HERE
&redirect_uri=https://your-app.com/callback
&client_id=your_client_id
&code_verifier=dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk
```

**Request Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| grant_type | Yes | Must be `authorization_code` |
| code | Yes | Authorization code from callback |
| redirect_uri | Yes | Must match original request |
| client_id | Yes | Client identifier |
| code_verifier | Yes (PKCE) | Original code verifier |
| client_secret | Conditional | Required for confidential clients |

### Response Format

**Success Response:**

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "scope": "openid profile email",
  "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Security Considerations

1. **Always Use PKCE**: Even for confidential clients
2. **Validate State**: Compare returned state with stored value
3. **Secure Storage**: Store tokens securely (HttpOnly cookies, secure storage)
4. **Short Auth Codes**: Authorization codes should be short-lived (10 minutes max)
5. **Single Use**: Authorization codes must be single-use

---

## Device Flow

**RFC Reference**: [RFC 8628](https://datatracker.ietf.org/doc/html/rfc8628)

### Use Cases

- Smart TVs and streaming devices
- Game consoles
- IoT devices
- CLI tools and terminals
- Printers and other input-constrained devices
- Any device without a browser or limited input capability

### Flow Description

```
┌──────────────┐                              ┌─────────────────────┐
│   Device     │──(1) Device Authorization ─▶ │                     │
│              │      Request                 │   Authorization     │
│              │◀──(2) Device Code + ──────── │      Server         │
│              │      User Code               │                     │
└──────────────┘                              └─────────────────────┘
       │                                              ▲
       │ Display: "Visit example.com/activate        │
       │          Enter code: ABCD-1234"             │
       ▼                                              │
┌──────────────┐                                      │
│    User      │──(3) User visits URL + ─────────────┘
│  (separate   │      enters code + authorizes
│   device)    │
└──────────────┘

┌──────────────┐                              ┌─────────────────────┐
│   Device     │──(4) Poll for Token ───────▶ │                     │
│              │      (repeated)              │   Authorization     │
│              │◀──(5) Access + Refresh ───── │      Server         │
│              │      Tokens                  │                     │
└──────────────┘                              └─────────────────────┘
```

### Step 1: Device Authorization Request

**Request Format:**

```
POST /oauth/device/code HTTP/1.1
Host: authorization-server.example.com
Content-Type: application/x-www-form-urlencoded

client_id=device_client_id&scope=api:read profile
```

**Request Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| client_id | Yes | Client identifier |
| scope | No | Space-delimited scopes |

### Step 2: Device Authorization Response

**Response Format:**

```json
{
  "device_code": "GmRhmhcxhwAzkoEqiMEg_DnyEysNkuNhszIySk9eS",
  "user_code": "ABCD-1234",
  "verification_uri": "https://auth.example.com/activate",
  "verification_uri_complete": "https://auth.example.com/activate?user_code=ABCD-1234",
  "expires_in": 1800,
  "interval": 5
}
```

**Response Fields:**

| Field | Description |
|-------|-------------|
| device_code | Code for polling (keep secret) |
| user_code | Code for user to enter (display to user) |
| verification_uri | URL for user to visit |
| verification_uri_complete | URL with code pre-filled (optional, for QR codes) |
| expires_in | Seconds until codes expire |
| interval | Minimum seconds between polling requests |

### Step 3: User Authorization

The device displays instructions to the user:
- "Visit https://auth.example.com/activate"
- "Enter code: ABCD-1234"

Optionally, display a QR code linking to `verification_uri_complete`.

The user:
1. Visits the verification URL on a separate device (phone, computer)
2. Enters the user code
3. Authenticates and grants permission

### Step 4: Token Polling

While the user authorizes, the device polls for tokens:

**Polling Request:**

```
POST /oauth/token HTTP/1.1
Host: authorization-server.example.com
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:device_code
&device_code=GmRhmhcxhwAzkoEqiMEg_DnyEysNkuNhszIySk9eS
&client_id=device_client_id
```

**Polling Response (Pending):**

```json
{
  "error": "authorization_pending",
  "error_description": "The user has not yet completed authorization"
}
```

**Polling Response (Slow Down):**

```json
{
  "error": "slow_down",
  "error_description": "Polling too frequently"
}
```

### Step 5: Token Response

**Success Response:**

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "scope": "api:read profile"
}
```

### Polling Error Codes

| Error | Description | Action |
|-------|-------------|--------|
| authorization_pending | User hasn't completed authorization | Continue polling |
| slow_down | Polling too frequently | Increase interval by 5 seconds |
| access_denied | User denied authorization | Stop polling, show error |
| expired_token | Device code expired | Restart flow |

### Security Considerations

1. **User Code Format**: Use easy-to-type codes (uppercase letters, digits, no confusing characters)
2. **Polling Interval**: Respect the `interval` parameter; increase on `slow_down`
3. **Code Expiration**: Honor `expires_in`; restart flow if expired
4. **Device Code Secrecy**: Never display `device_code` to users
5. **Rate Limiting**: Implement rate limiting on token endpoint

---

## Refresh Token Flow

**RFC Reference**: [RFC 6749 Section 6](https://datatracker.ietf.org/doc/html/rfc6749#section-6)

### Overview

Refresh tokens allow obtaining new access tokens without user interaction. They are long-lived and should be stored securely.

### Request Format

```
POST /oauth/token HTTP/1.1
Host: authorization-server.example.com
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token=dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...
&client_id=your_client_id
&scope=api:read
```

**Request Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| grant_type | Yes | Must be `refresh_token` |
| refresh_token | Yes | The refresh token |
| client_id | Yes | Client identifier |
| scope | No | Subset of original scopes (cannot expand) |

### Response Format

```json
{
  "access_token": "new_access_token...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "new_refresh_token...",
  "scope": "api:read"
}
```

### Security Considerations

1. **Refresh Token Rotation**: Issue new refresh token with each use
2. **Secure Storage**: Store refresh tokens with same security as passwords
3. **Revocation**: Implement token revocation endpoint
4. **Binding**: Consider binding refresh tokens to client instance

---

## Token Revocation

**RFC Reference**: [RFC 7009](https://datatracker.ietf.org/doc/html/rfc7009)

### Request Format

```
POST /oauth/revoke HTTP/1.1
Host: authorization-server.example.com
Content-Type: application/x-www-form-urlencoded
Authorization: Basic {base64(client_id:client_secret)}

token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
&token_type_hint=access_token
```

**Request Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| token | Yes | Token to revoke |
| token_type_hint | No | `access_token` or `refresh_token` |

### Response

Successful revocation returns `200 OK` with empty body. The endpoint should return success even if the token was already invalid (to prevent token enumeration).

---

## Common Error Responses

All OAuth2 error responses follow this format:

```json
{
  "error": "error_code",
  "error_description": "Human-readable description",
  "error_uri": "https://docs.example.com/errors/error_code"
}
```

### Error Codes

| Error | Description |
|-------|-------------|
| invalid_request | Missing or invalid parameter |
| invalid_client | Client authentication failed |
| invalid_grant | Grant (code, token) is invalid or expired |
| unauthorized_client | Client not authorized for this grant type |
| unsupported_grant_type | Grant type not supported |
| invalid_scope | Requested scope is invalid or unknown |

---

## Related Documentation

- [OpenID Connect Reference](openid-connect.md) - Identity layer on OAuth2
- [Security Headers Reference](security-headers.md) - Token transmission security
- [Advanced REST Patterns](advanced-rest-patterns.md) - Token usage in APIs
