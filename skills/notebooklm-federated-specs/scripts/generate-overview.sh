#!/bin/bash
set -e

# generate-overview.sh
# Generate audio/video overview for human confirmation
#
# Usage: bash generate-overview.sh [OPTIONS]
#
# Options:
#   --audio                Generate audio overview
#   --video                Generate video overview
#   --all                  Generate both audio and video
#   --mode MODE            Mode: confirmation (default), summary, walkthrough
#   --style STYLE          Video style: explainer, brief, cinematic
#   --length LENGTH        Audio length: short, default, long
#   --notebook-id ID       Notebook ID (uses config if not specified)
#   -c, --config FILE      Config file path
#   -v, --verbose          Verbose output
#   -h, --help             Show help

CONFIG_FILE=".notebooklm-specs.json"
NOTEBOOK_ID=""
AUDIO=false
VIDEO=false
MODE="confirmation"
VIDEO_STYLE="explainer"
AUDIO_LENGTH="default"
VERBOSE=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --audio)
                AUDIO=true
                shift
                ;;
            --video)
                VIDEO=true
                shift
                ;;
            --all)
                AUDIO=true
                VIDEO=true
                shift
                ;;
            --mode)
                MODE="$2"
                shift 2
                ;;
            --style)
                VIDEO_STYLE="$2"
                shift 2
                ;;
            --length)
                AUDIO_LENGTH="$2"
                shift 2
                ;;
            --notebook-id)
                NOTEBOOK_ID="$2"
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
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
Usage: bash generate-overview.sh [OPTIONS]

Generate audio/video overview for human confirmation of specs.

Options:
  --audio                Generate audio overview
  --video                Generate video overview
  --all                  Generate both audio and video
  --mode MODE            Mode: confirmation (default), summary, walkthrough
  --style STYLE          Video style: explainer, brief, cinematic
  --length LENGTH        Audio length: short, default, long
  --notebook-id ID       Notebook ID (uses config if not specified)
  -c, --config FILE      Config file path
  -v, --verbose          Verbose output
  -h, --help             Show help

Modes:
  confirmation  - "Here's what we're building" - for human approval
  summary       - Quick overview of the system
  walkthrough   - Detailed walkthrough of features and flows

Examples:
  bash generate-overview.sh --audio --mode confirmation
  bash generate-overview.sh --video --style explainer
  bash generate-overview.sh --all
EOF
}

log_info() { [[ "$VERBOSE" == true ]] && echo "[INFO] $1" >&2; }
log_success() { echo -e "\033[0;32m[OK]\033[0m $1" >&2; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }

get_config() {
    [[ -f "$CONFIG_FILE" ]] && command -v jq >/dev/null 2>&1 && \
        jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null
}

get_focus_prompt() {
    local mode="$1"
    case "$mode" in
        confirmation)
            echo "Explain what this system does, the problems it solves, and the key design decisions. Help the listener confirm this matches their expectations. Be clear about: core features, architecture choices, and important tradeoffs made."
            ;;
        summary)
            echo "Provide a concise overview of this system. Cover: purpose, main components, and how they work together."
            ;;
        walkthrough)
            echo "Walk through this system step by step. Explain each major feature, user flow, and how the components interact. Be detailed and thorough."
            ;;
        *)
            echo "Explain this system clearly and comprehensively."
            ;;
    esac
}

generate_audio() {
    local notebook_id="$1"
    local focus_prompt="$2"
    
    log_info "Generating audio overview..."
    
    cat << EOF

NOTEBOOKLM MCP COMMAND - AUDIO OVERVIEW
=======================================
notebooklm_studio_create({
  notebook_id: "$notebook_id",
  artifact_type: "audio",
  audio_format: "deep_dive",
  audio_length: "$AUDIO_LENGTH",
  focus_prompt: "$focus_prompt",
  confirm: true
})

EOF
    
    log_success "Audio generation command ready"
}

generate_video() {
    local notebook_id="$1"
    local focus_prompt="$2"
    
    log_info "Generating video overview..."
    
    cat << EOF

NOTEBOOKLM MCP COMMAND - VIDEO OVERVIEW
=======================================
notebooklm_studio_create({
  notebook_id: "$notebook_id",
  artifact_type: "video",
  video_format: "$( [[ "$VIDEO_STYLE" == "brief" ]] && echo "brief" || echo "explainer" )",
  visual_style: "$VIDEO_STYLE",
  focus_prompt: "$focus_prompt",
  confirm: true
})

EOF
    
    log_success "Video generation command ready"
}

main() {
    parse_args "$@"
    
    if [[ "$AUDIO" != true ]] && [[ "$VIDEO" != true ]]; then
        log_error "Specify --audio, --video, or --all"
        show_help
        exit 1
    fi
    
    # Get notebook ID
    if [[ -z "$NOTEBOOK_ID" ]]; then
        NOTEBOOK_ID=$(get_config '.notebook.id')
    fi
    
    if [[ -z "$NOTEBOOK_ID" ]]; then
        log_error "No notebook ID. Specify --notebook-id or run sync-notebook.sh first"
        exit 1
    fi
    
    local focus_prompt=$(get_focus_prompt "$MODE")
    
    echo ""
    echo "GENERATING OVERVIEW"
    echo "==================="
    echo "Notebook: $NOTEBOOK_ID"
    echo "Mode: $MODE"
    echo ""
    
    if [[ "$AUDIO" == true ]]; then
        generate_audio "$NOTEBOOK_ID" "$focus_prompt"
    fi
    
    if [[ "$VIDEO" == true ]]; then
        generate_video "$NOTEBOOK_ID" "$focus_prompt"
    fi
    
    echo ""
    echo "NEXT STEPS"
    echo "=========="
    echo "1. Execute the MCP commands above to generate media"
    echo "2. Check status: notebooklm_studio_status({ notebook_id: \"$NOTEBOOK_ID\" })"
    echo "3. Download when ready: notebooklm_download_artifact(...)"
    echo "4. Share with stakeholders for confirmation"
}

main "$@"
