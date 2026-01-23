# Advanced Portman Configuration Examples

This document provides advanced configuration examples for Portman to handle complex testing scenarios.

## Complete Configuration Example

```json
{
  "$schema": "https://raw.githubusercontent.com/apideck-libraries/portman/main/portman-config.schema.json",
  "version": 1.0,
  "globals": {
    "stripResponseExamples": false,
    "variableCasing": "camelCase",
    "separatorSymbol": "::",
    "collectionVariables": {
      "baseUrl": "{{baseUrl}}",
      "apiVersion": "v1"
    },
    "securityOverwrites": {
      "bearer": {
        "token": "{{accessToken}}"
      }
    },
    "collectionPreRequestScripts": [
      "// Set timestamp for requests",
      "pm.collectionVariables.set('timestamp', new Date().toISOString());"
    ],
    "collectionTestScripts": [
      "// Log response time",
      "console.log('Response time:', pm.response.responseTime, 'ms');"
    ],
    "keyValueReplacements": {
      "api_key": "{{apiKey}}",
      "organization_id": "{{organizationId}}"
    },
    "orderOfOperations": [
      "healthCheck",
      "authenticate",
      "listResources",
      "getResource",
      "createResource",
      "updateResource",
      "deleteResource"
    ]
  },
  "tests": {
    "contractTests": [
      {
        "openApiOperation": "*::*",
        "statusSuccess": true,
        "responseTime": {
          "maxMs": 500
        },
        "contentType": true,
        "jsonBody": true,
        "schemaValidation": true,
        "headersPresent": true
      }
    ],
    "contentTests": [
      {
        "openApiOperation": "GET::/health",
        "responseBodyTests": [
          {
            "key": "status",
            "value": "healthy"
          }
        ]
      }
    ],
    "variationTests": [
      {
        "name": "Unauthorized - Missing Token",
        "openApiOperation": "*::/api/*",
        "openApiResponse": "401",
        "overwrites": [
          {
            "overwriteRequestSecurity": {
              "remove": true
            }
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
        "name": "Unauthorized - Invalid Token",
        "openApiOperation": "*::/api/*",
        "openApiResponse": "401",
        "overwrites": [
          {
            "overwriteRequestHeaders": [
              {
                "key": "Authorization",
                "value": "Bearer invalid-token-12345",
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
        "name": "Not Found - Invalid ID",
        "openApiOperation": "GET::/api/*/{{id}}",
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
    ],
    "integrationTests": [
      {
        "name": "Resource CRUD Workflow",
        "operations": [
          {
            "openApiOperationId": "createResource",
            "variations": [
              {
                "name": "Create Resource",
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
                        "name": "createdResourceId"
                      }
                    ]
                  }
                ]
              }
            ]
          },
          {
            "openApiOperationId": "getResource",
            "variations": [
              {
                "name": "Get Created Resource",
                "overwrites": [
                  {
                    "overwriteRequestPathVariables": [
                      {
                        "key": "id",
                        "value": "{{createdResourceId}}",
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
            "openApiOperationId": "updateResource",
            "variations": [
              {
                "name": "Update Created Resource",
                "overwrites": [
                  {
                    "overwriteRequestPathVariables": [
                      {
                        "key": "id",
                        "value": "{{createdResourceId}}",
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
            "openApiOperationId": "deleteResource",
            "variations": [
              {
                "name": "Delete Created Resource",
                "overwrites": [
                  {
                    "overwriteRequestPathVariables": [
                      {
                        "key": "id",
                        "value": "{{createdResourceId}}",
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
  },
  "assignVariables": [
    {
      "openApiOperationId": "authenticate",
      "collectionVariables": [
        {
          "responseBodyProp": "access_token",
          "name": "accessToken"
        },
        {
          "responseBodyProp": "refresh_token",
          "name": "refreshToken"
        },
        {
          "responseBodyProp": "expires_in",
          "name": "tokenExpiresIn"
        }
      ]
    }
  ],
  "overwrites": [
    {
      "openApiOperation": "*::*",
      "overwriteRequestHeaders": [
        {
          "key": "X-Request-Id",
          "value": "{{$guid}}",
          "overwrite": true
        },
        {
          "key": "X-Correlation-Id",
          "value": "{{$guid}}",
          "overwrite": true
        }
      ]
    }
  ],
  "operationPreRequestScripts": [
    {
      "openApiOperationId": "authenticate",
      "scripts": [
        "// Clear existing tokens before authentication",
        "pm.collectionVariables.unset('accessToken');",
        "pm.collectionVariables.unset('refreshToken');"
      ]
    }
  ]
}
```

## Fuzzing Configuration Example

Testing API validation with invalid inputs:

