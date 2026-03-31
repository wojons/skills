#!/bin/bash
set -e

# init-specs-structure.sh
# Initialize exhaustive specs directory structure with _prompt.md, _index.md, and templates
#
# Usage: bash init-specs-structure.sh [OPTIONS]
#
# Options:
#   --project NAME        Project name
#   --output-dir DIR      Output directory (default: ./specs)
#   --skip-templates      Skip template generation
#   -v, --verbose         Verbose output
#   -h, --help            Show help

PROJECT_NAME=""
OUTPUT_DIR="./specs"
SKIP_TEMPLATES=false
VERBOSE=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project)
                PROJECT_NAME="$2"
                shift 2
                ;;
            --output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --skip-templates)
                SKIP_TEMPLATES=true
                shift
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
Usage: bash init-specs-structure.sh [OPTIONS]

Initialize exhaustive specs directory with _prompt.md, _index.md, and templates.

Options:
  --project NAME        Project name
  --output-dir DIR      Output directory (default: ./specs)
  --skip-templates      Skip template generation
  -v, --verbose         Verbose output
  -h, --help            Show help

Creates:
  specs/
  ├── _prompt.md          # Base prompt for detail level
  ├── _index.md           # Spec registry and status
  ├── templates/          # Spec templates
  │   ├── 01-system-overview.md
  │   ├── u01-ui-layout.md
  │   ├── a01-api-overview.md
  │   └── ...
  └── 01-system-overview.md  # First spec to fill in

Examples:
  bash init-specs-structure.sh --project "E-commerce Platform"
  bash init-specs-structure.sh --project "Game Engine" --output-dir ./docs/specs
EOF
}

log_info() { [[ "$VERBOSE" == true ]] && echo "[INFO] $1" >&2; }
log_success() { echo -e "\033[0;32m[OK]\033[0m $1" >&2; }

create_prompt_file() {
    local prompt_file="$OUTPUT_DIR/_prompt.md"
    
    cat > "$prompt_file" << 'EOF'
# Exhaustive Specification Prompt

> This file defines the detail level standard for ALL specs in this project.
> When context is lost, read this file to maintain spec quality.

## Detail Level Standard

**BLIND-PERSON VISUALIZATION**: Write specs so detailed that someone who cannot see can fully visualize the system. Every UI element, animation, color, interaction must be described in prose.

**NO ASSUMPTIONS**: Every decision must be explicit. Never write "as discussed" or "standard practice". Define everything.

**EXHAUSTIVE COVERAGE**: 
- Happy path + ALL error paths
- All edge cases enumerated
- All timing, sizing, spacing specified
- All states and transitions documented
- All data transformations explained

---

## Writing Standards

### For UI/UX Specs
- Exact pixel dimensions, colors (hex codes), fonts (name, size, weight)
- Animation timing (ms), easing functions (linear, ease-in, ease-out)
- Responsive breakpoints (exact widths)
- Accessibility requirements (WCAG level, specific requirements)
- Error states, loading states, empty states

### For API Specs  
- Request/response schemas with concrete examples
- All error codes with causes and resolutions
- Rate limits, timeouts, retry behavior
- Authentication/authorization for each endpoint
- Idempotency requirements

### For Database Specs
- Complete schema with constraints, defaults, nullability
- Index strategy and rationale
- Query patterns with example queries
- Migration strategies
- Backup/recovery procedures

### For Business Logic Specs
- Step-by-step algorithms
- Decision trees for all branches
- Input validation at each step
- State machines with all transitions
- Error handling at each step

---

## Structure Template

Every spec follows this structure:

```markdown
# [Spec Name]

## 1. Overview
- Purpose and scope
- Dependencies
- Related specs

## 2. Interface
- Inputs (with types, validation)
- Outputs (with types, formats)
- Integration points

## 3. Behavior
### 3.1 Happy Path
- Step-by-step flow

### 3.2 Error Paths
- Each error condition
- Error handling
- User messaging

### 3.3 Edge Cases
- Boundary conditions
- Unusual inputs
- Race conditions

## 4. Data
- Data structures
- State transitions
- Persistence requirements

## 5. States
- All possible states
- State transitions
- Initial/final states

## 6. Errors
- Error codes/names
- Causes
- Handling
- User messages

## 7. Testing
- Test cases for each behavior
- Edge case tests
- Error handling tests

## 8. Security
- Authentication/authorization
- Data protection
- Vulnerability considerations

## 9. Performance
- Response time requirements
- Throughput requirements
- Resource limits
```

---

## Quality Gates

Before marking any spec complete, verify:

- [ ] **Blind-person test**: Can someone visualize this from description alone?
- [ ] **No assumptions**: Is every "standard" or "obvious" thing explicitly stated?
- [ ] **All error paths**: Every failure scenario documented?
- [ ] **Edge cases enumerated**: All boundary conditions listed?
- [ ] **Concrete examples**: Example for every data structure?
- [ ] **Units specified**: All timings/sizings have units (ms, px, etc)?
- [ ] **Cross-references**: Links to related specs?

---

## Anti-Patterns to Avoid

❌ "As discussed previously"
❌ "Standard error handling"
❌ "Follow best practices"
❌ "In the usual way"
❌ "See documentation"
❌ "Similar to X"

Instead:
✅ "In section 3.2, we defined error handing as..."
✅ "Errors return { code: string, message: string, details: object }"
✅ "For authentication, use JWT with RS256..."
✅ "The algorithm is: 1) Validate input, 2) Check permissions..."

---

## Context Recovery

If context is lost:

1. Read this file (`_prompt.md`)
2. Read `_index.md` for spec status
3. Read the in-progress spec
4. Continue writing with these standards
EOF

    log_success "Created: _prompt.md"
}

