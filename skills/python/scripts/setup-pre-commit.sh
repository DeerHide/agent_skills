#!/usr/bin/env bash
set -euo pipefail

# Setup pre-commit hooks
# Usage: ./setup-pre-commit.sh [--hook-type TYPE]
# Options:
#   --hook-type    Hook type to install: pre-commit (default) or pre-push

# Default options
HOOK_TYPE="pre-commit"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --hook-type)
            HOOK_TYPE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--hook-type TYPE]"
            exit 1
            ;;
    esac
done

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "pre-commit is not installed. Installing pre-commit..."
    if command -v poetry &> /dev/null; then
        poetry add --group dev pre-commit
    else
        pip install pre-commit
    fi
fi

# Install pre-commit hooks
echo "Installing pre-commit hooks for $HOOK_TYPE stage..."
pre-commit install --hook-type $HOOK_TYPE

# Install hooks in the repository
echo "Installing hook environments..."
pre-commit install-hooks

echo "Pre-commit setup complete!"
echo ""
echo "To run pre-commit hooks manually:"
echo "  pre-commit run --all-files"
echo ""
echo "To run a specific hook:"
echo "  pre-commit run ruff-check --all-files"
echo "  pre-commit run mypy --all-files"
echo "  pre-commit run pytest --all-files"
