#!/usr/bin/env bash

# Pre-requirements:
# - spectral cli installed [scripts/install-spectral-cli.sh](scripts/install-spectral-cli.sh)

# Bundle OpenAPI files using Spectral CLI
# Arguments:
#   $1 - Directory containing OpenAPI files (default: docs/openapi)
#   $2 - Output file for bundled OpenAPI specification (default: dists/openapi_bundled.yaml)

DEFAULT_INPUT_DIR="./docs/openapi"
DEFAULT_OUTPUT_FILE="./dists/openapi_bundled.yaml"

INPUT_DIR=${1:-$DEFAULT_INPUT_DIR}
OUTPUT_FILE=${2:-$DEFAULT_OUTPUT_FILE}

echo "Bundling OpenAPI files from '$INPUT_DIR' into '$OUTPUT_FILE'..."


# Check if the directory exists
if [ ! -d "$INPUT_DIR" ]; then
  echo "Error: Input directory '$INPUT_DIR' does not exist."
  exit 1
fi

# Check if the openapi entrypoint exists
if [ ! -f "$INPUT_DIR/openapi.yaml" ] && [ ! -f "$INPUT_DIR/openapi.yml" ] && [ ! -f "$INPUT_DIR/swagger.yaml" ] && [ ! -f "$INPUT_DIR/swagger.yml" ]; then
  echo "Error: No OpenAPI entrypoint file (openapi.yaml, openapi.yml, swagger.yaml, swagger.yml) found in '$INPUT_DIR'."
  exit 1
fi

# Check if the ouput file directory exists, if not create it
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

# Check if the output file exists, if so create a .back-<date>-<time> of it and remove the original (to avoid Spectral CLI errors).
if [ -f "$OUTPUT_FILE" ]; then
  BACKUP_FILE="$OUTPUT_FILE.back-$(date +%Y%m%d-%H%M%S)"
  cp "$OUTPUT_FILE" "$BACKUP_FILE"
  echo "Warning: Output file '$OUTPUT_FILE' already exists. A backup has been created at '$BACKUP_FILE'."
  rm "$OUTPUT_FILE"
fi

spectral bundle "$INPUT_DIR" --output "$OUTPUT_FILE"
echo "Bundling completed."
