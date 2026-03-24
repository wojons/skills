#!/bin/bash
set -e

# sync-notebook.sh
# Sync merged specs with NotebookLM
#
# Usage: bash sync-notebook.sh [OPTIONS]
#
# Options:
#   --create               Create new notebook
#   --update               Update existing notebook (from config)
#   --status               Check sync status
#   --force                Force full resync
#   --batch                Upload batch files from merged-specs/ directory
#   --title TITLE          Notebook title (for --create)
#   -c, --config FILE      Config file path
#   -v, --verbose          Verbose output
#   -h, --help             Show help
#
# Requires: nlm CLI or NotebookLM MCP tools available

# Default settings
CONFIG_FILE=".notebooklm-specs.json"
MERGED_FILE="./merged-specs.md"
ACTION=""
NOTEBOOK_TITLE="Project Specs"
FORCE=false
BATCH_MODE=false
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --create)
                ACTION="create"
                shift
                ;;
            --update)
                ACTION="update"
                shift
                ;;
            --status)
                ACTION="status"
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --batch)
                BATCH_MODE=true
                shift
                ;;
            --title)
                NOTEBOOK_TITLE="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
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
                echo -e "${RED}Unknown option: $1${NC}" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
Usage: bash sync-notebook.sh [OPTIONS]

Sync merged specs with NotebookLM.

Options:
  --create               Create new notebook
  --update               Update existing notebook (from config)
  --status               Check sync status
  --force                Force full resync
  --batch                Upload batch files from merged-specs/ directory
  --title TITLE          Notebook title (for --create)
  -c, --config FILE      Config file path
  -v, --verbose          Verbose output
  -h, --help             Show help

Examples:
  bash sync-notebook.sh --create --title "My Project Specs"
  bash sync-notebook.sh --create --batch --title "My Project Specs"
  bash sync-notebook.sh --update
  bash sync-notebook.sh --status
  bash sync-notebook.sh --update --force
EOF
}

log_info() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    fi
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if nlm CLI is available
check_nlm() {
    if command -v nlm >/dev/null 2>&1; then
        return 0
    else
        log_error "nlm CLI not found. Install with: npm install -g notebooklm-mcp"
        log_error "Alternatively, use the NotebookLM MCP tools directly."
        return 1
    fi
}

# Get config value
get_config() {
    local key="$1"
    if [[ -f "$CONFIG_FILE" ]] && command -v jq >/dev/null 2>&1; then
        jq -r "$key // empty" "$CONFIG_FILE" 2>/dev/null
    fi
}

# Set config value
set_config() {
    local key="$1"
    local value="$2"
    
    if command -v jq >/dev/null 2>&1; then
        if [[ -f "$CONFIG_FILE" ]]; then
            local tmp=$(mktemp)
            jq "$key = \"$value\"" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
        else
            echo "{\"notebook\": {\"id\": \"\", \"title\": \"\", \"source_id\": \"\"}}" | \
                jq "$key = \"$value\"" > "$CONFIG_FILE"
        fi
    fi
}

# Compute hash of merged file
compute_hash() {
    if [[ -f "$MERGED_FILE" ]]; then
        shasum -a 256 "$MERGED_FILE" 2>/dev/null | cut -d' ' -f1 || \
            md5sum "$MERGED_FILE" 2>/dev/null | cut -d' ' -f1 || \
            echo "unknown"
    else
        echo "none"
    fi
}

