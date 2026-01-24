# Use Cases Pattern

## Overview

Use cases represent application-specific business rules and orchestrate the flow of data between the domain layer and the infrastructure layer. Each use case encapsulates a single user intention or system operation.

This pattern follows Clean Architecture principles where use cases sit in the Application Layer, depending only on the Domain Layer and abstractions (interfaces).

## Key Principles

| Principle | Description |
|-----------|-------------|
| **Single Responsibility** | One class per use case - each use case does one thing |
| **Dependency Inversion** | Depends on abstractions (interfaces), not concrete implementations |
| **Input/Output Separation** | Clear distinction between inputs (setters) and outputs (read-only properties) |
| **Testability** | Easy to test in isolation by mocking dependencies |

## Use Case Structure

A use case class follows this structure:

1. **Constructor** - Receives dependencies (repositories, services) via injection
2. **Input Setters** - Methods to set input data before execution
3. **Execute Method** - Performs the business operation
4. **Result Properties** - Read-only access to outputs after execution

### Complete Example

```python
# usecases/borrowers/borrow_book.py
from abc import ABC, abstractmethod

# --- Use Case Exceptions ---
class UseCaseError(Exception):
    """Base exception for use case errors."""
    pass

class BookNotFoundError(UseCaseError):
    """Raised when a book is not found in the repository."""
    
    def __init__(self, book_id: str):
        self.book_id = book_id
        super().__init__(f"Book not found: {book_id}")

class BookNotAvailableError(UseCaseError):
    """Raised when a book is not available for borrowing."""
    
    def __init__(self, book_id: str):
        self.book_id = book_id
        super().__init__(f"Book not available: {book_id}")

# Repository interface (defined in application layer)
class BookRepositoryInterface(ABC):
    @abstractmethod
    def find_by_id(self, book_id: str) -> Book | None:
        pass
    
    @abstractmethod
    def save(self, book: Book) -> Book:
        """Save the book and return the updated entity with new revision_id."""
        pass

class BorrowBookUseCase:
    """Use case for borrowing a book from the library."""
    
    def __init__(self, repository: BookRepositoryInterface):
        self._repository = repository
        # Input attributes (set before execution)
        self._book_id: str | None = None
        self._borrower_id: str | None = None
        # Result attributes (read after execution)
        self._result_book: Book | None = None
    
    # --- Pure Functional Methods ---
    def retrieve_book(self, book_id: str) -> Book:
        """
        Retrieve a book by ID.
        
        Args:
            book_id: The ID of the book to retrieve.
        
        Returns:
            The book entity.
        
        Raises:
            BookNotFoundError: If the book does not exist.
        """
        book = self._repository.find_by_id(book_id)
        if book is None:
            raise BookNotFoundError(book_id)
        return book
    
    def borrow_book(self, book: Book, borrower_id: str) -> Book:
        """
        Apply borrow logic to a book entity.
        
        Uses model_copy for immutable updates - does not modify the original entity.
        
        Args:
            book: The book entity to borrow.
            borrower_id: The ID of the user borrowing the book.
        
        Returns:
            A new book entity with updated state.
        
        Raises:
            BookNotAvailableError: If the book is not available for borrowing.
        """
        if not book.is_available_for_borrowing():
            raise BookNotAvailableError(book.id)
        
        # Immutable update using Pydantic's model_copy
        borrowed_book = book.model_copy(update={
            "available": False,
            "borrower_id": borrower_id,
        })

        borrowed_book_saved = self._repository.save(borrowed_book)

        return borrowed_book_saved
    
    def borrow(self, book_id: str, borrower_id: str) -> Book:
        """
        Pure functional method for borrowing a book.
        
        Orchestrates retrieval, business logic, and persistence.
        
        Args:
            book_id: The ID of the book to borrow.
            borrower_id: The ID of the user borrowing the book.
        
        Returns:
            The borrowed book with updated revision_id.
        
        Raises:
            BookNotFoundError: If the book does not exist.
            BookNotAvailableError: If the book is not available for borrowing.
        """
        # Retrieve
        book = self.retrieve_book(book_id)
        
        # Apply business logic (immutable) and persist
        saved_book = self.borrow_book(book, borrower_id)
        
        return saved_book
    
    # --- Input Setters ---
    def set_book_id(self, book_id: str) -> "BorrowBookUseCase":
        """Set the ID of the book to borrow."""
        self._book_id = book_id
        return self
    
    def set_borrower_id(self, borrower_id: str) -> "BorrowBookUseCase":
        """Set the ID of the user borrowing the book."""
        self._borrower_id = borrower_id
        return self
    
    # --- Read-Only Result Properties ---
    @property
    def book(self) -> Book:
        """Get the borrowed book after execution."""
        assert self._result_book is not None, "Use case has not been executed yet"
        return self._result_book
    
    # --- Execution ---
    def execute(self) -> None:
        """Execute the borrow book operation using setter-provided inputs."""
        assert self._book_id is not None, "book_id must be set before execution"
        assert self._borrower_id is not None, "borrower_id must be set before execution"
        
        try:
            self._result_book = self.borrow(self._book_id, self._borrower_id)
        except UseCaseError:
            # Re-raise use case exceptions as-is
            raise
        except Exception as e:
            # Wrap unexpected exceptions
            raise UseCaseError(f"Unexpected error during borrow operation: {e}") from e
```

