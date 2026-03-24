#!/bin/bash
set -e

# research-question.sh
# Create on-demand research notebook for user questions
#
# Usage: bash research-question.sh --question "QUESTION" [OPTIONS]
#
# Options:
#   --question TEXT        The question to research (required)
#   --sources LIST         Additional sources to include (comma-separated URLs/paths)
#   --audio                Generate audio summary
#   --video                Generate video explainer
#   --share                Generate public share link
#   --title TITLE          Custom notebook title
#   --timeout SECONDS      Timeout for operations (default: 120)
#   -v, --verbose          Verbose output
#   -h, --help             Show help

QUESTION=""
SOURCES=""
AUDIO=false
VIDEO=false
SHARE=false
TITLE=""
TIMEOUT=120
VERBOSE=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --question)
                QUESTION="$2"
                shift 2
                ;;
            --sources)
                SOURCES="$2"
                shift 2
                ;;
            --audio)
                AUDIO=true
                shift
                ;;
            --video)
                VIDEO=true
                shift
                ;;
            --share)
                SHARE=true
                shift
                ;;
            --title)
                TITLE="$2"
                shift 2
                ;;
            --timeout)
                TIMEOUT="$2"
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
Usage: bash research-question.sh --question "QUESTION" [OPTIONS]

Create an on-demand research notebook to answer user questions.
The notebook is separate from main specs and can be shared.

Options:
  --question TEXT        The question to research (required)
  --sources LIST         Additional sources (comma-separated URLs/paths)
  --audio                Generate audio summary of findings
  --video                Generate video explainer
  --share                Generate public share link
  --title TITLE          Custom notebook title
  --timeout SECONDS      Timeout for operations (default: 120)
  -v, --verbose          Verbose output
  -h, --help             Show help

Examples:
  bash research-question.sh --question "What's the difference between X and Y?"
  bash research-question.sh --question "Compare auth approaches" --audio --video
  bash research-question.sh --question "Tradeoffs?" --sources "spec.md,https://example.com" --share
EOF
}

log_info() { [[ "$VERBOSE" == true ]] && echo "[INFO] $1" >&2; }
log_success() { echo -e "\033[0;32m[OK]\033[0m $1" >&2; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }

main() {
    parse_args "$@"
    
    if [[ -z "$QUESTION" ]]; then
        log_error "Question is required. Use --question"
        show_help
        exit 1
    fi
    
    if [[ -z "$TITLE" ]]; then
        # Generate title from question (first 50 chars)
        TITLE="Research: $(echo "$QUESTION" | cut -c1-50)..."
    fi
    
    echo ""
    echo "ON-DEMAND RESEARCH"
    echo "=================="
    echo "Question: $QUESTION"
    echo "Title: $TITLE"
    echo ""
    
    # Step 1: Create notebook
    cat << EOF

STEP 1: CREATE RESEARCH NOTEBOOK
================================
notebooklm_notebook_create({ title: "$TITLE" })

// Save the returned notebook_id for subsequent steps

EOF
    
    # Step 2: Add sources
    echo ""
    echo "STEP 2: ADD SOURCES"
    echo "==================="
    echo ""
    
    if [[ -n "$SOURCES" ]]; then
        IFS=',' read -ra SOURCE_ARRAY <<< "$SOURCES"
        for source in "${SOURCE_ARRAY[@]}"; do
            source=$(echo "$source" | xargs)  # trim whitespace
            if [[ "$source" == http* ]]; then
                cat << EOF
notebooklm_source_add({
  notebook_id: "<notebook_id>",
  source_type: "url",
  url: "$source",
  wait: true,
  wait_timeout: $TIMEOUT
})

EOF
            elif [[ -f "$source" ]]; then
                cat << EOF
notebooklm_source_add({
  notebook_id: "<notebook_id>",
  source_type: "file",
  file_path: "$source",
  wait: true,
  wait_timeout: $TIMEOUT
})

EOF
            fi
        done
    fi
    
    # Step 3: Generate analysis
    if [[ "$AUDIO" == true ]] || [[ "$VIDEO" == true ]]; then
        echo ""
        echo "STEP 3: GENERATE ANALYSIS MEDIA"
        echo "================================"
        echo ""
        
        local focus_prompt="Research this question: $QUESTION. Provide a clear, comprehensive answer with supporting evidence from the sources. Explain the key points and any important nuances."
        
        if [[ "$AUDIO" == true ]]; then
            cat << EOF
notebooklm_studio_create({
  notebook_id: "<notebook_id>",
  artifact_type: "audio",
  audio_format: "deep_dive",
  focus_prompt: "$focus_prompt",
  confirm: true
})

EOF
        fi
        
        if [[ "$VIDEO" == true ]]; then
            cat << EOF
notebooklm_studio_create({
  notebook_id: "<notebook_id>",
  artifact_type: "video",
  video_format: "explainer",
  visual_style: "professional",
  focus_prompt: "$focus_prompt",
  confirm: true
})

EOF
        fi
    fi
    
    # Step 4: Share
    if [[ "$SHARE" == true ]]; then
        echo ""
        echo "STEP 4: GENERATE SHARE LINK"
        echo "==========================="
        echo ""
        cat << EOF
notebooklm_notebook_share_public({
  notebook_id: "<notebook_id>",
  is_public: true
})

// Returns: public_link for user to explore

EOF
    fi
    
    echo ""
    echo "WORKFLOW SUMMARY"
    echo "================"
    echo ""
    echo "1. Create new notebook for this research question"
    echo "2. Add relevant sources (specs + external references)"
    echo "3. Generate audio/video if requested"
    echo "4. Share link with user for independent exploration"
    echo ""
    echo "This keeps research separate from main spec notebook."
    echo ""
    echo "RATE LIMIT AWARENESS"
    echo "===================="
    echo "• NotebookLM has rate limits on API calls"
    echo "• If you receive rate limit errors, wait before retrying:"
    echo "  - 429 Too Many Requests: Wait 60 seconds, then retry"
    echo "  - 503 Service Unavailable: Wait 30 seconds, then retry"
    echo "• Use exponential backoff for repeated failures"
    echo "• Timeout for operations: ${TIMEOUT}s"
}

main "$@"
