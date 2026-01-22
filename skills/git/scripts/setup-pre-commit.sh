#!/usr/bin/env bash

# Setup pre-commit hooks for commit message validation
#
# This script installs pre-commit framework and configures git hooks
# for commit message linting with commitlint.
#
# Pre-requirements:
#   - Python 3.8 or higher
#   - pip
#   - Git repository initialized
#   - commitlint installed (run install-commitlint.sh first)
#
# Arguments:
#   $1 - (Optional) Project directory (default: current directory)
#
# Usage:
#   ./setup-pre-commit.sh
#   ./setup-pre-commit.sh /path/to/project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="${SCRIPT_DIR}/../assets"
PROJECT_DIR="${1:-.}"

echo "Setting up pre-commit hooks..."

# Change to project directory
cd "$PROJECT_DIR"

# Verify we're in a git repository
if [ ! -d ".git" ]; then
    echo "Error: Not a git repository."
    echo "Please run this script from a git repository root."
    exit 1
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed."
    echo "Please install Python 3.8 or higher."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
    echo "Error: pip is not installed."
    echo "Please install pip for Python 3."
    exit 1
fi

# Determine pip command
PIP_CMD="pip3"
if ! command -v pip3 &> /dev/null; then
    PIP_CMD="pip"
fi

# Check if commitlint is installed
if ! command -v commitlint &> /dev/null; then
    echo "Warning: commitlint is not installed globally."
    echo "Checking for local installation..."

    if [ ! -f "node_modules/.bin/commitlint" ]; then
        echo "Error: commitlint not found."
        echo "Please run install-commitlint.sh first or install locally:"
        echo "  npm install --save-dev @commitlint/cli @commitlint/config-conventional"
        exit 1
    fi
fi

# Install pre-commit if not already installed
if ! command -v pre-commit &> /dev/null; then
    echo "Installing pre-commit..."
    $PIP_CMD install pre-commit
else
    echo "pre-commit is already installed (version: $(pre-commit --version))"
fi

# Copy configuration files if they don't exist
if [ ! -f ".pre-commit-config.yaml" ]; then
    if [ -f "${ASSETS_DIR}/.pre-commit-config.yaml" ]; then
        echo "Copying .pre-commit-config.yaml..."
        cp "${ASSETS_DIR}/.pre-commit-config.yaml" .pre-commit-config.yaml
    else
        echo "Warning: .pre-commit-config.yaml template not found in assets."
        echo "Please create .pre-commit-config.yaml manually."
    fi
else
    echo ".pre-commit-config.yaml already exists."
fi

if [ ! -f "commitlint.config.js" ]; then
    if [ -f "${ASSETS_DIR}/commitlint.config.js" ]; then
        echo "Copying commitlint.config.js..."
        cp "${ASSETS_DIR}/commitlint.config.js" commitlint.config.js
    else
        echo "Warning: commitlint.config.js template not found in assets."
        echo "Please create commitlint.config.js manually."
    fi
else
    echo "commitlint.config.js already exists."
fi

# Install pre-commit hooks
echo "Installing git hooks..."
pre-commit install --hook-type commit-msg
pre-commit install --hook-type pre-commit

# Verify installation
echo ""
echo "✅ Pre-commit hooks installed successfully!"
echo ""
echo "Installed hooks:"
echo "  - commit-msg: Validates commit messages with commitlint"
echo "  - pre-commit: Runs code quality checks"
echo ""
echo "Configuration files:"
echo "  - .pre-commit-config.yaml: Pre-commit hook configuration"
echo "  - commitlint.config.js: Commitlint rules configuration"
echo ""
echo "Test the setup:"
echo "  echo '[TIC-001] feat: test commit' | commitlint"
echo ""
echo "Commands:"
echo "  pre-commit run --all-files    # Run all hooks manually"
echo "  pre-commit autoupdate         # Update hook versions"
echo "  git commit --no-verify        # Bypass hooks (emergency only)"