### Usage

```python
# Create use case with dependencies
use_case = BorrowBookUseCase(repository)

# Option 1: Pure functional method (recommended for simple cases)
borrowed_book = use_case.borrow(book_id="123", borrower_id="user-456")

# Option 2: Setter/execute pattern (for complex inputs or when storing results)
use_case.set_book_id("123").set_borrower_id("user-456")
use_case.execute()
borrowed_book = use_case.book
```

---

## Two Approaches: Functional vs Setter/Execute

The use case provides two ways to invoke the operation:

### Functional Method (`borrow`)

```python
result = use_case.borrow(book_id="123", borrower_id="user-456")
```

| Characteristic | Description |
|----------------|-------------|
| **Pure function** | Takes inputs as parameters, returns result directly |
| **No state mutation** | Does not modify instance attributes (except via dependencies) |
| **Simple API** | Single method call for the entire operation |
| **Best for** | Simple use cases with few inputs |

### Setter/Execute Pattern

```python
use_case.set_book_id("123").set_borrower_id("user-456")
use_case.execute()
result = use_case.book
```

| Characteristic | Description |
|----------------|-------------|
| **Stateful** | Stores inputs and results in instance attributes |
| **Fluent interface** | Method chaining for readable setup |
| **Best for** | Complex use cases with many optional inputs or multiple results |

### Combining Both

The `execute()` method delegates to the functional method, keeping business logic in one place:

```python
def execute(self) -> None:
    assert self._book_id is not None, "book_id must be set before execution"
    assert self._borrower_id is not None, "borrower_id must be set before execution"
    
    self._result_book = self.borrow(self._book_id, self._borrower_id)
```

This ensures:
- Business logic is defined once in the functional method
- Both APIs are always consistent
- Easy to test the core logic via the functional method

---

## Why Use Setter/Property Pattern?

This pattern offers several advantages over passing all parameters to `execute()`:

| Benefit | Description |
|---------|-------------|
| **Fluent Interface** | Method chaining for readable setup |
| **Optional Parameters** | Easy to handle optional inputs without long parameter lists |
| **Multiple Results** | Can expose multiple output properties |
| **Clear State** | Explicit separation of input phase, execution phase, and output phase |
| **Reusability** | Can reset inputs and re-execute with different values (extremely not recommended) |

---

## Why Use `assert` for Validation?

Assert statements are used to validate that inputs are set before execution and results are available before access. This is intentional:

- **Developer hints** - Assertions catch programming errors during development and testing
- **Production optimization** - Assertions are removed when Python runs with `-O` (optimized mode), eliminating runtime overhead
- **Clear intent** - Distinguishes programming errors (assert) from business rule violations (exceptions)

> ⚠️ **Important:** Never use `assert` for validating user input or business rules. Use proper exceptions for runtime errors that can occur in production.

