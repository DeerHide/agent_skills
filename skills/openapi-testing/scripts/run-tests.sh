#!/bin/bash
# Run OpenAPI contract tests using Portman and Newman
# Usage: ./run-tests.sh <openapi-spec> [portman-config] [base-url] [newman-options]

set -e

OPENAPI_SPEC="${1:-openapi.yaml}"
PORTMAN_CONFIG="${2:-portman-config.json}"
BASE_URL="${3:-}"
NEWMAN_OPTIONS="${4:-newman-options.json}"

# Validate inputs
if [ ! -f "$OPENAPI_SPEC" ]; then
    echo "Error: OpenAPI specification file not found: $OPENAPI_SPEC"
    echo "Usage: $0 <openapi-spec> [portman-config] [base-url] [newman-options]"
    exit 1
fi

echo "Running OpenAPI contract tests..."
echo "  OpenAPI Spec: $OPENAPI_SPEC"
echo "  Portman Config: ${PORTMAN_CONFIG:-default}"
echo "  Base URL: ${BASE_URL:-from spec}"
echo "  Newman Options: ${NEWMAN_OPTIONS:-default}"
echo ""

# Create test-results directory if it doesn't exist
mkdir -p test-results

# Build Portman command
CMD="npx portman -l $OPENAPI_SPEC --runNewman"

if [ -f "$PORTMAN_CONFIG" ]; then
    CMD="$CMD -c $PORTMAN_CONFIG"
fi

if [ -n "$BASE_URL" ]; then
    CMD="$CMD -b $BASE_URL"
fi

if [ -f "$NEWMAN_OPTIONS" ]; then
    CMD="$CMD --newmanOptionsFile $NEWMAN_OPTIONS"
fi

# Add optional flags
if [ -n "$BUNDLE_CONTRACT_TESTS" ]; then
    CMD="$CMD --bundleContractTests"
fi

if [ -n "$EXTRA_UNKNOWN_FORMATS" ]; then
    CMD="$CMD --extraUnknownFormats $EXTRA_UNKNOWN_FORMATS"
fi

if [ -n "$IGNORE_CIRCULAR_REFS" ]; then
    CMD="$CMD --ignoreCircularRefs"
fi

# Execute Portman with Newman
echo "Running: $CMD"
eval $CMD

echo ""
echo "Tests completed. Results available in test-results/"
