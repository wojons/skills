#!/bin/bash
set -e

# update-index.sh
# Update the spec index with current status
#
# Usage: bash update-index.sh [OPTIONS]
#
# Options:
#   --specs-dir DIR    Specs directory (default: ./specs)
#   -v, --verbose      Verbose output
#   -h, --help         Show help

SPECS_DIR="./specs"
VERBOSE=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --specs-dir)
                SPECS_DIR="$2"
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
Usage: bash update-index.sh [OPTIONS]

Update the _index.md file with current spec status.

Options:
  --specs-dir DIR    Specs directory (default: ./specs)
  -v, --verbose      Verbose output
  -h, --help         Show help

Reads all spec files and updates:
  - Line counts
  - Last modified dates
  - Completion status
  - Dependency graph

Example:
  bash update-index.sh --specs-dir ./docs/specs
EOF
}

log_info() { [[ "$VERBOSE" == true ]] && echo "[INFO] $1" >&2; }
log_success() { echo -e "\033[0;32m[OK]\033[0m $1" >&2; }

get_file_lines() {
    wc -l < "$1" 2>/dev/null || echo "0"
}

get_file_date() {
    stat -f "%Sm" -t "%Y-%m-%d" "$1" 2>/dev/null || \
    stat -c "%y" "$1" 2>/dev/null | cut -d' ' -f1 || \
    date +%Y-%m-%d
}

check_spec_complete() {
    local file="$1"
    local content=$(cat "$file" 2>/dev/null)
    
    # Check for quality gates section
    if echo "$content" | grep -q "Quality Gates"; then
        # Check if checkboxes are marked
        local checked=$(echo "$content" | grep -c "\- \[x\]" 2>/dev/null || echo "0")
        local total=$(echo "$content" | grep -c "\- \[" 2>/dev/null || echo "0")
        
        if [[ $total -gt 0 ]] && [[ $checked -ge $total ]]; then
            echo "complete"
        elif [[ $checked -gt 0 ]]; then
            echo "in_progress"
        else
            echo "pending"
        fi
    else
        # Check if file has substantial content
        local lines=$(get_file_lines "$file")
        if [[ $lines -gt 100 ]]; then
            echo "in_progress"
        else
            echo "pending"
        fi
    fi
}

main() {
    parse_args "$@"
    
    local index_file="$SPECS_DIR/_index.md"
    
    if [[ ! -f "$index_file" ]]; then
        echo "Error: _index.md not found at $index_file" >&2
        echo "Run: bash init-specs-structure.sh first" >&2
        exit 1
    fi
    
    log_info "Scanning specs directory: $SPECS_DIR"
    
    # Find all spec files (excluding _index.md, _prompt.md, templates)
    local spec_files=()
    while IFS= read -r -d '' file; do
        spec_files+=("$file")
    done < <(find "$SPECS_DIR" -name "*.md" \
        ! -name "_index.md" \
        ! -name "_prompt.md" \
        ! -path "*/templates/*" \
        -print0 2>/dev/null | sort -z)
    
    local total=${#spec_files[@]}
    local complete=0
    local in_progress=0
    local pending=0
    
    echo ""
    echo "UPDATING SPEC INDEX"
    echo "==================="
    echo "Found $total spec files"
    echo ""
    
    # Build new registry
    local registry=""
    
    for file in "${spec_files[@]}"; do
        local filename=$(basename "$file")
        local rel_path="${filename%.md}"
        local lines=$(get_file_lines "$file")
        local date=$(get_file_date "$file")
        local status=$(check_spec_complete "$file")
        
        case "$status" in
            complete)
                ((complete++))
                status_icon="✅ Complete"
                ;;
            in_progress)
                ((in_progress++))
                status_icon="🔄 In Progress"
                ;;
            *)
                ((pending++))
                status_icon="⏳ Pending"
                ;;
        esac
        
        # Extract spec ID from filename (e.g., 01-system-overview -> S01)
        local spec_id="??"
        if [[ "$filename" =~ ^([0-9]+)- ]]; then
            spec_id="S${BASH_REMATCH[1]}"
        elif [[ "$filename" =~ ^u([0-9]+)- ]]; then
            spec_id="U${BASH_REMATCH[1]}"
        elif [[ "$filename" =~ ^a([0-9]+)- ]]; then
            spec_id="A${BASH_REMATCH[1]}"
        elif [[ "$filename" =~ ^d([0-9]+)- ]]; then
            spec_id="D${BASH_REMATCH[1]}"
        elif [[ "$filename" =~ ^b([0-9]+)- ]]; then
            spec_id="B${BASH_REMATCH[1]}"
        elif [[ "$filename" =~ ^x([0-9]+)- ]]; then
            spec_id="X${BASH_REMATCH[1]}"
        elif [[ "$filename" =~ ^o([0-9]+)- ]]; then
            spec_id="O${BASH_REMATCH[1]}"
        elif [[ "$filename" =~ ^q([0-9]+)- ]]; then
            spec_id="Q${BASH_REMATCH[1]}"
        fi
        
        registry+="| $spec_id | $filename | - | $status_icon | - | $lines | $date |
"
        
        log_info "  $filename: $status_icon ($lines lines)"
    done
    
    # Update index file
    local date=$(date +%Y-%m-%d)
    
    # Read existing header
    local header=$(head -20 "$index_file")
    
    # Create new header with updated counts
    local new_header="# Specification Index

**Project**: $(grep "Project" "$index_file" | cut -d: -f2- | xargs || echo "Project")
**Last Updated**: $date
**Total Specs**: $total
**Completed**: $complete
**In Progress**: $in_progress
**Pending**: $pending

---

## Spec Registry

| ID | Spec File | Category | Status | Dependencies | Lines | Last Modified |
|----|-----------|----------|--------|--------------|-------|---------------|
$registry"
    
    # Write updated index
    echo "$new_header" > "$index_file.new"
    
    # Append remaining sections from old index
    if grep -q "^---" "$index_file"; then
        tail -n +$(grep -n "^---" "$index_file" | tail -1 | cut -d: -f1) "$index_file" >> "$index_file.new" 2>/dev/null || true
    fi
    
    mv "$index_file.new" "$index_file"
    
    log_success "Updated: $index_file"
    
    echo ""
    echo "SUMMARY"
    echo "======="
    echo "Total specs: $total"
    echo "Complete: $complete"
    echo "In progress: $in_progress"
    echo "Pending: $pending"
    echo ""
    
    if [[ $pending -gt 0 ]] || [[ $in_progress -gt 0 ]]; then
        echo "NEXT ACTIONS"
        echo "============"
        if [[ $in_progress -gt 0 ]]; then
            echo "- Continue in-progress specs"
        fi
        if [[ $pending -gt 0 ]]; then
            echo "- Start pending specs from templates"
        fi
        echo "- Re-run this script after updates"
    fi
}

main "$@"