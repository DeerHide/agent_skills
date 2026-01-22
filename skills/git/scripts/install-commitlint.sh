#!/usr/bin/env bash

# Install commitlint and its dependencies
#
# This script installs @commitlint/cli and @commitlint/config-conventional
# globally using npm.
#
# Pre-requirements:
#   - Node.js (v18 or higher)
#   - npm (v9 or higher)
#
# Usage:
#   ./install-commitlint.sh

set -euo pipefail

echo "Installing commitlint..."

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed."
    echo "Please install Node.js and npm first: https://nodejs.org/"
    exit 1
fi

# Check npm version
NPM_VERSION=$(npm --version | cut -d. -f1)
if [ "$NPM_VERSION" -lt 9 ]; then
    echo "Warning: npm version 9 or higher is recommended."
    echo "Current version: $(npm --version)"
fi

# Check if Node.js version is sufficient
NODE_VERSION=$(node --version | cut -d. -f1 | tr -d 'v')
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "Warning: Node.js version 18 or higher is recommended."
    echo "Current version: $(node --version)"
fi

# Check if commitlint is already installed
if command -v commitlint &> /dev/null; then
    CURRENT_VERSION=$(commitlint --version 2>/dev/null || echo "unknown")
    echo "commitlint is already installed (version: ${CURRENT_VERSION})."
    read -p "Do you want to reinstall/upgrade? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation skipped."
        exit 0
    fi
fi

# Install commitlint globally
echo "Installing @commitlint/cli and @commitlint/config-conventional..."
npm install -g @commitlint/cli @commitlint/config-conventional

# Verify installation
if command -v commitlint &> /dev/null; then
    echo ""
    echo "✅ commitlint installed successfully!"
    echo "   Version: $(commitlint --version)"
    echo ""
    echo "Next steps:"
    echo "  1. Copy commitlint.config.js to your project root"
    echo "  2. Run: ./setup-pre-commit.sh"
    echo "  3. Test: echo '[TIC-001] feat: test' | commitlint"
else
    echo "Error: commitlint installation failed."
    exit 1
fi
