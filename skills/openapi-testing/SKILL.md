---
name: openapi-testing
description: Guide for API contract testing and validation using Portman to convert OpenAPI specifications to Postman collections with automated tests, executed via Newman CLI.
metadata:
  author: Deerhide
  version: 1.0.0
---

# OpenAPI Testing Skill

## When to use this skill?

- Use this skill when implementing contract testing for APIs based on OpenAPI specifications
- Use this skill when validating API implementations against their OpenAPI specifications
- Use this skill when setting up automated API testing in CI/CD pipelines
- Use this skill when converting OpenAPI specifications to Postman collections with tests
- Use this skill when running API tests using Newman CLI
- Use this skill when implementing variation tests to validate error handling
- Use this skill when setting up integration tests for API workflows

## Related Skills

- [openapi](../openapi/SKILL.md) - For designing and documenting OpenAPI specifications that serve as the source for contract tests
- [http-api-architecture](../http-api-architecture/SKILL.md) - For understanding REST API design patterns, HTTP methods, status codes, and security practices that inform test cases
- [python-test](../python-test/SKILL.md) - General Python testing patterns

## What tools are used for OpenAPI testing?

We use [Portman](https://github.com/apideck-libraries/portman) to convert OpenAPI specifications to Postman collections with automated contract and variation tests, and [Newman](https://www.npmjs.com/package/newman) to execute these tests.

### Why Portman?

Portman leverages the full power of OpenAPI specifications to generate:

- **Contract Tests**: Validate API responses match the OpenAPI schema
- **Variation Tests**: Test error handling and edge cases
- **Integration Tests**: Test multi-step API workflows
- **Fuzzing Tests**: Validate API behavior with unexpected inputs

### Testing Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   OpenAPI Spec  │ ──► │     Portman     │ ──► │    Postman      │ ──► │     Newman      │
│   (source)      │     │   (converter)   │     │   Collection    │     │   (runner)      │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Installation

### Install Portman CLI

Use the installation script provided:

```bash
./scripts/install-portman.sh
```

Or install manually:

```bash
# Local installation (recommended)
npm install --save-dev @apideck/portman

# Global installation
npm install -g @apideck/portman

# Using npx (no installation required)
npx @apideck/portman -l your-openapi-file.yaml
```

### Install Newman

Newman is required to run the generated Postman collections:

```bash
# Local installation
npm install --save-dev newman

# Global installation
npm install -g newman
```

## Portman Configuration

### Basic Configuration Structure

Portman uses a JSON or YAML configuration file (`portman-config.json`):

```json
{
  "$schema": "https://raw.githubusercontent.com/apideck-libraries/portman/main/portman-config.schema.json",
  "version": 1.0,
  "globals": {},
  "tests": {
    "contractTests": [],
    "variationTests": [],
    "integrationTests": []
  },
  "assignVariables": [],
  "overwrites": [],
  "operationPreRequestScripts": []
}
```

A default configuration is provided at [assets/portman-config.json](assets/portman-config.json).

### Targeting Operations

Portman supports flexible targeting for tests:

| Method | Example | Description |
|--------|---------|-------------|
| `openApiOperationId` | `"getUserById"` | Target specific operation by ID |
| `openApiOperationIds` | `["getUsers", "getUser"]` | Target multiple operations |
| `openApiOperation` | `"GET::/users"` | Target by method and path |
| `excludeForOperations` | `["deleteUser"]` | Exclude operations from targeting |

**Wildcard Support:**

- `*::/users/*` - All methods on paths starting with `/users/`
- `GET::*` - All GET operations
- `*::*` - All operations

## Contract Tests

Contract tests validate that API responses conform to the OpenAPI specification.

### Available Contract Test Options

| Option | Description |
|--------|-------------|
| `statusSuccess` | Verify response returns 2xx status code |
| `statusCode` | Verify specific HTTP status code |
| `responseTime` | Verify response time is within threshold |
| `contentType` | Verify response content-type matches spec |
| `jsonBody` | Verify response body is valid JSON |
| `schemaValidation` | Validate response against JSON schema |
| `headersPresent` | Verify required headers are present |

### Contract Test Example

```json
{
  "tests": {
    "contractTests": [
      {
        "openApiOperation": "*::/api/*",
        "statusSuccess": true,
        "responseTime": {
          "maxMs": 500
        },
        "contentType": true,
        "jsonBody": true,
        "schemaValidation": true,
        "headersPresent": true
      }
    ]
  }
}
```

## Variation Tests

Variation tests validate error handling and edge cases by modifying requests.

### Variation Test Example

```json
{
  "tests": {
    "variationTests": [
      {
        "name": "Unauthorized Access",
        "openApiOperation": "*::/api/*",
        "openApiResponse": "401",
        "overwrites": [
          {
            "overwriteRequestHeaders": [
              {
                "key": "Authorization",
                "value": "Bearer invalid-token",
                "overwrite": true
              }
            ]
          }
        ],
        "tests": {
          "contractTests": [
            {
              "statusCode": 401
            }
          ]
        }
      },
      {
        "name": "Not Found",
        "openApiOperation": "GET::/api/resources/{id}",
        "openApiResponse": "404",
        "overwrites": [
          {
            "overwriteRequestPathVariables": [
              {
                "key": "id",
                "value": "00000000-0000-0000-0000-000000000000",
                "overwrite": true
              }
            ]
          }
        ],
        "tests": {
          "contractTests": [
            {
              "statusCode": 404
            }
          ]
        }
      }
    ]
  }
}
```

## Integration Tests

Integration tests validate multi-step API workflows and data persistence.

### Integration Test Example

```json
{
  "tests": {
    "integrationTests": [
      {
        "name": "User CRUD Workflow",
        "operations": [
          {
            "openApiOperationId": "createUser",
            "variations": [
              {
                "name": "Create User",
                "tests": {
                  "contractTests": [
                    {
                      "statusCode": 201
                    }
                  ]
                },
                "assignVariables": [
                  {
                    "collectionVariables": [
                      {
                        "responseBodyProp": "id",
                        "name": "createdUserId"
                      }
                    ]
                  }
                ]
              }
            ]
          },
          {
            "openApiOperationId": "getUser",
            "variations": [
              {
                "name": "Get Created User",
                "overwrites": [
                  {
                    "overwriteRequestPathVariables": [
                      {
                        "key": "id",
                        "value": "{{createdUserId}}",
                        "overwrite": true
                      }
                    ]
                  }
                ],
                "tests": {
                  "contractTests": [
                    {
                      "statusCode": 200
                    }
                  ]
                }
              }
            ]
          },
          {
            "openApiOperationId": "deleteUser",
            "variations": [
              {
                "name": "Delete Created User",
                "overwrites": [
                  {
                    "overwriteRequestPathVariables": [
                      {
                        "key": "id",
                        "value": "{{createdUserId}}",
                        "overwrite": true
                      }
                    ]
                  }
                ],
                "tests": {
                  "contractTests": [
                    {
                      "statusCode": 204
                    }
                  ]
                }
              }
            ]
          }
        ]
      }
    ]
  }
}
```

## Content Tests

Content tests validate specific values in API responses.

### Content Test Example

```json
{
  "tests": {
    "contentTests": [
      {
        "openApiOperation": "GET::/api/health",
        "responseBodyTests": [
          {
            "key": "status",
            "value": "healthy"
          },
          {
            "key": "version",
            "contains": "1."
          }
        ],
        "responseHeaderTests": [
          {
            "key": "X-Request-Id",
            "assert": "not.to.be.empty"
          }
        ]
      }
    ]
  }
}
```

## Fuzzing Tests

Fuzzing tests validate API behavior with invalid or unexpected inputs.

### Fuzzing Configuration

```json
{
  "tests": {
    "variationTests": [
      {
        "name": "Fuzzing - Required Fields Missing",
        "openApiOperation": "POST::/api/users",
        "openApiResponse": "400",
        "fuzzing": {
          "requestBody": [
            {
              "requiredFields": true
            }
          ]
        },
        "tests": {
          "contractTests": [
            {
              "statusCode": 400
            }
          ]
        }
      }
    ]
  }
}
```

### Available Fuzzing Options

| Option | Description |
|--------|-------------|
| `requiredFields` | Remove required fields from request |
| `minimumNumberFields` | Use values below minimum |
| `maximumNumberFields` | Use values above maximum |
| `minLengthFields` | Use strings shorter than minLength |
| `maxLengthFields` | Use strings longer than maxLength |

## Assigning Variables

Variables can be extracted from responses for use in subsequent requests.

### Variable Assignment Example

```json
{
  "assignVariables": [
    {
      "openApiOperationId": "createResource",
      "collectionVariables": [
        {
          "responseBodyProp": "id",
          "name": "resourceId"
        },
        {
          "responseHeaderProp": "Location",
          "name": "resourceLocation"
        }
      ]
    }
  ]
}
```

## Overwrites

Overwrites allow customization of request properties.

### Overwrite Example

```json
{
  "overwrites": [
    {
      "openApiOperation": "*::*",
      "overwriteRequestHeaders": [
        {
          "key": "X-Request-Id",
          "value": "{{$guid}}",
          "overwrite": true
        }
      ]
    },
    {
      "openApiOperationId": "getUser",
      "overwriteRequestPathVariables": [
        {
          "key": "id",
          "value": "{{userId}}",
          "overwrite": true
        }
      ]
    }
  ]
}
```

## Global Configuration

### Security Configuration

```json
{
  "globals": {
    "securityOverwrites": {
      "bearer": {
        "token": "{{accessToken}}"
      }
    }
  }
}
```

### Collection Variables

```json
{
  "globals": {
    "collectionVariables": {
      "baseUrl": "http://localhost:3000",
      "apiVersion": "v1"
    }
  }
}
```

### Pre-request Scripts

```json
{
  "globals": {
    "collectionPreRequestScripts": [
      "console.log('Starting request...');",
      "file:scripts/setup-auth.js"
    ]
  }
}
```

## Environment Variables

Portman supports environment variables prefixed with `PORTMAN_`:

```bash
# .env file
PORTMAN_BASE_URL=http://localhost:3000
PORTMAN_API_KEY=your-api-key
PORTMAN_USER_ID=test-user-123
```

These become available in Postman as camelCase variables:
- `{{baseUrl}}`
- `{{apiKey}}`
- `{{userId}}`

## Running Tests

### Generate Postman Collection

```bash
# From local spec
npx portman -l openapi.yaml -o collection.json -c portman-config.json

# From remote spec
npx portman -u https://api.example.com/openapi.yaml -o collection.json -c portman-config.json
```

### Run with Newman

```bash
# Basic run
npx portman -l openapi.yaml -c portman-config.json --runNewman

# With base URL override
npx portman -l openapi.yaml -c portman-config.json -b http://localhost:3000 --runNewman

# With Newman options file
npx portman -l openapi.yaml -c portman-config.json --runNewman --newmanOptionsFile newman-options.json
```

### Newman Options File

```json
{
  "reporters": ["cli", "junit"],
  "reporter": {
    "junit": {
      "export": "./test-results/newman-results.xml"
    }
  },
  "timeout": 30000,
  "insecure": false,
  "bail": false
}
```

Use the provided scripts for common operations:
- [scripts/generate-collection.sh](scripts/generate-collection.sh) - Generate Postman collection
- [scripts/run-tests.sh](scripts/run-tests.sh) - Run tests with Newman

## CI/CD Integration

### GitHub Actions Example

```yaml
name: API Contract Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  contract-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Start API server
        run: npm run start:test &
        
      - name: Wait for server
        run: npx wait-on http://localhost:3000/health
        
      - name: Run contract tests
        run: |
          npx portman \
            -l openapi.yaml \
            -c portman-config.json \
            -b http://localhost:3000 \
            --runNewman \
            --newmanOptionsFile newman-options.json
            
      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: test-results/
```

## Best Practices

### 1. Keep OpenAPI Spec as Source of Truth

- All contract tests derive from the OpenAPI specification
- Update the spec first, then regenerate tests
- Use schema validation to catch specification drift

### 2. Organize Tests by Category

```json
{
  "tests": {
    "contractTests": [...],      // Basic contract validation
    "variationTests": [...],     // Error handling
    "integrationTests": [...]    // Workflow testing
  }
}
```

### 3. Use Meaningful Variable Names

```json
{
  "assignVariables": [
    {
      "openApiOperationId": "createOrder",
      "collectionVariables": [
        {
          "responseBodyProp": "id",
          "name": "createdOrderId"
        }
      ]
    }
  ]
}
```

### 4. Test All Response Codes

Define variation tests for common error responses:

| Status Code | Test Scenario |
|-------------|---------------|
| 400 | Invalid request body |
| 401 | Missing or invalid authentication |
| 403 | Insufficient permissions |
| 404 | Resource not found |
| 409 | Conflict (duplicate resource) |
| 422 | Validation errors |

### 5. Configure Appropriate Timeouts

```json
{
  "tests": {
    "contractTests": [
      {
        "openApiOperation": "*::*",
        "responseTime": {
          "maxMs": 500
        }
      },
      {
        "openApiOperation": "*::/reports/*",
        "responseTime": {
          "maxMs": 5000
        }
      }
    ]
  }
}
```

### 6. Use Environment-Specific Configurations

Create separate configurations for different environments:

```
portman-config.json           # Base configuration
portman-config.local.json     # Local development
portman-config.staging.json   # Staging environment
portman-config.prod.json      # Production smoke tests
```

### 7. Bundle Contract Tests for Organization

```bash
npx portman -l openapi.yaml -c portman-config.json --bundleContractTests
```

This groups contract tests in a separate folder in the Postman collection.

## Troubleshooting

### Common Issues

**Schema Validation Failures:**
- Ensure response examples in OpenAPI match the schema
- Check for unknown formats using `--extraUnknownFormats`

**Authentication Errors:**
- Verify security overwrites are configured correctly
- Check environment variables are set

**Timeout Issues:**
- Increase Newman timeout in options file
- Check server startup time in CI/CD

**Circular Reference Errors:**
- Use `--ignoreCircularRefs` flag if needed
- Simplify schema references where possible

## References

- [Portman GitHub Repository](https://github.com/apideck-libraries/portman)
- [Portman Documentation](https://getportman.com/)
- [Newman Documentation](https://learning.postman.com/docs/running-collections/using-newman-cli/command-line-integration-with-newman/)
- [OpenAPI Specification](https://spec.openapis.org/oas/v3.1.0)
- [Postman Collection Format](https://learning.postman.com/collection-format/)
