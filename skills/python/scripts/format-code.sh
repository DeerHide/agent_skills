#!/usr/bin/env bash
set -euo pipefail

# Format and lint Python code
# Usage: ./format-code.sh [--check] [--fix] [--files FILES]
# Options:
#   --check    Only check formatting without making changes
#   --fix      Auto-fix linting issues (default)
#   --files    Specific files or directories to format (default: src tests)

# Default options
CHECK=false
FIX=true
FILES="src tests"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --check)
            CHECK=true
            FIX=false
            shift
            ;;
        --fix)
            FIX=true
            CHECK=false
            shift
            ;;
        --files)
            FILES="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--check] [--fix] [--files FILES]"
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

echo "Formatting code with Ruff..."

if [ "$CHECK" = true ]; then
    echo "Checking code formatting (no changes will be made)..."
    $RUN_CMD ruff format --check $FILES
    $RUN_CMD ruff check $FILES
else
    echo "Formatting code..."
    $RUN_CMD ruff format $FILES
    echo "Fixing linting issues..."
    $RUN_CMD ruff check --fix $FILES
    echo "Code formatting complete!"
fi