# Create new notebook
create_notebook() {
    log_info "Creating notebook: $NOTEBOOK_TITLE"
    
    local files_to_upload=()
    
    if [[ "$BATCH_MODE" == true ]]; then
        # Use batch files from merged-specs/
        if [[ -d "merged-specs" ]]; then
            while IFS= read -r file; do
                files_to_upload+=("$file")
            done < <(find merged-specs -name "merged-specs-*.md" -type f | sort)
        else
            log_error "merged-specs/ directory not found. Run merge-specs.sh --batch first"
            exit 1
        fi
        
        if [[ ${#files_to_upload[@]} -eq 0 ]]; then
            log_error "No batch files found in merged-specs/"
            exit 1
        fi
    else
        # Use single merged file
        if [[ ! -f "$MERGED_FILE" ]]; then
            log_error "Merged file not found: $MERGED_FILE"
            log_error "Run merge-specs.sh first"
            exit 1
        fi
        files_to_upload+=("$MERGED_FILE")
    fi
    
    # Use nlm CLI to create notebook
    local notebook_id=$(nlm notebook create --title "$NOTEBOOK_TITLE" 2>/dev/null | grep -oE '[a-f0-9-]{36}' | head -1)
    
    if [[ -z "$notebook_id" ]]; then
        log_error "Failed to create notebook"
        exit 1
    fi
    
    log_success "Created notebook: $notebook_id"
    
    # Add all files as sources
    local source_ids=()
    for file in "${files_to_upload[@]}"; do
        local filename=$(basename "$file")
        log_info "Adding $filename to notebook..."
        local source_id=$(nlm source add "$notebook_id" --file "$file" 2>/dev/null | grep -oE '[a-f0-9-]{36}' | head -1)
        
        if [[ -n "$source_id" ]]; then
            source_ids+=("$source_id")
            log_success "Added: $filename (source: $source_id)"
        else
            log_warn "Could not get source ID for $filename"
        fi
    done
    
    # Save to config
    set_config '.notebook.id' "$notebook_id"
    set_config '.notebook.title' "$NOTEBOOK_TITLE"
    
    if [[ "$BATCH_MODE" == true ]]; then
        # Save all source IDs as array
        if command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
            local tmp=$(mktemp)
            jq ".notebook.source_ids = $(printf '%s\n' "${source_ids[@]}" | jq -R . | jq -s .)" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
        fi
    else
        set_config '.notebook.source_id' "${source_ids[0]:-}"
    fi
    
    # Save hash
    local hash=$(compute_hash)
    set_config '.last_sync.hash' "$hash"
    set_config '.last_sync.timestamp' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    
    log_success "Notebook created and synced"
    echo ""
    echo "NOTEBOOK CREATED"
    echo "================"
    echo "Notebook ID: $notebook_id"
    echo "Title: $NOTEBOOK_TITLE"
    echo "Files uploaded: ${#files_to_upload[@]}"
    for file in "${files_to_upload[@]}"; do
        echo "  ✓ $(basename $file)"
    done
    echo "Config saved to: $CONFIG_FILE"
}

# Update existing notebook
update_notebook() {
    local notebook_id=$(get_config '.notebook.id')
    local source_id=$(get_config '.notebook.source_id')
    
    if [[ -z "$notebook_id" ]]; then
        log_error "No notebook ID in config. Run with --create first"
        exit 1
    fi
    
    if [[ ! -f "$MERGED_FILE" ]]; then
        log_error "Merged file not found: $MERGED_FILE"
        exit 1
    fi
    
    # Check if update needed
    local current_hash=$(compute_hash)
    local last_hash=$(get_config '.last_sync.hash')
    
    if [[ "$FORCE" != true ]] && [[ "$current_hash" == "$last_hash" ]]; then
        log_success "Already in sync (hashes match)"
        echo ""
        echo "SYNC STATUS"
        echo "==========="
        echo "Status: IN SYNC"
        echo "Hash: $current_hash"
        echo "Last sync: $(get_config '.last_sync.timestamp')"
        exit 0
    fi
    
    log_info "Updating notebook: $notebook_id"
    log_info "Local hash: $current_hash"
    log_info "Last sync hash: $last_hash"
    
    # Remove old source and add new one
    # (NotebookLM doesn't have a direct update, so we re-add)
    if [[ -n "$source_id" ]]; then
        log_info "Removing old source..."
        nlm source delete "$notebook_id" "$source_id" --confirm 2>/dev/null || true
    fi
    
    log_info "Adding updated source..."
    local new_source_id=$(nlm source add "$notebook_id" --file "$MERGED_FILE" 2>/dev/null | grep -oE '[a-f0-9-]{36}' | head -1)
    
    # Update config
    set_config '.notebook.source_id' "${new_source_id:-unknown}"
    set_config '.last_sync.hash' "$current_hash"
    set_config '.last_sync.timestamp' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    
    log_success "Notebook updated"
    echo ""
    echo "SYNC COMPLETE"
    echo "============="
    echo "Notebook: $(get_config '.notebook.title')"
    echo "Notebook ID: $notebook_id"
    echo "New Source ID: ${new_source_id:-unknown}"
    echo "Hash: $current_hash"
}

# Check sync status
check_status() {
    local notebook_id=$(get_config '.notebook.id')
    local source_id=$(get_config '.notebook.source_id')
    local title=$(get_config '.notebook.title')
    local last_sync=$(get_config '.last_sync.timestamp')
    local last_hash=$(get_config '.last_sync.hash')
    local current_hash=$(compute_hash)
    
    echo ""
    echo "SYNC STATUS"
    echo "==========="
    
    if [[ -z "$notebook_id" ]]; then
        echo "Status: NOT CONFIGURED"
        echo ""
        echo "Run with --create to set up sync"
        exit 0
    fi
    
    echo "Notebook: $title"
    echo "Notebook ID: $notebook_id"
    echo "Source ID: ${source_id:-unknown}"
    echo ""
    echo "Last Sync: ${last_sync:-never}"
    echo "Local Hash: $current_hash"
    echo "Remote Hash: ${last_hash:-unknown}"
    
    if [[ "$current_hash" == "$last_hash" ]]; then
        echo ""
        echo "Status: ${GREEN}IN SYNC${NC}"
    else
        echo ""
        echo "Status: ${YELLOW}OUT OF SYNC${NC}"
        echo "Run with --update to sync changes"
    fi
    
    # Check merged file
    if [[ -f "$MERGED_FILE" ]]; then
        local size=$(stat -f%z "$MERGED_FILE" 2>/dev/null || stat -c%s "$MERGED_FILE" 2>/dev/null || echo "0")
        echo ""
        echo "Merged File: $MERGED_FILE"
        echo "Size: $size bytes"
    else
        echo ""
        echo "Merged File: ${RED}NOT FOUND${NC}"
        echo "Run merge-specs.sh first"
    fi
}

# Main
main() {
    parse_args "$@"
    
    case "$ACTION" in
        create)
            check_nlm && create_notebook
            ;;
        update)
            check_nlm && update_notebook
            ;;
        status)
            check_status
            ;;
        "")
            log_error "No action specified. Use --create, --update, or --status"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
