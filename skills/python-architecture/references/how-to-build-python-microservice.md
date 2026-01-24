# How to Build a Python Microservice ?

## Overview

This document provides a step-by-step guide to building a production-ready Python microservice using FastAPI, Poetry for package management, and Cloud Native Buildpacks for containerization. We use Paketo Buildpacks to create optimized container images.

## Prerequisites

- Python 3.12 or higher installed
- Poetry and Project Installed and configured
- Docker and Docker CLI installed (for containerization)
- Pack CLI installed (for Cloud Native Buildpacks)
- Target Container Registry account (e.g., Docker Hub, AWS ECR, Harbor,etc.)

## Steps to Build the Microservice

1. **Update Dependencies and Define a poetry.lock File**

   Ensure that your `pyproject.toml` file is up to date with the required dependencies. Run the following command to update dependencies and generate a `poetry.lock` file:

   ```bash
   poetry lock && poetry update
   ```

2. **Authenticate with Your Container Registry**

   Log in to your target container registry using the Docker CLI. Replace `<registry-url>` with your registry's URL:

   ```bash
   cat $PASSWORD | docker login <registry-url> -u <username> --password-stdin
   ```

3. **Build the Container Image Using Pack**

    Use the Pack CLI to build your container image. Replace `<image-name>` with your desired image name and `<registry-url>` with your registry's URL:
  
    ```bash
    pack build "${IMAGE}" \
      -B paketobuildpacks/builder-jammy-base \
      --buildpack paketo-buildpacks/python \
      --trust-builder \
      --publish \
      <registry-url>/<image-name>:latest
    ```

## External References

| Document | Description |
|----------|-------------|
| [Paketo Buildpacks](https://paketo.io/docs/howto/python/) | Python buildpack documentation |
