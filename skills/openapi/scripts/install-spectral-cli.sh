#!/usr/bin/env bash

# Install Spectral CLI for OpenAPI linting
# This script installs the Spectral CLI and Redocly OpenAPI CLI globally using npm.
# It requires Node.js and npm to be installed on the system.
# It also use sudo to ensure global installation permissions.

# Test if npm is installed
if ! command -v npm &> /dev/null
then
    echo "npm could not be found. Please install Node.js and npm first."
    exit 1
fi

# Test if node is installed
if ! command -v node &> /dev/null
then
    echo "Node.js could not be found. Please install Node.js first."
    exit 1
fi

# Test if sudo is available
if ! command -v sudo &> /dev/null
then
    echo "sudo could not be found. Please install sudo or run this script as root."
    exit 1
fi

# Test if the node version is compatible (>=22.x.x)
NODE_VERSION=$(node -v | sed 's/v\([0-9]*\).*/\1/')
if [ "$NODE_VERSION" -lt 22 ]; then
    echo "Node.js version 22 or higher is required. Please update your Node.js installation."
    exit 1
fi

# Test is already installed
if command -v spectral &> /dev/null
then
    echo "Spectral CLI is already installed. Skipping installation."
    exit 0
fi

sudo npm install -g @stoplight/spectral-cli
sudo npm install -g @stoplight/spectral-core