### When to Use Assert vs Exceptions

| Scenario | Use |
|----------|-----|
| Input setter not called before execute | `assert` |
| Result property accessed before execute | `assert` |
| Book not found in database | `raise BookNotFoundError` |
| Book not available for borrowing | `raise BookNotAvailableError` |
| Invalid user input | `raise ValueError` or custom exception |

---

## Organizing Use Cases

Use cases should be organized by actor or role when the application has multiple user types:

```
usecases/
|-- __init__.py
|-- generics/              # Use cases for all users
|   |-- __init__.py
|   |-- search_books.py
|   |-- view_book_details.py
|-- borrowers/             # Use cases for library members
|   |-- __init__.py
|   |-- borrow_book.py
|   |-- return_book.py
|   |-- view_borrowed_books.py
|-- managers/              # Use cases for library staff
|   |-- __init__.py
|   |-- add_book.py
|   |-- remove_book.py
|   |-- manage_inventory.py
```

---

## Naming Conventions

- **Class Name**: Verb + Noun + `UseCase` suffix (e.g., `BorrowBookUseCase`, `CreateUserUseCase`)
- **File Name**: snake_case matching the action (e.g., `borrow_book.py`, `create_user.py`)
- **Setter Methods**: `set_` prefix (e.g., `set_book_id`, `set_user_data`)
- **Result Properties**: Noun describing the output (e.g., `book`, `user`, `result`)

---

## Testing Use Cases

Use cases are easy to test because dependencies are injected:

```python
# tests/units/usecases/borrowers/test_borrow_book.py
import pytest
from unittest.mock import Mock

class TestBorrowBookUseCase:
    def test_borrow_available_book(self):
        # Arrange
        mock_repository = Mock(spec=BookRepositoryInterface)
        mock_repository.find_by_id.return_value = Book(
            id="123",
            title="Clean Code",
            author="Robert Martin",
            isbn="978-0132350884",
            available=True
        )
        
        use_case = BorrowBookUseCase(mock_repository)
        use_case.set_book_id("123").set_borrower_id("user-456")
        
        # Act
        use_case.execute()
        
        # Assert
        assert use_case.book.available is False
        mock_repository.save.assert_called_once()
    
    def test_borrow_unavailable_book_raises_error(self):
        # Arrange
        mock_repository = Mock(spec=BookRepositoryInterface)
        mock_repository.find_by_id.return_value = Book(
            id="123",
            title="Clean Code",
            author="Robert Martin",
            isbn="978-0132350884",
            available=False
        )
        
        use_case = BorrowBookUseCase(mock_repository)
        use_case.set_book_id("123").set_borrower_id("user-456")
        
        # Act & Assert
        with pytest.raises(BookNotAvailableError):
            use_case.execute()
```

---

## Integration with FastAPI

Use cases are injected into FastAPI routes using the `Depends` system:

```python
# api/books/routes.py
from fastapi import APIRouter, Depends, HTTPException, status

router = APIRouter(prefix="/books", tags=["books"])

def get_borrow_book_use_case(
    repository: BookRepositoryInterface = Depends(get_book_repository)
) -> BorrowBookUseCase:
    return BorrowBookUseCase(repository)

@router.post("/{book_id}/borrow", status_code=status.HTTP_200_OK)
async def borrow_book(
    book_id: str,
    borrower_id: str,
    use_case: BorrowBookUseCase = Depends(get_borrow_book_use_case)
):
    try:
        use_case.set_book_id(book_id).set_borrower_id(borrower_id)
        use_case.execute()
        return {"message": "Book borrowed successfully", "book_id": use_case.book.id}
    except BookNotFoundError:
        raise HTTPException(status_code=404, detail="Book not found")
    except BookNotAvailableError:
        raise HTTPException(status_code=409, detail="Book not available")
```

---

## External References

| Document | Description |
|----------|-------------|
| [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) | Original Clean Architecture article by Robert C. Martin |
| [Dependency Injection](dependency-injection.md) | Dependency injection patterns in Python and FastAPI |
| [Project Structure](project-structure.md) | Full project structure following Clean Architecture |
