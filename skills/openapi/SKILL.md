---
name: openapi
description: Provide recommendations and best practices for designing OpenAPI specifications.
metadata:
  author: Deerhide
  version: 1.0.0
---
# OpenAPI Skill

## When to use this skill?

- Use this skill when you need to design, document, or maintain RESTful APIs using the OpenAPI Specification.
- Use this skill when documenting APIs to ensure clarity, consistency, and ease of use for developers.
- Use this skill when validating, reviewing, or improving existing OpenAPI specifications.
- Use this skill when reviewing backend developer implementations against the OpenAPI specifications.

## Which version of OpenAPI did we need to use for our project?

We will use the [OpenAPI Specification version 3.1.2](https://github.com/OAI/OpenAPI-Specification/tree/3.1.2).

### OpenAPI 3.1 Features

- **JSON Schema 2020-12 alignment** - Full JSON Schema compatibility
- **Webhooks** - Document webhook/event-driven endpoints
- **Improved `$ref` handling** - Reference any type, not just schemas
- **`null` type support** - Native nullable types without `nullable: true`

## What are some best practices for designing OpenAPI specifications?

### Use Clear and Consistent Naming Conventions

- Use descriptive names for paths, parameters, and components.
- Follow a consistent naming convention: **snake_case**.
- Avoid abbreviations unless they are widely understood.

### Organize Your Specification in multiple files

- Split and organize your OpenAPI specification into multiple files for better maintainability.
- Use `$ref` to reference external files for components, paths, and schemas.
- Group related endpoints and components together.

### Always Include Descriptions and Examples

- Provide clear descriptions for paths, parameters, request bodies, and responses.
- Include examples for request bodies and responses to illustrate expected data formats.
- Use markdown formatting in descriptions for better readability.

### Resource Naming Should be Nouns and Plural

- Use nouns to represent resources in your API paths.
  Good: `/orders`, `/customers`
  Bad: `/getOrder`, `/createCustomer`
- Use plural forms for resource names to indicate collections
  Good: `/users`, `/products`
  Bad: `/user`, `/product`
- Avoid using verbs in resource names; use HTTP methods to indicate actions.
  Good: `GET /invoices`
  Bad: `/fetchInvoices`

### Action/Process Endpoints Should Use Query Parameters or Sub-resources

- For actions that do not fit standard CRUD operations, use query parameters or sub-resources.
  Good: `POST /orders/{orderId}/cancel` or `POST /orders/{orderId}?action=cancel`
  Bad: `POST /cancelOrder`
- Clearly document the purpose and usage of these endpoints in your API documentation.

### Use HTTP Methods Appropriately

- Use GET for retrieving resources.
- Use POST for creating new resources.
- Use PUT for updating existing resources.
- Use PATCH for partial updates to resources (only use it when explicitly needed).
- Use DELETE for removing resources.

### Use UUIDv4 for Resource Identifiers

- Use UUIDv4 format for resource identifiers to ensure uniqueness across distributed systems.
- Document the expected format of identifiers in the parameter descriptions.
- Validate UUIDv4 format in your API implementation.

### Segmentation Identifiers Must be Present in All Resources

- Include segmentation identifiers (e.g., organization ID, user ID) in resource contents where applicable.
- This ensures proper scoping and access control for resources.
- Document the purpose and usage of segmentation identifiers in your API documentation.

### Search Endpoints Should Support Filtering, Sorting, and Field Selection using Query Parameters

- Implement filtering using query parameters (e.g., `?status=active`).
- Support sorting with query parameters (e.g., `?sort=created_at`).
- Allow field selection to limit response data (e.g., `?fields=id,name,email`).
- Document the available query parameters and their usage in the endpoint descriptions.

### Enforce Strict Typing for All Parameters and Request/Response Bodies

- Define explicit data types for all parameters (e.g., string, integer, boolean).
- Use JSON Schema to define request and response body structures.
- Validate data types in your API implementation to ensure data integrity.

### Avoid Using `anyOf`, `oneOf`, and `allOf` Unless Absolutely Necessary
- Prefer explicit definitions for schemas to enhance clarity and maintainability.
- Use `anyOf`, `oneOf`, and `allOf` only when there is a clear need for polymorphism or complex validation logic.
- Document the rationale for using these constructs when they are included in the specification.

### Use Meaningful Operation IDs

- Assign unique and descriptive operation IDs to each endpoint.
- Follow a consistent naming convention for operation IDs (e.g., `getUserById`, `createOrder`).
- This aids in code generation and improves readability.

### Document All Possible Responses

- Define all potential HTTP responses for each endpoint, including success and error responses.
- Use appropriate status codes and provide detailed descriptions for each response.
- Include examples for response bodies to illustrate expected data formats for most cases.

### Enumerations and Status Fields Should be Clearly Defined

- Define enumerations for fields with a limited set of values.
- Document the possible values and their meanings in the schema definitions.
- Use enumerations to improve data validation and clarity.
- Use natural language for status fields (e.g., "active", "inactive", "pending") instead of numeric codes.

### Use Standard HTTP Status Codes

Follow standard HTTP status codes for responses:
- 200 for successful GET requests
- 201 for successful POST requests that create resources
- 204 for successful DELETE requests with no content
- 400 for bad requests
- 401 for unauthorized access
- 403 for forbidden access
- 404 for not found resources
- 500 for server errors

### Leverage Components for Reusability

- Define reusable components for schemas, parameters, responses, and security schemes.
- Use `$ref` to reference these components throughout your specification.
- This reduces redundancy and ensures consistency.

### Version Your API

- Include versioning in your API paths (e.g., `/v1/resource`).
- Clearly document version changes and deprecations in your specification.
- Use semantic versioning for your API versions.

### Paginate Search, List, and Collection Endpoints

- Implement pagination for endpoints that return large collections of data.
- Use query parameters like `limit` and `offset` to control pagination.
- Document pagination behavior in the endpoint descriptions.

### Error Responses Should Be Detailed, Informative and Consistent but Not Overly Verbose

- Provide clear error messages with relevant details.
- Include error codes and descriptions in the response body.
- Maintain consistency in error response formats across all endpoints.

### Permissions and Authorization Should Be Clearly Defined

- Specify required permissions and authorization mechanisms for each endpoint.
- Use security schemes defined in the `components.securitySchemes` section.
- Document authorization requirements in the endpoint descriptions.

### Content Negotiation Must be Clearly Defined

- Specify supported content types for request and response bodies using the `content` field.
- Use appropriate media types (e.g., `application/json`, `application/xml`).
- Document content negotiation behavior in the endpoint descriptions.
- Prefer JSON as the primary data format unless there is a specific need for others.

### Deprecate Outdated Endpoints Properly

- Mark outdated endpoints as deprecated using the `deprecated: true` field.
- Provide information about alternative endpoints or versions.
- Communicate deprecation timelines and plans in your documentation, changelogs, or release notes.

### Validate Your Specification Regularly

For validation of your OpenAPI specification, use this tool [Spectral](https://stoplight.io/open-source/spectral/).
If it's not installed yet, you can install it with [scripts/install-spectral-cli.sh](scripts/install-spectral-cli.sh).
We also provide a ruleset [assets/ruleset.yml](assets/ruleset.yml) that you can use to validate your OpenAPI specification against best practices.
We provide a script [scripts/lint-openapi-spec.sh](scripts/lint-openapi-spec.sh) that uses Spectral and the provided ruleset to validate your OpenAPI specification.

### Always Ensure Security Definitions are Included

- Define security schemes (e.g., API keys, OAuth2) in the `components.securitySchemes` section.
- Apply security requirements globally or to specific operations as needed.
- Keep security definitions up to date with your authentication mechanisms.

### Use Tags to Group Related Endpoints

- Use tags to categorize and group related endpoints.
- This improves the organization and readability of your specification.
- Provide descriptions for tags to explain their purpose.

### Keep Your Specification Up to Date

- Regularly review and update your OpenAPI specification to reflect changes in your API.
- Remove deprecated endpoints and update documentation as needed.
- Ensure that your specification remains accurate and useful for developers.

### Use a testing tool to validate your API implementation against the OpenAPI specification

- Utilize tools like [Portman](https://github.com/apideck-libraries/portman) to generate and run tests based on your OpenAPI specification.
- Integrate testing into your CI/CD pipeline to catch discrepancies early.

### Utilize Advanced Features When Appropriate

- Use features like callbacks, links, and webhooks to enhance your API documentation.
- Implement these features only when they add value and clarity to your API design.
- Ensure that advanced features are well-documented and easy to understand.

By following these best practices, you can create clear, maintainable, and effective OpenAPI specifications that facilitate better API design and usage.

## How can i bundle my OpenAPI specification into a single file?

You can use the the script [scripts/bundle-openapi-spec.sh](scripts/bundle-openapi-spec.sh) to bundle your OpenAPI specification into a single file using [Spectral](https://stoplight.io/open-source/spectral/).
It provides an easy way to consolidate multiple files into one for distribution or deployment.
It also improves portability and compatibility with tools that may not support multi-file specifications.

## Example OpenAPI Specification

You can find an example [OpenAPI specs](assets/openapi.yml).
It demonstrates the best practices outlined in this skill and serves as a reference for designing your own specifications.

## Pre-Deployment Checklist

Before deploying your OpenAPI specification, ensure the following checklist items are completed:

- [ ] **All Endpoints Documented**: Verify that all API endpoints are documented with paths, methods, parameters, request bodies, and responses.
- [ ] **Descriptions and Examples**: Ensure that descriptions and examples are provided for all relevant sections.
- [ ] **Validation**: Run validation tools (e.g., Spectral) to check for syntax errors and adherence to best practices.
- [ ] **Versioning**: Confirm that the API version is correctly specified in the paths and documentation.
- [ ] **Security Definitions**: Ensure that security schemes are defined and applied appropriately.
- [ ] **Testing**: Validate the API implementation against the OpenAPI specification using testing tools.
- [ ] **Deprecation Notices**: Check that deprecated endpoints are marked and alternatives are provided.
- [ ] **Content Negotiation**: Verify that supported content types are specified.
- [ ] **Pagination**: Ensure that pagination is implemented for collection endpoints.
- [ ] **Error Responses**: Review error response formats for consistency and informativeness.
- [ ] **Tags and Organization**: Confirm that endpoints are grouped using tags for better organization.
- [ ] **Up-to-Date Specification**: Review the specification to ensure it reflects the current state of the API.

## Related Skills

- [http-api-architecture](../http-api-architecture/SKILL.md) - REST API design principles
- [openapi-testing](../openapi-testing/SKILL.md) - API testing strategies
- [fastapi-factory-utilities](../fastapi-factory-utilities/SKILL.md) - FastAPI implementation with OpenAPI auto-generation
