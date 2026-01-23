#!/bin/bash
# Generate Postman collection from OpenAPI specification using Portman
# Usage: ./generate-collection.sh <openapi-spec> [portman-config] [output-file]

set -e

OPENAPI_SPEC="${1:-openapi.yaml}"
PORTMAN_CONFIG="${2:-portman-config.json}"
OUTPUT_FILE="${3:-postman-collection.json}"

# Validate inputs
if [ ! -f "$OPENAPI_SPEC" ]; then
    echo "Error: OpenAPI specification file not found: $OPENAPI_SPEC"
    echo "Usage: $0 <openapi-spec> [portman-config] [output-file]"
    exit 1
fi

if [ ! -f "$PORTMAN_CONFIG" ]; then
    echo "Warning: Portman config file not found: $PORTMAN_CONFIG"
    echo "Using default Portman configuration..."
    PORTMAN_CONFIG=""
fi

echo "Generating Postman collection..."
echo "  OpenAPI Spec: $OPENAPI_SPEC"
echo "  Portman Config: ${PORTMAN_CONFIG:-default}"
echo "  Output: $OUTPUT_FILE"
echo ""

# Build Portman command
CMD="npx portman -l $OPENAPI_SPEC -o $OUTPUT_FILE"

if [ -n "$PORTMAN_CONFIG" ]; then
    CMD="$CMD -c $PORTMAN_CONFIG"
fi

# Add optional flags
if [ -n "$BUNDLE_CONTRACT_TESTS" ]; then
    CMD="$CMD --bundleContractTests"
fi

if [ -n "$EXTRA_UNKNOWN_FORMATS" ]; then
    CMD="$CMD --extraUnknownFormats $EXTRA_UNKNOWN_FORMATS"
fi

# Execute Portman
echo "Running: $CMD"
eval $CMD

echo ""
echo "Postman collection generated: $OUTPUT_FILE"
