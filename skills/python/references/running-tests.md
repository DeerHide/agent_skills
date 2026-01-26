# How to Test

## Test Runner Script

Use the test runner script for convenient test execution with various options:

**Run all tests:**
```bash
./scripts/run-tests.sh
```

**Run tests with coverage:**
```bash
./scripts/run-tests.sh --coverage
./scripts/run-tests.sh --coverage-html  # Generate HTML report
./scripts/run-tests.sh --coverage-lcov  # Generate LCOV report
```

**Run tests in parallel:**
```bash
./scripts/run-tests.sh --parallel
```

**Run tests with verbose output:**
```bash
./scripts/run-tests.sh --verbose
```

**Run tests matching a pattern:**
```bash
./scripts/run-tests.sh --pattern "test_exception"
```

**Run tests in a specific file:**
```bash
./scripts/run-tests.sh --file tests/units/test_exceptions.py
```

**Run tests for a specific class:**
```bash
./scripts/run-tests.sh --class tests/units/test_exceptions.py::TestExceptions
```

**Run tests with markers:**
```bash
./scripts/run-tests.sh --marker "not slow"
```

**Stop on first failure:**
```bash
./scripts/run-tests.sh --stop-first
```

## Running Tests

Run all tests using pytest:

```bash
pytest
```

Or using Poetry:

```bash
poetry run pytest
```

## Running Specific Tests

**Run tests in a specific directory:**
```bash
pytest tests/units
```

**Run tests in a specific file:**
```bash
pytest tests/units/test_exceptions.py
```

**Run a specific test class:**
```bash
pytest tests/units/test_exceptions.py::TestExceptions
```

**Run a specific test method:**
```bash
pytest tests/units/test_exceptions.py::TestExceptions::test_specific_scenario
```

## Running Tests with Coverage

Generate coverage reports:

```bash
pytest --cov=src --cov-report=html --cov-report=term
```

This will:
- Generate coverage data for the `src` directory
- Create an HTML report in `htmlcov/` directory
- Display coverage summary in the terminal

**Generate LCOV format (for CI/CD):**
```bash
pytest --cov=src --cov-report=lcov:build/coverage.lcov
```

**Generate JUnit XML (for CI/CD):**
```bash
pytest --junitxml=build/junit.xml
```

## Running Tests in Parallel

The project is configured to run tests in parallel automatically using `pytest-xdist`:

```bash
pytest -n auto
```

The `-n auto` flag automatically detects the number of CPU cores and runs tests in parallel.

## Running Tests with Verbose Output

Get more detailed output:

```bash
pytest -v
```

Or even more verbose:

```bash
pytest -vv
```

## Running Tests with Output Capture Disabled

See print statements and logs during test execution:

```bash
pytest -s
```

## Running Tests Matching a Pattern

Run tests matching a specific pattern:

```bash
pytest -k "test_exception"
```

This will run all tests with "test_exception" in their name.

## Running Tests and Stopping on First Failure

Stop test execution on the first failure:

```bash
pytest -x
```

Or stop after N failures:

```bash
pytest --maxfail=3
```

## Running Tests with Markers

Run tests with specific markers:

```bash
pytest -m "not slow"
```
