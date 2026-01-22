#!/usr/bin/env bash

# Lint commit messages against Conventional Commits specification
#
# This script runs commitlint to validate commit messages in a given range.
# Useful for CI/CD pipelines or manual validation of commit history.
#
# Pre-requirements:
#   - commitlint installed (run install-commitlint.sh first)
#   - Git repository with commits
#
# Arguments:
#   $1 - (Optional) Start reference (default: HEAD~1)
#   $2 - (Optional) End reference (default: HEAD)
#
# Usage:
#   ./lint-commits.sh                     # Lint last commit
#   ./lint-commits.sh HEAD~5              # Lint last 5 commits
#   ./lint-commits.sh origin/main         # Lint all commits since main
#   ./lint-commits.sh v1.0.0 HEAD         # Lint commits between tag and HEAD
#   ./lint-commits.sh origin/main HEAD    # Lint commits from main to HEAD

set -euo pipefail

FROM_REF="${1:-HEAD~1}"
TO_REF="${2:-HEAD}"

echo "Linting commits from ${FROM_REF} to ${TO_REF}..."
echo ""

# Check if commitlint is installed
if ! command -v commitlint &> /dev/null; then
    # Check for local installation
    if [ -f "node_modules/.bin/commitlint" ]; then
        COMMITLINT_CMD="npx commitlint"
    else
        echo "Error: commitlint is not installed."
        echo "Please run install-commitlint.sh first or install locally:"
        echo "  npm install --save-dev @commitlint/cli @commitlint/config-conventional"
        exit 1
    fi
else
    COMMITLINT_CMD="commitlint"
fi

# Verify we're in a git repository
if ! git rev-parse --git-dir &> /dev/null; then
    echo "Error: Not a git repository."
    exit 1
fi

# Verify references exist
if ! git rev-parse "$FROM_REF" &> /dev/null; then
    echo "Error: Reference '${FROM_REF}' not found."
    exit 1
fi

if ! git rev-parse "$TO_REF" &> /dev/null; then
    echo "Error: Reference '${TO_REF}' not found."
    exit 1
fi

# Count commits to lint
COMMIT_COUNT=$(git rev-list --count "${FROM_REF}..${TO_REF}" 2>/dev/null || echo "0")

if [ "$COMMIT_COUNT" -eq 0 ]; then
    echo "No commits found in range ${FROM_REF}..${TO_REF}"
    echo ""
    echo "Tips:"
    echo "  - Use HEAD~N to lint last N commits"
    echo "  - Use origin/main to lint all commits since main branch"
    exit 0
fi

echo "Found ${COMMIT_COUNT} commit(s) to lint."
echo ""

# Show commits being linted
echo "Commits:"
git log --oneline "${FROM_REF}..${TO_REF}"
echo ""

# Run commitlint
echo "Running commitlint..."
echo "────────────────────────────────────────"

if $COMMITLINT_CMD --from "$FROM_REF" --to "$TO_REF" --verbose; then
    echo "────────────────────────────────────────"
    echo ""
    echo "✅ All ${COMMIT_COUNT} commit(s) pass commitlint validation!"
else
    EXIT_CODE=$?
    echo "────────────────────────────────────────"
    echo ""
    echo "❌ Commit validation failed!"
    echo ""
    echo "Expected commit format:"
    echo "  [TICKET-ID] type(scope): description"
    echo ""
    echo "Examples:"
    echo "  [TIC-001] feat: add new feature"
    echo "  [API-123] fix(auth): resolve login issue"
    echo "  [DOCS-001] docs: update README"
    echo ""
    echo "Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert"
    exit $EXIT_CODE
fi
