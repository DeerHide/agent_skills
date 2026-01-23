#!/bin/bash
# Install Portman CLI and Newman for OpenAPI testing
# Usage: ./install-portman.sh

set -e

echo "Installing Portman CLI and Newman..."

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed. Please install Node.js and npm first."
    exit 1
fi

# Check if package.json exists, if not create one
if [ ! -f "package.json" ]; then
    echo "No package.json found. Initializing npm project..."
    npm init -y
fi

# Install Portman as dev dependency
echo "Installing @apideck/portman..."
npm install --save-dev @apideck/portman

# Install Newman as dev dependency
echo "Installing newman..."
npm install --save-dev newman

# Install newman-reporter-junit for CI/CD integration
echo "Installing newman-reporter-junit..."
npm install --save-dev newman-reporter-junit

echo ""
echo "Installation complete!"
echo ""
echo "You can now use Portman with:"
echo "  npx portman -l openapi.yaml -c portman-config.json"
echo ""
echo "Or run tests with Newman:"
echo "  npx portman -l openapi.yaml -c portman-config.json --runNewman"
