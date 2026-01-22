# OpenID Connect Reference

OpenID Connect (OIDC) is an identity layer built on top of OAuth2, defined by the [OpenID Foundation](https://openid.net/specs/openid-connect-core-1_0.html). It provides a standardized way to authenticate users and obtain their identity information.

## Overview

### OAuth2 vs OpenID Connect

| Aspect | OAuth2 | OpenID Connect |
|--------|--------|----------------|
| Purpose | Authorization | Authentication + Authorization |
| Question Answered | "What can this app access?" | "Who is this user?" |
| Primary Token | Access Token | Access Token + ID Token |
| User Identity | Not standardized | Standardized claims in ID Token |
| Discovery | Not defined | `.well-known/openid-configuration` |
| Specification | RFC 6749 | OpenID Connect Core 1.0 |

### When to Use OIDC

- **Single Sign-On (SSO)**: Users sign in once, access multiple applications
- **User Authentication**: Verify user identity (not just authorization)
- **Profile Information**: Access standardized user profile data
- **Federated Identity**: Delegate authentication to identity providers

---

## Core Concepts

### ID Token

The ID Token is a JSON Web Token (JWT) that contains claims about the authentication event and the user. It's the primary extension OIDC adds to OAuth2.

**ID Token Structure:**

```
Header.Payload.Signature
```

**Header:**
```json
{
  "alg": "RS256",
  "typ": "JWT",
  "kid": "key-id-123"
}
```

**Payload (Claims):**
```json
{
  "iss": "https://auth.example.com",
  "sub": "user_123456",
  "aud": "your_client_id",
  "exp": 1706140800,
  "iat": 1706137200,
  "auth_time": 1706137100,
  "nonce": "abc123xyz",
  "at_hash": "MTIzNDU2Nzg5MA",
  "name": "John Doe",
  "email": "john@example.com",
  "email_verified": true
}
```

### Standard Claims

OIDC defines standard claims that can appear in ID Tokens and UserInfo responses.

**Required Claims (in ID Token):**

| Claim | Description |
|-------|-------------|
| iss | Issuer identifier (URL) |
| sub | Subject identifier (unique user ID) |
| aud | Audience (client_id) |
| exp | Expiration time (Unix timestamp) |
| iat | Issued at time (Unix timestamp) |

**Common Optional Claims:**

| Claim | Description | Scope Required |
|-------|-------------|----------------|
| name | Full name | profile |
| given_name | First name | profile |
| family_name | Last name | profile |
| nickname | Casual name | profile |
| preferred_username | Username | profile |
| profile | Profile page URL | profile |
| picture | Profile picture URL | profile |
| website | Website URL | profile |
| email | Email address | email |
| email_verified | Email verification status | email |
| gender | Gender | profile |
| birthdate | Birthday (YYYY-MM-DD) | profile |
| zoneinfo | Timezone | profile |
| locale | Locale (e.g., en-US) | profile |
| phone_number | Phone number | phone |
| phone_number_verified | Phone verification status | phone |
| address | Postal address (JSON object) | address |
| updated_at | Last profile update (Unix timestamp) | profile |

### Scopes

OIDC defines standard scopes that map to sets of claims.

| Scope | Claims Included |
|-------|-----------------|
| openid | (Required) Enables OIDC; returns sub claim |
| profile | name, family_name, given_name, nickname, preferred_username, profile, picture, website, gender, birthdate, zoneinfo, locale, updated_at |
| email | email, email_verified |
| address | address |
| phone | phone_number, phone_number_verified |
| offline_access | Requests refresh token |

---

## Discovery Endpoint

OIDC defines a discovery mechanism that allows clients to automatically configure themselves.

### Well-Known Configuration

**Endpoint**: `/.well-known/openid-configuration`

**Request:**
```
GET /.well-known/openid-configuration HTTP/1.1
Host: auth.example.com
```

**Response:**
```json
{
  "issuer": "https://auth.example.com",
  "authorization_endpoint": "https://auth.example.com/oauth/authorize",
  "token_endpoint": "https://auth.example.com/oauth/token",
  "userinfo_endpoint": "https://auth.example.com/userinfo",
  "jwks_uri": "https://auth.example.com/.well-known/jwks.json",
  "registration_endpoint": "https://auth.example.com/oauth/register",
  "scopes_supported": ["openid", "profile", "email", "address", "phone", "offline_access"],
  "response_types_supported": ["code", "token", "id_token", "code token", "code id_token", "token id_token", "code token id_token"],
  "response_modes_supported": ["query", "fragment", "form_post"],
  "grant_types_supported": ["authorization_code", "client_credentials", "refresh_token", "urn:ietf:params:oauth:grant-type:device_code"],
  "subject_types_supported": ["public", "pairwise"],
  "id_token_signing_alg_values_supported": ["RS256", "ES256"],
  "token_endpoint_auth_methods_supported": ["client_secret_basic", "client_secret_post", "private_key_jwt"],
  "claims_supported": ["iss", "sub", "aud", "exp", "iat", "name", "email", "email_verified"],
  "code_challenge_methods_supported": ["S256"]
}
```

**Key Configuration Fields:**

| Field | Description |
|-------|-------------|
| issuer | Base URL of the authorization server |
| authorization_endpoint | URL for authorization requests |
| token_endpoint | URL for token requests |
| userinfo_endpoint | URL for user info requests |
| jwks_uri | URL for JSON Web Key Set (for token validation) |
| scopes_supported | List of supported scopes |
| claims_supported | List of supported claims |
| id_token_signing_alg_values_supported | Supported signing algorithms |

---

## UserInfo Endpoint

The UserInfo endpoint returns claims about the authenticated user.

### Request Format

```
GET /userinfo HTTP/1.1
Host: auth.example.com
Authorization: Bearer {access_token}
```

Or:

```
POST /userinfo HTTP/1.1
Host: auth.example.com
Content-Type: application/x-www-form-urlencoded

access_token={access_token}
```

### Response Format

```json
{
  "sub": "user_123456",
  "name": "John Doe",
  "given_name": "John",
  "family_name": "Doe",
  "preferred_username": "johnd",
  "email": "john@example.com",
  "email_verified": true,
  "picture": "https://example.com/johnd/photo.jpg",
  "locale": "en-US",
  "updated_at": 1706137200
}
```

### Claims Returned

The claims returned depend on:
1. Scopes requested during authorization
2. Scopes granted by the user
3. Claims the provider supports

---

## OIDC Authentication Flow

OIDC uses the OAuth2 Authorization Code flow with additional parameters.

### Authorization Request

```
GET /oauth/authorize HTTP/1.1
Host: auth.example.com

Parameters:
  response_type=code
  client_id=your_client_id
  redirect_uri=https://your-app.com/callback
  scope=openid profile email
  state=abc123
  nonce=xyz789
  code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM
  code_challenge_method=S256
```

**OIDC-Specific Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| scope | Yes | Must include `openid` |
| nonce | Recommended | Random value for replay protection |
| prompt | No | `none`, `login`, `consent`, `select_account` |
| max_age | No | Maximum authentication age in seconds |
| ui_locales | No | Preferred UI languages |
| acr_values | No | Requested authentication context class |

### Token Response

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "scope": "openid profile email"
}
```

---

## ID Token Validation

Always validate ID tokens before trusting their contents.

### Validation Steps

1. **Decode JWT**: Parse header, payload, and signature
2. **Verify Signature**: 
   - Fetch JWKS from `jwks_uri`
   - Find key matching `kid` in token header
   - Verify signature using public key
3. **Validate Claims**:

| Claim | Validation |
|-------|------------|
| iss | Must match expected issuer |
| aud | Must contain your client_id |
| exp | Must be in the future |
| iat | Must be in the past (with clock skew tolerance) |
| nonce | Must match value sent in authorization request |
| at_hash | If present, must match hash of access token |

### JSON Web Key Set (JWKS)

**Request:**
```
GET /.well-known/jwks.json HTTP/1.1
Host: auth.example.com
```

**Response:**
```json
{
  "keys": [
    {
      "kty": "RSA",
      "alg": "RS256",
      "use": "sig",
      "kid": "key-id-123",
      "n": "0vx7agoebGcQSuu...",
      "e": "AQAB"
    }
  ]
}
```

**JWK Fields** ([RFC 7517](https://datatracker.ietf.org/doc/html/rfc7517)):

| Field | Description |
|-------|-------------|
| kty | Key type (RSA, EC) |
| alg | Algorithm (RS256, ES256) |
| use | Usage (sig = signature) |
| kid | Key ID |
| n | RSA modulus (base64url) |
| e | RSA exponent (base64url) |

---

## Provider Variance

While OIDC is a standard, providers may have variations. Always consult provider-specific documentation.

### Common Variations

| Aspect | Potential Variance |
|--------|-------------------|
| Claims | Providers may support additional custom claims |
| Token Lifetimes | Default expiration times vary |
| Scopes | Additional provider-specific scopes |
| Discovery Fields | Additional configuration options |
| Algorithms | Different signing algorithms supported |
| Authentication Methods | Varying client authentication options |

### Provider-Specific Considerations

**General Guidelines:**

1. **Always use Discovery**: Don't hardcode endpoints; fetch from `.well-known/openid-configuration`
2. **Check Supported Features**: Verify required features are in discovery document
3. **Handle Custom Claims**: Providers may add claims outside the standard
4. **Token Formats**: Access tokens may be JWTs or opaque strings
5. **Refresh Token Behavior**: Rotation policies vary by provider
6. **Rate Limits**: Providers may impose rate limits on endpoints

**Questions to Answer for Each Provider:**

- What scopes and claims are supported?
- What is the token lifetime?
- How often should JWKS be refreshed?
- Are there provider-specific error codes?
- What authentication methods are supported?
- Are there additional security requirements?

---

## Session Management

OIDC defines optional session management capabilities.

### Front-Channel Logout

Allows the identity provider to log out users from all applications.

**Discovery Fields:**
```json
{
  "frontchannel_logout_supported": true,
  "frontchannel_logout_session_supported": true
}
```

### Back-Channel Logout

Server-to-server logout notification.

**Discovery Fields:**
```json
{
  "backchannel_logout_supported": true,
  "backchannel_logout_session_supported": true
}
```

### End Session Endpoint

**Request:**
```
GET /oauth/logout HTTP/1.1
Host: auth.example.com

Parameters:
  id_token_hint={id_token}
  post_logout_redirect_uri=https://your-app.com/logged-out
  state=abc123
```

---

## Security Considerations

1. **Always Validate ID Tokens**: Never trust claims without signature verification
2. **Use Nonce**: Prevent replay attacks with unique nonce per request
3. **Validate at_hash**: When access token is returned with ID token
4. **Check Token Binding**: Ensure tokens are bound to intended client
5. **Secure Token Storage**: Treat ID tokens as sensitive data
6. **Clock Skew**: Allow small tolerance for exp/iat validation (e.g., 5 minutes)
7. **HTTPS Only**: All OIDC endpoints must use HTTPS
8. **State Parameter**: Always use for CSRF protection

---

## Related Documentation

- [OAuth2 Flows Reference](oauth2-flows.md) - Underlying authorization framework
- [Security Headers Reference](security-headers.md) - Secure token transmission
- [Webhook Security Reference](webhook-security.md) - Signature verification patterns
