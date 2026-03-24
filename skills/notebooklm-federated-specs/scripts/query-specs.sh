#!/bin/bash
set -e

# query-specs.sh
# Query NotebookLM notebook for spec information
#
# Usage: bash query-specs.sh [OPTIONS] "query text"
#
# Options:
#   --notebook-id ID       Notebook ID (uses config if not specified)
#   --source FILE          Limit query to specific source file
#   --context TEXT         Additional context for the query
#   --conversation ID      Continue existing conversation
#   --save-conversation    Save conversation ID for follow-up
#   -c, --config FILE      Config file path
#   -v, --verbose          Verbose output
#   -h, --help             Show help

CONFIG_FILE=".notebooklm-specs.json"
NOTEBOOK_ID=""
SOURCE_FILTER=""
CONTEXT=""
CONVERSATION_ID=""
SAVE_CONVERSATION=false
VERBOSE=false
QUERY=""

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --notebook-id)
                NOTEBOOK_ID="$2"
                shift 2
                ;;
            --source)
                SOURCE_FILTER="$2"
                shift 2
                ;;
            --context)
                CONTEXT="$2"
                shift 2
                ;;
            --conversation)
                CONVERSATION_ID="$2"
                shift 2
                ;;
            --save-conversation)
                SAVE_CONVERSATION=true
                shift
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
            -*)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
            *)
                if [[ -z "$QUERY" ]]; then
                    QUERY="$1"
                else
                    QUERY="$QUERY $1"
                fi
                shift
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
Usage: bash query-specs.sh [OPTIONS] "query text"

Query NotebookLM notebook for spec information.

Options:
  --notebook-id ID       Notebook ID (uses config if not specified)
  --source FILE          Limit query to specific source file
  --context TEXT         Additional context for the query
  --conversation ID      Continue existing conversation
  --save-conversation    Save conversation ID for follow-up
  -c, --config FILE      Config file path
  -v, --verbose          Verbose output
  -h, --help             Show help

Examples:
  bash query-specs.sh "What are the API rate limits?"
  bash query-specs.sh --source auth.md "How does OAuth work?"
  bash query-specs.sh --context "Adding new feature" "What specs apply?"
  bash query-specs.sh --conversation "abc-123" "Tell me more about that"
EOF
}

log_info() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[INFO] $1" >&2
    fi
}

log_error() {
    echo "[ERROR] $1" >&2
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
    
    if command -v jq >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
        local tmp=$(mktemp)
        jq "$key = \"$value\"" "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
    fi
}

main() {
    parse_args "$@"
    
    if [[ -z "$QUERY" ]]; then
        log_error "No query provided"
        show_help
        exit 1
    fi
    
    # Get notebook ID from config if not specified
    if [[ -z "$NOTEBOOK_ID" ]]; then
        NOTEBOOK_ID=$(get_config '.notebook.id')
    fi
    
    if [[ -z "$NOTEBOOK_ID" ]]; then
        log_error "No notebook ID. Specify --notebook-id or run sync-notebook.sh --create first"
        exit 1
    fi
    
    log_info "Notebook ID: $NOTEBOOK_ID"
    log_info "Query: $QUERY"
    
    # Build full query with context
    local full_query="$QUERY"
    
    if [[ -n "$SOURCE_FILTER" ]]; then
        full_query="Looking at the $SOURCE_FILTER spec: $full_query"
        log_info "Source filter: $SOURCE_FILTER"
    fi
    
    if [[ -n "$CONTEXT" ]]; then
        full_query="Context: $CONTEXT. Question: $full_query"
        log_info "Context: $CONTEXT"
    fi
    
    # Check if nlm CLI is available
    if ! command -v nlm >/dev/null 2>&1; then
        log_error "nlm CLI not found. Install with: npm install -g notebooklm-mcp"
        echo ""
        echo "Alternatively, use the MCP tool directly:"
        echo ""
        echo "notebooklm_notebook_query("
        echo "    notebook_id=\"$NOTEBOOK_ID\","
        echo "    query=\"$full_query\""
        [[ -n "$CONVERSATION_ID" ]] && echo "    conversation_id=\"$CONVERSATION_ID\""
        echo ")"
        exit 1
    fi
    
    # Execute query
    log_info "Executing query..."
    
    local nlm_args=()
    nlm_args+=("query" "$NOTEBOOK_ID" "$full_query")
    
    if [[ -n "$CONVERSATION_ID" ]]; then
        nlm_args+=("--conversation" "$CONVERSATION_ID")
    fi
    
    local result=$(nlm "${nlm_args[@]}" 2>/dev/null)
    
    # Save conversation ID if requested
    if [[ "$SAVE_CONVERSATION" == true ]]; then
        local conv_id=$(echo "$result" | grep -oE 'conversation[_-]?id["\s:]+[a-f0-9-]+' | grep -oE '[a-f0-9-]{36}' | head -1)
        if [[ -n "$conv_id" ]]; then
            set_config '.last_conversation.id' "$conv_id"
            set_config '.last_conversation.timestamp' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
            log_info "Saved conversation ID: $conv_id"
        fi
    fi
    
    echo ""
    echo "$result"
}

main "$@"
