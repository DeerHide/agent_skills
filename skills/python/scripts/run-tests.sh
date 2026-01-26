#!/usr/bin/env bash
set -euo pipefail

# Run Python tests with various options
# Usage: ./run-tests.sh [options]
# Options:
#   --coverage    Run tests with coverage report
#   --parallel    Run tests in parallel
#   --verbose     Run tests with verbose output
#   --pattern     Run tests matching a pattern (requires pattern argument)
#   --file        Run tests in a specific file (requires file path)
#   --class       Run tests in a specific class (requires class path)
#   --method      Run tests for a specific method (requires method path)
#   --stop-first  Stop on first failure
#   --marker      Run tests with specific marker (requires marker argument)

# Default options
COVERAGE=false
PARALLEL=false
VERBOSE=false
PATTERN=""
FILE=""
CLASS=""
METHOD=""
STOP_FIRST=false
MARKER=""
COVERAGE_FORMAT="term"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage)
            COVERAGE=true
            shift
            ;;
        --coverage-html)
            COVERAGE=true
            COVERAGE_FORMAT="html"
            shift
            ;;
        --coverage-lcov)
            COVERAGE=true
            COVERAGE_FORMAT="lcov"
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --pattern)
            PATTERN="$2"
            shift 2
            ;;
        --file)
            FILE="$2"
            shift 2
            ;;
        --class)
            CLASS="$2"
            shift 2
            ;;
        --method)
            METHOD="$2"
            shift 2
            ;;
        --stop-first|-x)
            STOP_FIRST=true
            shift
            ;;
        --marker|-m)
            MARKER="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--coverage] [--parallel] [--verbose] [--pattern PATTERN] [--file FILE] [--class CLASS] [--method METHOD] [--stop-first] [--marker MARKER]"
            exit 1
            ;;
    esac
done

# Build pytest command
PYTEST_CMD="pytest"

# Add coverage options
if [ "$COVERAGE" = true ]; then
    PYTEST_CMD="$PYTEST_CMD --cov=src"
    case $COVERAGE_FORMAT in
        html)
            PYTEST_CMD="$PYTEST_CMD --cov-report=html --cov-report=term"
            echo "Coverage report will be generated in htmlcov/ directory"
            ;;
        lcov)
            mkdir -p build
            PYTEST_CMD="$PYTEST_CMD --cov-report=lcov:build/coverage.lcov --cov-report=term"
            echo "Coverage report will be generated in build/coverage.lcov"
            ;;
        *)
            PYTEST_CMD="$PYTEST_CMD --cov-report=term"
            ;;
    esac
fi

# Add parallel option
if [ "$PARALLEL" = true ]; then
    PYTEST_CMD="$PYTEST_CMD -n auto"
fi

# Add verbose option
if [ "$VERBOSE" = true ]; then
    PYTEST_CMD="$PYTEST_CMD -vv"
fi

# Add stop first option
if [ "$STOP_FIRST" = true ]; then
    PYTEST_CMD="$PYTEST_CMD -x"
fi

# Add marker option
if [ -n "$MARKER" ]; then
    PYTEST_CMD="$PYTEST_CMD -m \"$MARKER\""
fi

# Add pattern option
if [ -n "$PATTERN" ]; then
    PYTEST_CMD="$PYTEST_CMD -k \"$PATTERN\""
fi

# Add file/class/method options
if [ -n "$METHOD" ]; then
    PYTEST_CMD="$PYTEST_CMD $METHOD"
elif [ -n "$CLASS" ]; then
    PYTEST_CMD="$PYTEST_CMD $CLASS"
elif [ -n "$FILE" ]; then
    PYTEST_CMD="$PYTEST_CMD $FILE"
fi

# Use Poetry if available, otherwise use direct pytest
if command -v poetry &> /dev/null; then
    echo "Running: poetry run $PYTEST_CMD"
    poetry run $PYTEST_CMD
else
    echo "Running: $PYTEST_CMD"
    $PYTEST_CMD
fi
