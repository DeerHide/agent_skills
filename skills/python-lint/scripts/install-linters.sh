#!/usr/bin/env bash
set -euo pipefail

# Install Python linters
# Using uv tool to install the linters in an isolated environment

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "uv could not be found, installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Source the shell config to make uv available
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "uv is already installed."
fi

# Install ruff if not present
if ! uv tool list 2>/dev/null | grep -q "^ruff "; then
    echo "Installing ruff..."
    uv tool install ruff@latest
else
    echo "ruff is already installed."
fi

# Install pylint if not present
if ! uv tool list 2>/dev/null | grep -q "^pylint "; then
    echo "Installing pylint..."
    uv tool install pylint@latest
else
    echo "pylint is already installed."
fi

# Install mypy if not present
if ! uv tool list 2>/dev/null | grep -q "^mypy "; then
    echo "Installing mypy..."
    uv tool install mypy@latest
else
    echo "mypy is already installed."
fi

echo "All linters installed successfully!"
