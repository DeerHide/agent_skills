#!/usr/bin/env bash

# This script lints the OpenAPI specification bundle using Spectral.
# To use this script, ensure you have Spectral CLI installed through npm scripts/install-spectral-cli.sh.
# It checks for adherence to best practices and common issues.
# Arguments:
#   $1 - Path to the OpenAPI specification file (YAML or JSON)
#   $2 - Path to the Spectral ruleset file (YAML)
#   $3 - (Optional) Output format for the linting results (default: pretty)
# Example formats: plain, pretty, json, github-actions, junit
# Example Usage:
#   ./lint-openapi-bundle.sh path/to/openapi.yml path/to/ruleset.yml
#   ./lint-openapi-bundle.sh path/to/openapi.yml path/to/ruleset.yml [format (plain|pretty|json|github-actions|junit)]

# Check if spectral is installed
if ! command -v spectral &> /dev/null; then
    echo "Spectral CLI is not installed. Please install it using scripts/install-spectral-cli.sh."
    exit 1
fi

# Validate input arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 path/to/openapi.yml path/to/ruleset.yml"
    echo "Usage: $0 path/to/openapi.yml path/to/ruleset.yml [format (plain|pretty|json|github-actions|junit)]"
    exit 1
fi

OPEN_API_FILE=${1}
RULESET_FILE=${2}
FORMAT=${3:-pretty}
FAILED_LEVEL="info"

# Check if the provided OpenAPI file exists
if [ ! -f "${OPEN_API_FILE}" ]; then
    echo "Error: OpenAPI specification file '${OPEN_API_FILE}' not found."
    exit 1
fi

# Check if the provided ruleset file exists
if [ ! -f "${RULESET_FILE}" ]; then
    echo "Error: Ruleset file '${RULESET_FILE}' not found."
    exit 1
fi

# Check if the provided format is valid
VALID_FORMATS=("plain" "pretty" "json" "github-actions" "junit")
if [[ ! " ${VALID_FORMATS[@]} " =~ " ${FORMAT} " ]]; then
    echo "Error: Invalid format '${FORMAT}'. Valid formats are: ${VALID_FORMATS[*]}"
    exit 1
fi

set -euo pipefail

spectral lint \
  -F "${FAILED_LEVEL}" \
  -f "${FORMAT}" \
  "${OPEN_API_FILE}" \
  --ruleset "${RULESET_FILE}"

echo "Linting completed for ${OPEN_API_FILE} using ruleset ${RULESET_FILE}."
