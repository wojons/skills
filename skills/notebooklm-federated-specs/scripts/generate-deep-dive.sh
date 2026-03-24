#!/bin/bash
set -e

# generate-deep-dive.sh
# Generate Sherlock-style deep dive analysis video
#
# Usage: bash generate-deep-dive.sh [OPTIONS]
#
# Options:
#   --video                Generate deep dive video
#   --full                 Generate full analysis (video + report)
#   --focus AREA           Focus area: design-problems, security, scalability, all
#   --questions LIST       Comma-separated analysis questions
#   --notebook-id ID       Notebook ID (uses config if not specified)
#   -c, --config FILE      Config file path
#   -v, --verbose          Verbose output
#   -h, --help             Show help

CONFIG_FILE=".notebooklm-specs.json"
NOTEBOOK_ID=""
VIDEO=false
FULL=false
FOCUS="design-problems"
QUESTIONS=""
VERBOSE=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --video)
                VIDEO=true
                shift
                ;;
            --full)
                FULL=true
                VIDEO=true
                shift
                ;;
            --focus)
                FOCUS="$2"
                shift 2
                ;;
            --questions)
                QUESTIONS="$2"
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
Usage: bash generate-deep-dive.sh [OPTIONS]

Generate Sherlock-style deep dive analysis video for design problems.

Options:
  --video                Generate deep dive video
  --full                 Generate full analysis (video + report)
  --focus AREA           Focus area: design-problems, security, scalability, all
  --questions LIST       Comma-separated analysis questions
  --notebook-id ID       Notebook ID (uses config if not specified)
  -c, --config FILE      Config file path
  -v, --verbose          Verbose output
  -h, --help             Show help

Focus Areas:
  design-problems  - Hidden complexity, assumptions, contradictions (default)
  security         - Vulnerabilities, attack vectors, security risks
  scalability      - Performance limits, bottlenecks, scaling issues
  all              - Comprehensive analysis of all areas

Default Questions:
  - What are the hidden complexities not immediately obvious?
  - What assumptions could fail?
  - Where are design contradictions?
  - What edge cases are not covered?
  - What security vulnerabilities might exist?
  - Where will this break under scale?

Examples:
  bash generate-deep-dive.sh --video
  bash generate-deep-dive.sh --full --focus security
  bash generate-deep-dive.sh --video --questions "complexity,assumptions,edge cases"
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
    local focus="$1"
    local custom="$2"
    
    if [[ -n "$custom" ]]; then
        echo "Analyze this system with focus on: $custom. Apply detective-like reasoning to find issues that might not be obvious from a surface reading. Be thorough and critical."
        return
    fi
    
    case "$focus" in
        design-problems)
            echo "Analyze this system design like a detective. Find: 
1. Hidden complexities not immediately obvious
2. Implicit assumptions that could fail
3. Design contradictions or tensions
4. Edge cases not covered by the specs
5. Areas where the spec is ambiguous or incomplete

Be thorough and critical. Think about what could go wrong." ;;
        security)
            echo "Perform a security deep dive on this system. Find:
1. Authentication and authorization vulnerabilities
2. Data exposure risks
3. Input validation gaps
4. Attack vectors and exploitation paths
5. Security assumptions that could fail

Think like a security researcher looking for weaknesses." ;;
        scalability)
            echo "Analyze the scalability of this system. Find:
1. Performance bottlenecks
2. Single points of failure
3. Resource limits that will be hit
4. Areas that won't scale under load
5. Missing scaling strategies

Think about what happens at 10x, 100x, 1000x scale." ;;
        all)
            echo "Perform a comprehensive analysis of this system covering:
1. Hidden complexities and design problems
2. Security vulnerabilities and attack vectors
3. Scalability limits and performance issues
4. Implicit assumptions that could fail
5. Edge cases not covered
6. Design contradictions

Be extremely thorough. Think like a detective, security researcher, and scalability engineer." ;;
        *)
            echo "Analyze this system deeply and find potential issues, risks, and areas of concern."
            ;;
    esac
}

main() {
    parse_args "$@"
    
    if [[ "$VIDEO" != true ]]; then
        log_error "Specify --video or --full"
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
    
    local focus_prompt=$(get_focus_prompt "$FOCUS" "$QUESTIONS")
    
    echo ""
    echo "DEEP DIVE ANALYSIS"
    echo "=================="
    echo "Notebook: $NOTEBOOK_ID"
    echo "Focus: $FOCUS"
    echo ""
    
    # Generate video command
    cat << EOF

NOTEBOOKLM MCP COMMAND - DEEP DIVE VIDEO
========================================
notebooklm_studio_create({
  notebook_id: "$NOTEBOOK_ID",
  artifact_type: "video",
  video_format: "explainer",
  visual_style: "whiteboard",
  focus_prompt: "$(echo "$focus_prompt" | tr '\n' ' ')",
  confirm: true
})

EOF
    
    if [[ "$FULL" == true ]]; then
        # Also generate report
        cat << EOF

NOTEBOOKLM MCP COMMAND - ANALYSIS REPORT
=========================================
notebooklm_studio_create({
  notebook_id: "$NOTEBOOK_ID",
  artifact_type: "report",
  report_format: "Briefing Doc",
  focus_prompt: "Deep dive analysis report: $(echo "$focus_prompt" | tr '\n' ' ')",
  confirm: true
})

EOF
    fi
    
    log_success "Deep dive generation commands ready"
    
    echo ""
    echo "ANALYSIS FOCUS AREAS"
    echo "===================="
    echo "The deep dive will investigate:"
    echo ""
    echo "  🔍 Hidden Complexity"
    echo "     - What's not immediately obvious?"
    echo "     - What interactions are underspecified?"
    echo ""
    echo "  ⚠️  Implicit Assumptions"
    echo "     - What does the system assume?"
    echo "     - Which assumptions could fail?"
    echo ""
    echo "  ❌ Design Contradictions"
    echo "     - Where do requirements conflict?"
    echo "     - What tensions exist in the design?"
    echo ""
    echo "  🔓 Security Concerns"
    echo "     - What attack vectors exist?"
    echo "     - What data could be exposed?"
    echo ""
    echo "  📊 Scalability Limits"
    echo "     - Where will performance degrade?"
    echo "     - What won't scale?"
    echo ""
    echo "NEXT STEPS"
    echo "=========="
    echo "1. Execute the MCP command above"
    echo "2. Watch the generated video"
    echo "3. Address identified issues in specs"
    echo "4. Re-run after fixes to verify"
}

main "$@"
