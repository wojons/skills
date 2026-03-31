#!/bin/bash
set -e

# map-required-specs.sh
# Analyze project and determine what specs are needed
#
# Usage: bash map-required-specs.sh [OPTIONS]
#
# Options:
#   --project-type TYPE    Project type (web, api, mobile, game, cli, library)
#   --analyze              Analyze existing specs to find gaps
#   --output FILE          Output file for spec map
#   -v, --verbose          Verbose output
#   -h, --help             Show help

PROJECT_TYPE=""
ANALYZE=false
OUTPUT_FILE=""
VERBOSE=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
            --analyze)
                ANALYZE=true
                shift
                ;;
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
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
Usage: bash map-required-specs.sh [OPTIONS]

Analyze project and determine what specs are required.

Options:
  --project-type TYPE    Project type (web, api, mobile, game, cli, library)
  --analyze              Analyze existing specs to find gaps
  --output FILE          Output file for spec map
  -v, --verbose          Verbose output
  -h, --help             Show help

Project Types:
  web      - Web application (frontend + backend + database)
  api      - API service (backend-only)
  mobile   - Mobile application
  game     - Game or game engine
  cli      - Command-line tool
  library  - Library or SDK

Examples:
  bash map-required-specs.sh --project-type web
  bash map-required-specs.sh --analyze
  bash map-required-specs.sh --project-type api --output spec-map.md
EOF
}

log_info() { [[ "$VERBOSE" == true ]] && echo "[INFO] $1" >&2; }

# Spec requirements by project type
get_required_specs() {
    local type="$1"
    
    case "$type" in
        web)
            echo "REQUIRED:
S01: System Overview (mandatory)
S02: Domain Model (mandatory)
U01: UI Layout (mandatory)
U02: UI Flows (mandatory)
U03: UI Components (mandatory)
U06: UI Error States (mandatory)
A01: API Overview (mandatory)
A02: API Authentication (mandatory)
A03: API Resources (mandatory)
A04: API Errors (mandatory)
D01: Database Schema (mandatory)
D02: Database Queries (mandatory)
X01: Security (mandatory)
X02: Logging (mandatory)
Q01: Test Strategy (mandatory)

RECOMMENDED:
U04: UI Animations
U05: UI Accessibility
A05: API Rate Limiting
A06: API Webhooks
D03: Database Migrations
D04: Data Validation
B01: Business Rules
B02: State Machines
X03: Monitoring
X04: Error Handling
O01: Deployment
O03: Performance

OPTIONAL:
S03: Glossary
B03: Workflows
B04: Calculations
B05: Notifications
D05: Data Retention
X05: Configuration
O02: Infrastructure
O04: Backup & Recovery
O05: Runbooks
Q02: Test Cases
Q03: Acceptance Criteria
Q04: Quality Gates"
            ;;
        api)
            echo "REQUIRED:
S01: System Overview (mandatory)
S02: Domain Model (mandatory)
A01: API Overview (mandatory)
A02: API Authentication (mandatory)
A03: API Resources (mandatory)
A04: API Errors (mandatory)
A05: API Rate Limiting (mandatory)
D01: Database Schema (mandatory)
X01: Security (mandatory)
X02: Logging (mandatory)
Q01: Test Strategy (mandatory)

RECOMMENDED:
A06: API Webhooks
D02: Database Queries
D03: Database Migrations
D04: Data Validation
B01: Business Rules
B02: State Machines
X03: Monitoring
X04: Error Handling
O01: Deployment
O03: Performance

OPTIONAL:
S03: Glossary
D05: Data Retention
B03: Workflows
B04: Calculations
B05: Notifications
X05: Configuration
O02: Infrastructure
O04: Backup & Recovery
O05: Runbooks"
            ;;
        mobile)
            echo "REQUIRED:
S01: System Overview (mandatory)
S02: Domain Model (mandatory)
U01: UI Layout (mandatory)
U02: UI Flows (mandatory)
U03: UI Components (mandatory)
U06: UI Error States (mandatory)
A01: API Overview (mandatory)
A03: API Resources (mandatory)
A04: API Errors (mandatory)
X01: Security (mandatory)
Q01: Test Strategy (mandatory)

RECOMMENDED:
U04: UI Animations
U05: UI Accessibility
A02: API Authentication
D01: Database Schema (local)
B01: Business Rules
B02: State Machines
X02: Logging
O01: Deployment (app store)
O03: Performance

