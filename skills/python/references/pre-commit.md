# How to Use Pre-commit

## Setup Script

Use the setup script to automatically install pre-commit hooks:

```bash
./scripts/setup-pre-commit.sh
```

**Install pre-push hooks:**
```bash
./scripts/setup-pre-commit.sh --hook-type pre-push
```

This script will:
- Install pre-commit if not already installed
- Install hooks for the specified stage
- Install hook environments

## Installing Pre-commit Hooks

Install pre-commit hooks to run automatically on git commits:

```bash
pre-commit install
```

This will install hooks for the `pre-commit` stage. To also install hooks for the `pre-push` stage:

```bash
pre-commit install --hook-type pre-push
```

## Running Pre-commit Hooks Manually

Run all pre-commit hooks on all files:

```bash
pre-commit run --all-files
```

Run a specific hook:

```bash
pre-commit run ruff-check --all-files
pre-commit run pytest --all-files
pre-commit run mypy --all-files
```

## Running Pre-commit Hooks on Staged Files

Run hooks only on files that are staged for commit:

```bash
pre-commit run
```

## Pre-commit Hooks Configuration

The project uses the following pre-commit hooks (configured in `.pre-commit-config.yaml`):

### Code Formatting and Linting

- **ruff-format**: Formats code using Ruff
- **ruff-check**: Checks code style and fixes issues automatically
- **trailing-whitespace**: Removes trailing whitespace
- **end-of-file-fixer**: Ensures files end with a newline

### Type Checking

- **mypy**: Performs static type checking

### Code Quality

- **pylint**: Performs additional code quality checks

### Testing

- **pytest**: Runs unit tests with coverage

### Dependency Management

- **poetry lock and update**: Updates and syncs Poetry lock file (runs on pre-push only)

## Pre-commit Hook Stages

Hooks run at different stages:

- **pre-commit**: Runs when you execute `git commit`
- **pre-push**: Runs when you execute `git push`
- **manual**: Can be run manually using `pre-commit run`

## Skipping Pre-commit Hooks

To skip pre-commit hooks for a specific commit (not recommended):

```bash
git commit --no-verify
```

## Updating Pre-commit Hooks

Update pre-commit hooks to their latest versions:

```bash
pre-commit autoupdate
```

This updates the hook versions in `.pre-commit-config.yaml` to the latest available versions.

## Pre-commit Cache

Pre-commit caches hook environments. To clear the cache:

```bash
pre-commit clean
```
