---
name: Python Docstring
description: A skill for writing consistent, well-structured Python docstrings following the Google style convention.
author: Deerhide
version: 1.0.0
---

# Python Docstring Skill

# When to Use This Skill ?

- Use this skill when writing or updating Python documentation strings (docstrings).
- This skill is useful for ensuring consistent documentation across a Python codebase.
- It should be applied when documenting modules, classes, functions, methods, and attributes.
- Use it during code reviews to verify docstring quality and completeness.

# Docstring Style Convention

We follow the **Google style** docstring convention. This style is chosen for its:
- Readability and clean formatting
- Wide adoption in the Python community
- Excellent support in documentation tools (Sphinx, MkDocs)
- Native support in linting tools (Ruff, Pylint)

# Module Docstrings

Every Python module should start with a docstring describing its purpose.

```python
"""Module for handling user authentication and session management.

This module provides utilities for user authentication, token generation,
and session lifecycle management. It integrates with OAuth2 providers
and supports JWT-based authentication.

Example:
    Basic usage of the authentication service::

        from auth import AuthService
        
        service = AuthService(secret_key="my-secret")
        token = service.create_token(user_id=123)

Attributes:
    DEFAULT_TOKEN_EXPIRY (int): Default token expiration time in seconds.
    SUPPORTED_ALGORITHMS (list): List of supported JWT algorithms.

Todo:
    * Add support for refresh tokens
    * Implement rate limiting for failed attempts
"""

DEFAULT_TOKEN_EXPIRY = 3600
SUPPORTED_ALGORITHMS = ["HS256", "RS256"]
```

# Class Docstrings

Class docstrings should describe the class purpose and list its attributes.

```python
class UserRepository:
    """Repository for managing user data persistence.

    This class provides CRUD operations for user entities and handles
    database connections and transactions.

    Attributes:
        connection: Database connection instance.
        table_name: Name of the users table.
        cache_enabled: Whether caching is enabled for queries.

    Example:
        Creating and using a repository::

            repo = UserRepository(connection=db_conn)
            user = repo.find_by_id(user_id=42)
            repo.save(user)
    """

    def __init__(self, connection: DatabaseConnection) -> None:
        """Initialize the UserRepository.

        Args:
            connection: Active database connection to use for operations.
        """
        self.connection = connection
        self.table_name = "users"
        self.cache_enabled = True
```

# Function and Method Docstrings

Functions and methods should document their purpose, arguments, return values, and exceptions.

## Basic Function

```python
def calculate_discount(price: float, percentage: float) -> float:
    """Calculate the discounted price.

    Args:
        price: Original price of the item.
        percentage: Discount percentage (0-100).

    Returns:
        The discounted price after applying the percentage reduction.

    Raises:
        ValueError: If percentage is not between 0 and 100.
        TypeError: If price or percentage are not numeric.

    Example:
        >>> calculate_discount(100.0, 20)
        80.0
    """
    if not 0 <= percentage <= 100:
        raise ValueError("Percentage must be between 0 and 100")
    return price * (1 - percentage / 100)
```

## Method with Complex Arguments

```python
def create_user(
    self,
    username: str,
    email: str,
    *,
    role: str = "user",
    metadata: dict[str, Any] | None = None,
) -> User:
    """Create a new user in the system.

    Creates a user entity with the provided information and persists
    it to the database. Sends a welcome email upon successful creation.

    Args:
        username: Unique username for the new user. Must be alphanumeric
            and between 3-50 characters.
        email: Valid email address for the user.
        role: User role assignment. Defaults to "user".
            Valid options are "user", "admin", "moderator".
        metadata: Optional dictionary of additional user metadata.
            Keys must be strings, values can be any JSON-serializable type.

    Returns:
        The newly created User instance with assigned ID.

    Raises:
        DuplicateUserError: If username or email already exists.
        ValidationError: If input validation fails.
        DatabaseError: If database operation fails.

    Note:
        This method triggers a background task for sending the welcome email.
        The email sending is non-blocking and failures are logged but not raised.

    Example:
        Creating a basic user::

            user = service.create_user(
                username="johndoe",
                email="john@example.com"
            )

        Creating an admin user with metadata::

            admin = service.create_user(
                username="admin",
                email="admin@example.com",
                role="admin",
                metadata={"department": "IT"}
            )
    """
```

## Async Functions

```python
async def fetch_user_data(user_id: int, timeout: float = 30.0) -> UserData:
    """Fetch user data from the remote service.

    Asynchronously retrieves user information from the external API
    with automatic retry logic for transient failures.

    Args:
        user_id: Unique identifier of the user to fetch.
        timeout: Maximum time in seconds to wait for response.
            Defaults to 30.0 seconds.

    Returns:
        UserData object containing the user's information.

    Raises:
        UserNotFoundError: If no user exists with the given ID.
        TimeoutError: If the request exceeds the timeout duration.
        ServiceUnavailableError: If the remote service is unreachable.
    """
```

# Generator and Iterator Docstrings

```python
def paginate_results(
    query: Query,
    page_size: int = 100,
) -> Iterator[list[Record]]:
    """Paginate through query results.

    Yields pages of records from the query, handling cursor-based
    pagination automatically.

    Args:
        query: Database query to paginate.
        page_size: Number of records per page. Defaults to 100.

    Yields:
        Lists of Record objects, each list containing up to page_size items.

    Example:
        >>> for page in paginate_results(query, page_size=50):
        ...     process_records(page)
    """
```

# Property Docstrings

