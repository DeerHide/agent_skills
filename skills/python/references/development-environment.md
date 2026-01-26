# Development Environment

## Setup Script

Use the setup script to automatically configure Poetry and create the virtual environment:

```bash
./scripts/setup-dev-environment.sh
```

This script will:
- Install Poetry if not already installed
- Configure Poetry to use local `.venv` directory
- Install all dependencies including test dependencies

## Virtual Environment

This project uses a virtual environment located in `.venv` directory. The virtual environment should be created and activated before working on the project.

### Creating Virtual Environment

The virtual environment is typically created automatically by Poetry when installing dependencies. If you need to create it manually:

```bash
python3.12 -m venv .venv
```

### Activating Virtual Environment

**On Linux/macOS:**
```bash
source .venv/bin/activate
```

**On Windows:**
```bash
.venv\Scripts\activate
```

### Deactivating Virtual Environment

```bash
deactivate
```

## Poetry

This project uses [Poetry](https://python-poetry.org/) for dependency management and packaging. Poetry manages dependencies defined in `pyproject.toml`.

### Installing Poetry

If Poetry is not installed, follow the [official installation guide](https://python-poetry.org/docs/#installation).

### Installing Dependencies

Install all dependencies including development dependencies:

```bash
poetry install --with test
```

This will:
- Create a virtual environment if it doesn't exist (in `.venv` directory)
- Install all production dependencies
- Install all test dependencies (from `[tool.poetry.group.test]`)

### Adding Dependencies

**Production dependency:**
```bash
poetry add package-name
```

**Development dependency:**
```bash
poetry add --group test package-name
```

### Updating Dependencies

Update all dependencies to their latest compatible versions:

```bash
poetry update --with test
```

This will update `poetry.lock` file with the latest compatible versions.

### Synchronizing Dependencies

Ensure the virtual environment matches the lock file exactly:

```bash
poetry install --with test --sync
```

### Running Commands in Virtual Environment

Poetry can run commands in the virtual environment without activating it:

```bash
poetry run pytest
poetry run mypy
poetry run ruff check src tests
```

### Virtual Environment Location

By default, Poetry creates virtual environments in a centralized location. This project uses a local `.venv` directory in the project root. To configure Poetry to use a local virtual environment:

```bash
poetry config virtualenvs.in-project true
```
