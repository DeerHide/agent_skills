#!/usr/bin/env bash
set -euo pipefail

# Run type checking on Python code
# Usage: ./type-check.sh [--files FILES]
# Options:
#   --files    Specific files or directories to check (default: src)

# Default options
FILES="src"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --files)
            FILES="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--files FILES]"
            exit 1
            ;;
    esac
done

# Use Poetry if available, otherwise use direct mypy
if command -v poetry &> /dev/null; then
    echo "Running type checking with mypy..."
    poetry run mypy $FILES
else
    if ! command -v mypy &> /dev/null; then
        echo "Error: mypy is not installed and Poetry is not available."
        echo "Please install mypy or set up Poetry."
        exit 1
    fi
    echo "Running type checking with mypy..."
    mypy $FILES
fi
