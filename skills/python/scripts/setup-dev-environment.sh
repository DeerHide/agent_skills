#!/usr/bin/env bash
set -euo pipefail

# Setup Python development environment
# This script sets up Poetry and creates a virtual environment in .venv

echo "Setting up Python development environment..."

# Check if Poetry is installed
if ! command -v poetry &> /dev/null; then
    echo "Poetry is not installed. Installing Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -
    # Add Poetry to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "Poetry is already installed."
    poetry --version
fi

# Configure Poetry to use local .venv directory
echo "Configuring Poetry to use local .venv directory..."
poetry config virtualenvs.in-project true

# Install dependencies (this will create .venv if it doesn't exist)
echo "Installing dependencies..."
poetry install --with test

echo "Development environment setup complete!"
echo ""
echo "To activate the virtual environment:"
echo "  source .venv/bin/activate  # Linux/macOS"
echo "  .venv\\Scripts\\activate     # Windows"
echo ""
echo "Or use Poetry to run commands:"
echo "  poetry run pytest"
echo "  poetry run mypy"
echo "  poetry run ruff check src tests"
