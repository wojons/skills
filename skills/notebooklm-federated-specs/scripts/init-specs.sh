#!/bin/bash
set -e

# init-specs.sh
# Initialize federated specs structure
#
# Usage: bash init-specs.sh [OPTIONS]
#
# Options:
#   --project-name NAME    Project name for config
#   --batch-size N         Files per batch (default: 10)
#   --max-batch-size SIZE  Max batch file size (default: 500KB)
#   -h, --help             Show help

PROJECT_NAME=""
BATCH_SIZE=10
MAX_BATCH_SIZE="500KB"

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-name)
                PROJECT_NAME="$2"
                shift 2
                ;;
            --batch-size)
                BATCH_SIZE="$2"
                shift 2
                ;;
            --max-batch-size)
                MAX_BATCH_SIZE="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
Usage: bash init-specs.sh [OPTIONS]

Initialize federated specs structure for NotebookLM.

Options:
  --project-name NAME    Project name for config
  --batch-size N         Files per batch (default: 10)
  --max-batch-size SIZE  Max batch file size (default: 500KB)
  -h, --help             Show help

Creates:
  - specs/ directory with example spec
  - merged-specs/ directory (git-ignored)
  - .notebooklm-specs.json config file
  - Updates .gitignore
EOF
}

main() {
    parse_args "$@"
    
    if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME=$(basename "$PWD")
    fi
    
    echo "Initializing NotebookLM Federated Specs for: $PROJECT_NAME"
    echo ""
    
    # Create specs directory
    if [[ ! -d "specs" ]]; then
        mkdir -p specs
        echo "✓ Created specs/ directory"
    else
        echo "✓ specs/ directory exists"
    fi
    
    # Create merged-specs directory
    if [[ ! -d "merged-specs" ]]; then
        mkdir -p merged-specs
        echo "✓ Created merged-specs/ directory"
    else
        echo "✓ merged-specs/ directory exists"
    fi
    
    # Create example spec if none exist
    if [[ -z "$(ls -A specs/*.md 2>/dev/null)" ]]; then
        cat > specs/00-overview.md << 'EOF'
# Project Overview

> Last Updated: YYYY-MM-DD
> Owner: Team Name
> Status: Draft

## Summary

Brief description of the project.

## Goals

- Goal 1
- Goal 2

## Non-Goals

- What this project will NOT do

## Key Decisions

| Decision | Rationale | Date |
|----------|-----------|------|
| Decision 1 | Why | YYYY-MM-DD |

## Related Specs

- 01-api.md
- 02-database.md
EOF
        echo "✓ Created example spec: specs/00-overview.md"
    fi
    
    # Create config file
    if [[ ! -f ".notebooklm-specs.json" ]]; then
        cat > .notebooklm-specs.json << EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  },
  "notebook": {
    "id": "",
    "title": "$PROJECT_NAME - Merged Specifications",
    "source_ids": []
  },
  "specs_dir": "./specs",
  "merged_dir": "./merged-specs",
  "batch_size": $BATCH_SIZE,
  "max_batch_size": "$MAX_BATCH_SIZE",
  "include_patterns": ["*.md"],
  "exclude_patterns": ["README.md", "CHANGELOG.md", "*.draft.md"],
  "header_format": "\\n\\n=== {filename} ===\\n\\n",
  "auto_sync": false
}
EOF
        echo "✓ Created .notebooklm-specs.json"
    else
        echo "✓ .notebooklm-specs.json exists"
    fi
    
    # Update .gitignore
    if [[ -f ".gitignore" ]]; then
        if ! grep -q "merged-specs/" .gitignore 2>/dev/null; then
            echo "" >> .gitignore
            echo "# Merged specifications (generated files)" >> .gitignore
            echo "merged-specs/" >> .gitignore
            echo "✓ Added merged-specs/ to .gitignore"
        else
            echo "✓ merged-specs/ already in .gitignore"
        fi
    else
        echo "# Merged specifications (generated files)" > .gitignore
        echo "merged-specs/" >> .gitignore
        echo "✓ Created .gitignore with merged-specs/"
    fi
    
    echo ""
    echo "INITIALIZATION COMPLETE"
    echo "======================"
    echo ""
    echo "Next steps:"
    echo "  1. Add your spec files to specs/ directory"
    echo "     (use 00-, 01-, 02- prefix for ordering)"
    echo "  2. Run: bash scripts/merge-specs.sh --batch"
    echo "  3. Run: bash scripts/sync-notebook.sh --create"
    echo ""
}

main "$@"