```json
{
  "tests": {
    "variationTests": [
      {
        "name": "Fuzzing - Missing Required Fields",
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
          ],
          "contentTests": [
            {
              "responseBodyTests": [
                {
                  "key": "error.type",
                  "value": "validation_error"
                }
              ]
            }
          ]
        }
      },
      {
        "name": "Fuzzing - Below Minimum Values",
        "openApiOperation": "POST::/api/users",
        "openApiResponse": "400",
        "fuzzing": {
          "requestBody": [
            {
              "minimumNumberFields": true
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
      },
      {
        "name": "Fuzzing - Above Maximum Values",
        "openApiOperation": "POST::/api/users",
        "openApiResponse": "400",
        "fuzzing": {
          "requestBody": [
            {
              "maximumNumberFields": true
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
      },
      {
        "name": "Fuzzing - String Too Short",
        "openApiOperation": "POST::/api/users",
        "openApiResponse": "400",
        "fuzzing": {
          "requestBody": [
            {
              "minLengthFields": true
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
      },
      {
        "name": "Fuzzing - String Too Long",
        "openApiOperation": "POST::/api/users",
        "openApiResponse": "400",
        "fuzzing": {
          "requestBody": [
            {
              "maxLengthFields": true
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

## OAuth2 Authentication Configuration

For APIs using OAuth2 authentication:

```json
{
  "globals": {
    "securityOverwrites": {
      "oauth2": [
        {
          "key": "accessToken",
          "value": "{{accessToken}}",
          "type": "string"
        },
        {
          "key": "tokenType",
          "value": "Bearer",
          "type": "string"
        },
        {
          "key": "addTokenTo",
          "value": "header",
          "type": "string"
        }
      ]
    }
  },
  "operationPreRequestScripts": [
    {
      "openApiOperation": "*::/api/*",
      "scripts": [
        "file:scripts/oauth2-token-refresh.js"
      ]
    }
  ]
}
```

**oauth2-token-refresh.js:**

```javascript
// Check if token is expired or about to expire
const tokenExpiry = pm.collectionVariables.get('tokenExpiry');
const currentTime = Date.now();

