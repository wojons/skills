#!/bin/bash
#
# Setup script to install git hooks
# Run this once after cloning the repository
#
# Usage: bash scripts/setup-git-hooks.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$ROOT_DIR/.git/hooks"

echo "Setting up git hooks..."
echo ""

# Install pre-commit hook
if [[ -f "$SCRIPT_DIR/pre-commit" ]]; then
    cp "$SCRIPT_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
    chmod +x "$HOOKS_DIR/pre-commit"
    echo "✓ Installed pre-commit hook"
else
    echo "✗ pre-commit hook not found in scripts/"
    exit 1
fi

echo ""
echo "Git hooks installed successfully!"
echo ""
echo "The pre-commit hook will verify that all skills have:"
echo "  - SKILL.md  (required)"
echo "  - README.md (required)"
echo ""
echo "To regenerate README.md files, run:"
echo "  bash scripts/generate-readmes.sh"