```python
@property
def full_name(self) -> str:
    """Return the full name of the user.

    Combines first_name and last_name with proper spacing.
    Returns an empty string if both names are unset.
    """
    return f"{self.first_name} {self.last_name}".strip()


@property
def is_active(self) -> bool:
    """Return whether the user account is currently active.

    An account is considered active if it has been verified
    and has not been suspended or deleted.
    """
    return self.verified and not self.suspended
```

# Context Manager Docstrings

```python
@contextmanager
def database_transaction(
    connection: Connection,
    isolation_level: str = "READ_COMMITTED",
) -> Iterator[Transaction]:
    """Context manager for database transactions.

    Provides automatic commit on success and rollback on failure.
    Nested transactions are supported via savepoints.

    Args:
        connection: Active database connection.
        isolation_level: Transaction isolation level.
            Options: "READ_UNCOMMITTED", "READ_COMMITTED",
            "REPEATABLE_READ", "SERIALIZABLE".
            Defaults to "READ_COMMITTED".

    Yields:
        Transaction object for executing queries.

    Raises:
        TransactionError: If transaction cannot be started.

    Example:
        >>> with database_transaction(conn) as tx:
        ...     tx.execute("INSERT INTO users VALUES (?)", [user])
    """
```

# Dataclass and Pydantic Model Docstrings

```python
@dataclass
class OrderItem:
    """Represents a single item in an order.

    Attributes:
        product_id: Unique identifier of the product.
        quantity: Number of units ordered. Must be positive.
        unit_price: Price per unit in the order currency.
        discount: Applied discount as a decimal (0.0-1.0).
    """

    product_id: str
    quantity: int
    unit_price: Decimal
    discount: Decimal = Decimal("0.0")


class UserSettings(BaseModel):
    """User preference settings.

    Stores user-configurable settings for the application,
    including notification preferences and display options.

    Attributes:
        theme: UI theme preference. Either "light" or "dark".
        notifications_enabled: Whether to send notifications.
        language: Preferred language code (ISO 639-1).
        timezone: User's timezone (IANA format).
    """

    theme: Literal["light", "dark"] = "light"
    notifications_enabled: bool = True
    language: str = "en"
    timezone: str = "UTC"
```

# Enum Docstrings

```python
class OrderStatus(Enum):
    """Status values for order lifecycle.

    Attributes:
        PENDING: Order created but not yet processed.
        CONFIRMED: Order confirmed and awaiting fulfillment.
        SHIPPED: Order has been shipped to customer.
        DELIVERED: Order successfully delivered.
        CANCELLED: Order was cancelled before fulfillment.
    """

    PENDING = "pending"
    CONFIRMED = "confirmed"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
```

# Exception Docstrings

```python
class ValidationError(Exception):
    """Raised when input validation fails.

    This exception is raised when user input or API request data
    fails validation rules.

    Attributes:
        field: Name of the field that failed validation.
        message: Human-readable error message.
        code: Machine-readable error code for client handling.

    Example:
        >>> raise ValidationError(
        ...     field="email",
        ...     message="Invalid email format",
        ...     code="INVALID_EMAIL"
        ... )
    """

    def __init__(self, field: str, message: str, code: str) -> None:
        """Initialize ValidationError.

        Args:
            field: Name of the field that failed validation.
            message: Human-readable description of the error.
            code: Machine-readable error code.
        """
        self.field = field
        self.message = message
        self.code = code
        super().__init__(f"{field}: {message}")
```

# Docstring Sections Reference

The following sections are supported in Google style docstrings:

| Section | Purpose |
|---------|---------|
| `Args:` | Document function/method parameters |
| `Returns:` | Describe the return value |
| `Yields:` | Describe yielded values (generators) |
| `Raises:` | List exceptions that may be raised |
| `Attributes:` | Document class/module attributes |
| `Example:` / `Examples:` | Provide usage examples |
| `Note:` | Additional information or caveats |
| `Warning:` | Important warnings for users |
| `Todo:` | Future improvements or tasks |
| `See Also:` | References to related functions/classes |

# Best Practices

1. **Be Concise**: First line should be a brief summary under 79 characters.
2. **Use Imperative Mood**: Write "Calculate the sum" not "Calculates the sum".
3. **Document All Public APIs**: Every public function, class, and method needs a docstring.
4. **Rely on Type Hints**: Avoid duplicating type information in docstrings when type hints are present. Modern documentation tools extract types from annotations.
5. **Provide Examples**: Complex functions benefit from usage examples.
6. **Document Exceptions**: List all exceptions that can be raised.
7. **Keep Updated**: Update docstrings when code changes.
8. **Use Proper Indentation**: Continuation lines should be indented consistently.

# Linting Configuration

For docstring linting configuration with Ruff and other tools, refer to the [Python Lint Skill](../python-lint/SKILL.md).

The Python Lint skill configures Ruff with `convention = "google"` in the `[tool.ruff.lint.pydocstyle]` section, which enforces the Google style docstring convention documented in this skill.

# Common Ruff Docstring Rules

| Rule | Description |
|------|-------------|
| D100 | Missing docstring in public module |
| D101 | Missing docstring in public class |
| D102 | Missing docstring in public method |
| D103 | Missing docstring in public function |
| D107 | Missing docstring in `__init__` |
| D200 | One-line docstring should fit on one line |
| D205 | 1 blank line required between summary and description |
| D400 | First line should end with a period |
| D401 | First line should be in imperative mood |
| D417 | Missing argument descriptions in docstring |
