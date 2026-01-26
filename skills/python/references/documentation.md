# Documentation

## Docstring Format

Always add docstrings to methods, functions, and classes using Google Python docstring format.

## Module-Level Docstrings

Every module should start with a module-level docstring:

```python
"""Provides functionality for X."""
```

## Class Docstrings

```python
class MyClass:
    """Brief description of the class.

    Longer description if needed, explaining the purpose and usage
    of the class.
    """
```

## Function/Method Docstrings

```python
def my_function(param1: str, param2: int) -> bool:
    """Brief description of the function.

    Longer description if needed, explaining what the function does
    and any important details.

    Args:
        param1: Description of param1.
        param2: Description of param2.

    Returns:
        Description of the return value.

    Raises:
        ValueError: Description of when this exception is raised.
        CustomError: Description of when this exception is raised.
    """
```

## Complex Functions

For complex functions, include examples in the docstring:

```python
def complex_function(data: dict[str, Any]) -> ProcessedData:
    """Process complex data structure.

    This function performs multiple transformations on the input data
    and returns a processed result.

    Args:
        data: Dictionary containing raw data to process.

    Returns:
        ProcessedData object with transformed data.

    Example:
        >>> data = {"key": "value"}
        >>> result = complex_function(data)
        >>> print(result.processed_key)
        'processed_value'

    Raises:
        ValidationError: If the input data is invalid.
    """
```
