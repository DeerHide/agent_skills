# Testing

## Test Organization

- Use pytest for all tests
- Organize tests by functional scope in classes
- Prioritize unit tests over integration tests
- Place tests in `tests/units/` for unit tests
- Use descriptive test class names (e.g., `TestSetupLog`, `TestExceptions`)

## Test Structure

```python
class TestFeatureName:
    """Various tests for the feature_name function."""

    def test_specific_scenario(self) -> None:
        """Test that specific scenario works correctly."""
        # Arrange
        # Act
        # Assert
```

## Async Tests

Use `pytest-asyncio` for async tests. The project is configured with `asyncio_mode = "auto"`:

```python
import pytest

class TestAsyncFeature:
    """Tests for async features."""

    async def test_async_operation(self) -> None:
        """Test async operation."""
        result = await async_function()
        assert result is not None
```

## Parametrized Tests

Use `pytest.mark.parametrize` for testing multiple scenarios:

```python
import pytest

class TestValidation:
    """Tests for validation logic."""

    @pytest.mark.parametrize(
        "input_value,expected",
        [
            ("valid", True),
            ("invalid", False),
            ("", False),
        ],
    )
    def test_validation(self, input_value: str, expected: bool) -> None:
        """Test validation with different inputs."""
        result = validate(input_value)
        assert result == expected
```

## Mocking

### Generic mocking
Use `unittest.mock` for mocking dependencies:

```python
from unittest.mock import MagicMock, patch

class TestService:
    """Tests for service."""

    @patch("module.external_dependency")
    def test_with_mock(self, mock_dependency: MagicMock) -> None:
        """Test with mocked dependency."""
        mock_dependency.return_value = "expected"
        result = function_under_test()
        assert result == "expected"
        mock_dependency.assert_called_once()
```

### Mocking Aiohttp Resources

fastapi-factory-utilities provides helpers for mocking aiohttp resources:

```python
from fastapi_factory_utilities.core.plugins.aiohttp.mockers import (
    build_mocked_aiohttp_response,
    build_mocked_aiohttp_resource,
)

class TestService:
    """Tests for service."""

    def test_with_mock(self) -> None:
        """Test with mocked dependency."""
        mocked_response: ClientResponse = build_mocked_aiohttp_response(
            status=HTTPStatus.OK,
            json={"message": "Hello, world!"},
        )
        mocked_resource: AioHttpClientResource = build_mocked_aiohttp_resource(
            get=mocked_response,
        )
```

Using dependency injection, you can inject the mocked resource into the class under test.

## Test Naming

- Test class names: `TestFeatureName` or `TestClassName`
- Test method names: `test_specific_scenario_description`
- Use descriptive names that explain what is being tested
