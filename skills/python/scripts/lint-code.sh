#!/usr/bin/env bash
set -euo pipefail

# Lint Python code with multiple tools
# Usage: ./lint-code.sh [--files FILES] [--tool TOOL]
# Options:
#   --files    Specific files or directories to lint (default: src tests)
#   --tool     Specific tool to use: ruff, pylint, or all (default: all)

# Default options
FILES="src tests"
TOOL="all"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --files)
            FILES="$2"
            shift 2
            ;;
        --tool)
            TOOL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--files FILES] [--tool TOOL]"
            exit 1
            ;;
    esac
done

# Use Poetry if available, otherwise use direct commands
if command -v poetry &> /dev/null; then
    RUN_CMD="poetry run"
else
    RUN_CMD=""
fi

# Run Ruff
if [ "$TOOL" = "all" ] || [ "$TOOL" = "ruff" ]; then
    echo "Running Ruff..."
    $RUN_CMD ruff check $FILES
    if [ $? -eq 0 ]; then
        echo "✓ Ruff checks passed"
    else
        echo "✗ Ruff checks failed"
        exit 1
    fi
fi

# Run Pylint
if [ "$TOOL" = "all" ] || [ "$TOOL" = "pylint" ]; then
    echo "Running Pylint..."
    $RUN_CMD pylint $FILES
    if [ $? -eq 0 ]; then
        echo "✓ Pylint checks passed"
    else
        echo "✗ Pylint checks failed"
        exit 1
    fi
fi

echo "All linting checks complete!"