create_index_file() {
    local index_file="$OUTPUT_DIR/_index.md"
    local date=$(date +%Y-%m-%d)
    
    cat > "$index_file" << EOF
# Specification Index

**Project**: ${PROJECT_NAME:-Unnamed Project}
**Last Updated**: ${date}
**Total Specs**: 1
**Completed**: 0
**In Progress**: 1
**Pending**: 0

---

## Spec Registry

| ID | Spec File | Category | Status | Dependencies | Lines | Last Modified |
|----|-----------|----------|--------|--------------|-------|---------------|
| S01 | 01-system-overview.md | Core | 🔄 In Progress | None | 0 | ${date} |

---

## Dependency Graph

\`\`\`
S01 (System Overview)
└── [No dependencies - Start here]
\`\`\`

---

## Categories

### Core (1 spec)
- [ ] S01: System Overview (in progress)

### UI/UX (0 specs)
- [ ] No UI specs defined yet

### API (0 specs)
- [ ] No API specs defined yet

### Database (0 specs)
- [ ] No database specs defined yet

### Business Logic (0 specs)
- [ ] No business logic specs defined yet

### Cross-Cutting (0 specs)
- [ ] No cross-cutting specs defined yet

### Operations (0 specs)
- [ ] No operations specs defined yet

### Quality (0 specs)
- [ ] No quality specs defined yet

---

## Spec Type Map

Run \`bash scripts/map-required-specs.sh\` to determine what specs are needed.

### Potential Spec Types

| Tier | Category | Specs Needed |
|------|----------|--------------|
| 1 | Foundation | S01-System Overview, S02-Domain Model, S03-Glossary |
| 2 | UI/UX | U01-Layout, U02-Flows, U03-Components, U04-Animations, U05-Accessibility, U06-Error States |
| 3 | API | A01-Overview, A02-Auth, A03-Resources, A04-Errors, A05-Rate Limiting, A06-Webhooks |
| 4 | Data | D01-Schema, D02-Queries, D03-Migrations, D04-Validation, D05-Retention |
| 5 | Business | B01-Rules, B02-State Machines, B03-Workflows, B04-Calculations, B05-Notifications |
| 6 | Cross-Cutting | X01-Security, X02-Logging, X03-Monitoring, X04-Error Handling, X05-Configuration |
| 7 | Operations | O01-Deployment, O02-Infrastructure, O03-Performance, O04-Backup, O05-Runbooks |
| 8 | Quality | Q01-Test Strategy, Q02-Test Cases, Q03-Acceptance Criteria, Q04-Quality Gates |

---

## Next Actions

1. Complete S01: System Overview
2. Run \`map-required-specs.sh\` to identify needed specs
3. Generate specs from templates

---

## Notes

- All spec files follow the structure defined in \`_prompt.md\`
- Update this index when adding/completing specs
- Use \`bash scripts/update-index.sh\` to auto-update
EOF

    log_success "Created: _index.md"
}

create_template_files() {
    local template_dir="$OUTPUT_DIR/templates"
    mkdir -p "$template_dir"
    
    # System Overview template
    cat > "$template_dir/01-system-overview.md" << 'EOF'
# System Overview

## 1. Purpose

[What problem does this system solve? Why does it exist?]

## 2. Success Criteria

[What does "perfect" look like? How do we measure success?]

## 3. Users & Stakeholders

### 3.1 User Personas

[Who uses this system? What are their characteristics?]

### 3.2 Stakeholders

[Who cares about this system? What are their concerns?]

## 4. High-Level Architecture

[Describe the system at a high level - can be visualized without diagrams]

## 5. Core Components

[List and describe each major component]

## 6. Key Decisions

[What are the important design decisions and why?]

## 7. Constraints

[What limitations exist? Technical, business, regulatory?]

## 8. Assumptions

[What assumptions are we making? These must be validated]

## 9. Risks

[What could go wrong? What are we worried about?]

## 10. Related Specs

[List related specification files]
EOF

    log_success "Created: templates/01-system-overview.md"
    
    # UI Layout template
    cat > "$template_dir/u01-ui-layout.md" << 'EOF'
# UI Layout Specification

## 1. Overview

[Purpose of this UI component/page]

## 2. Layout Structure

### 2.1 Overall Layout

[Describe the page layout - header, content, sidebar, footer]

### 2.2 Grid System

[Columns, gutters, margins in pixels]

### 2.3 Responsive Breakpoints

[Exact widths for each breakpoint]

## 3. Component Hierarchy

[Tree structure of components]

## 4. Spacing

[All margins, paddings with exact values]

## 5. Visual Design

### 5.1 Colors

[Hex codes for all colors used]

### 5.2 Typography

[Fonts, sizes, weights, line heights]

### 5.3 Borders & Shadows

[All border styles, radii, shadow definitions]

## 6. Accessibility

[ARIA labels, keyboard navigation, focus states]

## 7. States

[Loading, empty, error states for this layout]

## 8. Related Specs

[Links to related specifications]
EOF

    log_success "Created: templates/u01-ui-layout.md"
    
    # API Overview template
    cat > "$template_dir/a01-api-overview.md" << 'EOF'
# API Overview

## 1. Purpose

[What does this API provide?]

## 2. Base URL

[API base URL for each environment]

## 3. Authentication

[Authentication method, token format, refresh logic]

## 4. Request/Response Format

[Content-Type, character encoding, date format]

## 5. Versioning

[Version strategy, header format]

## 6. Rate Limiting

[Limits, headers, retry behavior]

## 7. Error Format

[Error response structure]

## 8. Endpoints Summary

[Table of all endpoints with method, path, description]

## 9. Pagination

[How pagination works]

## 10. Related Specs

[Links to detailed endpoint specs]
EOF

    log_success "Created: templates/a01-api-overview.md"
    
    # Database Schema template
    cat > "$template_dir/d01-database-schema.md" << 'EOF'
# Database Schema

## 1. Overview

[Purpose of this database]

## 2. Database Type

[PostgreSQL, MySQL, MongoDB, etc. and version]

## 3. Tables/Collections

### Table: [table_name]

| Column | Type | Nullable | Default | Constraints | Index |
|--------|------|----------|---------|-------------|-------|
| id | bigint | NO | auto | PRIMARY KEY | PK |

[For each table]

## 4. Relationships

[Foreign keys, cardinality]

## 5. Indexes

[All indexes with rationale]

## 6. Constraints

[Unique, check constraints]

## 7. Triggers

[If any, with purpose and logic]

## 8. Views

[Materialized or regular views]

## 9. Migrations

[Link to migration files]

## 10. Query Patterns

[Common query patterns with examples]
EOF

    log_success "Created: templates/d01-database-schema.md"
}

create_first_spec() {
    local spec_file="$OUTPUT_DIR/01-system-overview.md"
    
    if [[ ! -f "$spec_file" ]]; then
        cp "$OUTPUT_DIR/templates/01-system-overview.md" "$spec_file"
        log_success "Created: 01-system-overview.md (start here)"
    fi
}

main() {
    parse_args "$@"
    
    if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME=$(basename "$PWD")
    fi
    
    echo ""
    echo "INITIALIZING EXHAUSTIVE SPECS STRUCTURE"
    echo "======================================="
    echo "Project: $PROJECT_NAME"
    echo "Output: $OUTPUT_DIR"
    echo ""
    
    # Create directories
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR/templates"
    
    log_info "Creating directory structure..."
    
    # Create core files
    create_prompt_file
    create_index_file
    
    if [[ "$SKIP_TEMPLATES" != true ]]; then
        create_template_files
    fi
    
    create_first_spec
    
    echo ""
    echo "STRUCTURE CREATED"
    echo "================="
    echo ""
    echo "Files created:"
    echo "  - $OUTPUT_DIR/_prompt.md      (detail standard)"
    echo "  - $OUTPUT_DIR/_index.md       (spec registry)"
    echo "  - $OUTPUT_DIR/templates/      (spec templates)"
    echo "  - $OUTPUT_DIR/01-system-overview.md (start here)"
    echo ""
    echo "NEXT STEPS"
    echo "=========="
    echo "1. Edit _prompt.md to customize detail standard"
    echo "2. Fill in 01-system-overview.md"
    echo "3. Run: bash scripts/map-required-specs.sh"
    echo "4. Generate remaining specs from templates"
}

main "$@"