if (!tokenExpiry || currentTime >= parseInt(tokenExpiry) - 60000) {
    // Token expired or will expire in less than 60 seconds
    console.log('Token expired, refreshing...');
    
    const refreshToken = pm.collectionVariables.get('refreshToken');
    
    pm.sendRequest({
        url: pm.collectionVariables.get('baseUrl') + '/oauth/token',
        method: 'POST',
        header: {
            'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {
            mode: 'urlencoded',
            urlencoded: [
                { key: 'grant_type', value: 'refresh_token' },
                { key: 'refresh_token', value: refreshToken },
                { key: 'client_id', value: pm.collectionVariables.get('clientId') },
                { key: 'client_secret', value: pm.collectionVariables.get('clientSecret') }
            ]
        }
    }, (err, res) => {
        if (err) {
            console.error('Token refresh failed:', err);
        } else {
            const response = res.json();
            pm.collectionVariables.set('accessToken', response.access_token);
            pm.collectionVariables.set('refreshToken', response.refresh_token);
            pm.collectionVariables.set('tokenExpiry', Date.now() + (response.expires_in * 1000));
        }
    });
}
```

## API Key Authentication Configuration

For APIs using API key authentication:

```json
{
  "globals": {
    "securityOverwrites": {
      "apiKey": {
        "key": "X-API-Key",
        "value": "{{apiKey}}",
        "in": "header"
      }
    }
  }
}
```

## Basic Authentication Configuration

For APIs using basic authentication:

```json
{
  "globals": {
    "securityOverwrites": {
      "basic": {
        "username": "{{username}}",
        "password": "{{password}}"
      }
    }
  }
}
```

## Content Type Variations

Testing different content types:

```json
{
  "tests": {
    "variationTests": [
      {
        "name": "Accept JSON",
        "openApiOperation": "GET::/api/data",
        "openApiResponse": "200::application/json",
        "overwrites": [
          {
            "overwriteRequestHeaders": [
              {
                "key": "Accept",
                "value": "application/json",
                "overwrite": true
              }
            ]
          }
        ],
        "tests": {
          "contractTests": [
            {
              "statusCode": 200,
              "contentType": true
            }
          ]
        }
      },
      {
        "name": "Accept XML",
        "openApiOperation": "GET::/api/data",
        "openApiResponse": "200::application/xml",
        "overwrites": [
          {
            "overwriteRequestHeaders": [
              {
                "key": "Accept",
                "value": "application/xml",
                "overwrite": true
              }
            ]
          }
        ],
        "tests": {
          "contractTests": [
            {
              "statusCode": 200,
              "contentType": true
            }
          ]
        }
      }
    ]
  }
}
```

## Pagination Testing

Testing paginated endpoints:

```json
{
  "tests": {
    "variationTests": [
      {
        "name": "Pagination - First Page",
        "openApiOperationId": "listItems",
        "overwrites": [
          {
            "overwriteRequestQueryParams": [
              {
                "key": "page",
                "value": "1",
                "overwrite": true
              },
              {
                "key": "limit",
                "value": "10",
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
          ],
          "contentTests": [
            {
              "responseBodyTests": [
                {
                  "key": "data",
                  "maxLength": 10
                },
                {
                  "key": "meta.page",
                  "value": 1
                }
              ]
            }
          ]
        }
      },
      {
        "name": "Pagination - Empty Page",
        "openApiOperationId": "listItems",
        "overwrites": [
          {
            "overwriteRequestQueryParams": [
              {
                "key": "page",
                "value": "99999",
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
          ],
          "contentTests": [
            {
              "responseBodyTests": [
                {
                  "key": "data",
                  "length": 0
                }
              ]
            }
          ]
        }
      }
    ]
  }
}
```

## Extended Tests with Custom Scripts

Adding custom test scripts:

```json
{
  "tests": {
    "extendTests": [
      {
        "openApiOperationId": "createOrder",
        "tests": [
          "// Custom validation for order creation",
          "pm.test('Order ID is a valid UUID', function() {",
          "    const response = pm.response.json();",
          "    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;",
          "    pm.expect(response.id).to.match(uuidRegex);",
          "});",
          "",
          "pm.test('Created timestamp is recent', function() {",
          "    const response = pm.response.json();",
          "    const createdAt = new Date(response.created_at);",
          "    const now = new Date();",
          "    const diffMs = now - createdAt;",
          "    pm.expect(diffMs).to.be.below(60000); // Within last minute",
          "});"
        ],
        "append": true
      }
    ]
  }
}
```

## Environment-Specific Configurations

### Local Development (portman-config.local.json)

```json
{
  "version": 1.0,
  "globals": {
    "collectionVariables": {
      "baseUrl": "http://localhost:3000",
      "apiVersion": "v1"
    }
  },
  "tests": {
    "contractTests": [
      {
        "openApiOperation": "*::*",
        "statusSuccess": true,
        "schemaValidation": true,
        "responseTime": {
          "maxMs": 1000
        }
      }
    ]
  }
}
```

### Staging (portman-config.staging.json)

```json
{
  "version": 1.0,
  "globals": {
    "collectionVariables": {
      "baseUrl": "https://api.staging.example.com",
      "apiVersion": "v1"
    }
  },
  "tests": {
    "contractTests": [
      {
        "openApiOperation": "*::*",
        "statusSuccess": true,
        "schemaValidation": true,
        "responseTime": {
          "maxMs": 500
        }
      }
    ]
  }
}
```

### Production Smoke Tests (portman-config.prod.json)

```json
{
  "version": 1.0,
  "globals": {
    "collectionVariables": {
      "baseUrl": "https://api.example.com",
      "apiVersion": "v1"
    }
  },
  "tests": {
    "contractTests": [
      {
        "openApiOperation": "GET::/health",
        "statusCode": 200
      },
      {
        "openApiOperation": "GET::/api/*",
        "excludeForOperations": ["POST::*", "PUT::*", "DELETE::*", "PATCH::*"],
        "statusSuccess": true,
        "responseTime": {
          "maxMs": 300
        }
      }
    ]
  }
}
```

## CLI Options File

Instead of passing many CLI options, use a configuration file:

**portman-cli-options.json:**

```json
{
  "local": "openapi.yaml",
  "output": "postman-collection.json",
  "portmanConfigFile": "portman-config.json",
  "postmanConfigFile": "postman-config.json",
  "runNewman": true,
  "newmanOptionsFile": "newman-options.json",
  "bundleContractTests": true,
  "includeTests": true,
  "logAssignVariables": true
}
```

Run with:

```bash
npx portman --cliOptionsFile portman-cli-options.json
```

## References

- [Portman GitHub Repository](https://github.com/apideck-libraries/portman)
- [Portman Examples](https://github.com/apideck-libraries/portman/tree/main/examples)
- [Contract Tests Example](https://github.com/apideck-libraries/portman/tree/main/examples/testsuite-contract-tests)
- [Variation Tests Example](https://github.com/apideck-libraries/portman/tree/main/examples/testsuite-variation-tests)
- [Integration Tests Example](https://github.com/apideck-libraries/portman/tree/main/examples/testsuite-integration-tests)
- [Fuzzing Tests Example](https://github.com/apideck-libraries/portman/tree/main/examples/testsuite-fuzzing-tests)