OPTIONAL:
S03: Glossary
U05: UI Accessibility
A05: API Rate Limiting
B03: Workflows
B04: Calculations
B05: Notifications
X03: Monitoring
O04: Backup & Recovery
Q02: Test Cases"
            ;;
        game)
            echo "REQUIRED:
S01: System Overview (mandatory)
S02: Domain Model (mandatory)
U01: UI Layout (mandatory)
U04: UI Animations (mandatory)
D01: Data Structures (mandatory)
B01: Game Rules (mandatory)
B02: State Machines (mandatory)
B04: Calculations (mandatory)
Q01: Test Strategy (mandatory)

RECOMMENDED:
U02: UI Flows
U03: UI Components
A01: API Overview (if multiplayer)
X01: Security (if multiplayer)
X02: Logging
O01: Deployment
O03: Performance

OPTIONAL:
S03: Glossary
U06: UI Error States
B03: Workflows
B05: Notifications
O02: Infrastructure
O04: Save System
Q02: Test Cases"
            ;;
        cli)
            echo "REQUIRED:
S01: System Overview (mandatory)
S02: Domain Model (mandatory)
U01: CLI Interface (mandatory)
D01: Data Structures (mandatory)
B01: Business Rules (mandatory)
X04: Error Handling (mandatory)
Q01: Test Strategy (mandatory)

RECOMMENDED:
A01: API Overview (if has API)
X01: Security
X02: Logging
X05: Configuration
O01: Deployment (package)
O03: Performance

OPTIONAL:
S03: Glossary
D04: Input Validation
B02: State Machines
Q02: Test Cases"
            ;;
        library)
            echo "REQUIRED:
S01: Library Overview (mandatory)
S02: API Surface (mandatory)
D01: Data Structures (mandatory)
B01: Core Logic (mandatory)
X04: Error Handling (mandatory)
Q01: Test Strategy (mandatory)
Q02: Test Cases (mandatory)

RECOMMENDED:
Q03: Acceptance Criteria
Q04: Quality Gates
X02: Logging
X05: Configuration
O01: Distribution

OPTIONAL:
S03: Glossary
X01: Security
B02: Algorithms
O03: Performance"
            ;;
        *)
            echo "REQUIRED:
S01: System Overview (mandatory)

RECOMMENDED:
S02: Domain Model
Q01: Test Strategy

OPTIONAL:
All other specs based on project needs"
            ;;
    esac
}

analyze_existing_specs() {
    local specs_dir="${OUTPUT_FILE%/*}/specs"
    
    if [[ -f "$specs_dir/_index.md" ]]; then
        log_info "Analyzing existing specs from _index.md"
        
        # Read existing specs
        local existing=$(grep -E "^\| S[0-9]+" "$specs_dir/_index.md" 2>/dev/null || echo "")
        
        if [[ -n "$existing" ]]; then
            echo ""
            echo "EXISTING SPECS FOUND"
            echo "===================="
            echo "$existing"
        fi
    fi
}

generate_spec_map() {
    local type="$1"
    local output="$2"
    
    local content="# Specification Map

**Project Type**: ${type:-Unknown}
**Generated**: $(date +%Y-%m-%d)

---

$(get_required_specs "$type")

---

## Recommended Order

1. Start with Tier 1 (Foundation)
2. Move to UI or API based on project type
3. Add Data specs as needed
4. Fill in Business Logic
5. Add Cross-Cutting concerns
6. Define Operations
7. Complete Quality specs

---

## Template Files

All templates available in: \`specs/templates/\`

---

## Next Command

\`\`\`bash
# Generate first spec
bash scripts/generate-spec.sh --spec-id S01 --from-template

# Generate all required specs
bash scripts/generate-spec.sh --all-required
\`\`\`
"
    
    if [[ -n "$output" ]]; then
        echo "$content" > "$output"
        echo "Written to: $output"
    else
        echo "$content"
    fi
}

main() {
    parse_args "$@"
    
    echo ""
    echo "SPECIFICATION MAPPING"
    echo "====================="
    echo ""
    
    if [[ "$ANALYZE" == true ]]; then
        analyze_existing_specs
        echo ""
    fi
    
    if [[ -n "$PROJECT_TYPE" ]]; then
        echo "Project Type: $PROJECT_TYPE"
        generate_spec_map "$PROJECT_TYPE" "$OUTPUT_FILE"
    else
        echo "No project type specified. Showing all available spec types:"
        echo ""
        get_required_specs "all"
    fi
}

main "$@"