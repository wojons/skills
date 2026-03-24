#!/bin/bash
set -e

# generate-risk-assessment.sh
# Generate risk assessment video and report
#
# Usage: bash generate-risk-assessment.sh [OPTIONS]
#
# Options:
#   --video                Generate risk assessment video
#   --report               Generate risk report
#   --both                 Generate both video and report
#   --categories LIST      Risk categories to analyze
#   --notebook-id ID       Notebook ID (uses config if not specified)
#   -c, --config FILE      Config file path
#   -v, --verbose          Verbose output
#   -h, --help             Show help

CONFIG_FILE=".notebooklm-specs.json"
NOTEBOOK_ID=""
VIDEO=false
REPORT=false
CATEGORIES=""
VERBOSE=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --video)
                VIDEO=true
                shift
                ;;
            --report)
                REPORT=true
                shift
                ;;
            --both)
                VIDEO=true
                REPORT=true
                shift
                ;;
            --categories)
                CATEGORIES="$2"
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
Usage: bash generate-risk-assessment.sh [OPTIONS]

Generate risk assessment video and report for the system specs.

Options:
  --video                Generate risk assessment video
  --report               Generate risk report
  --both                 Generate both video and report
  --categories LIST      Risk categories to analyze (comma-separated)
  --notebook-id ID       Notebook ID (uses config if not specified)
  -c, --config FILE      Config file path
  -v, --verbose          Verbose output
  -h, --help             Show help

Risk Categories:
  critical      - System-breaking failures
  security      - Security vulnerabilities
  data          - Data loss/corruption risks
  performance   - Performance degradation risks
  dependency    - External dependency failures
  operational   - Operational and maintenance risks
  compliance    - Regulatory and compliance risks

Default: All categories

Examples:
  bash generate-risk-assessment.sh --video
  bash generate-risk-assessment.sh --both
  bash generate-risk-assessment.sh --report --categories "critical,security"
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
    local categories="$1"
    
    local base_prompt="Identify and analyze all risks in this system. For each risk:
1. Describe the risk clearly
2. Explain what could go wrong
3. Identify the impact if it occurs
4. Rate severity: Critical (system failure), High (major feature broken), Medium (degraded experience), Low (minor issue)
5. Suggest mitigation strategies"

    if [[ -n "$categories" ]]; then
        echo "$base_prompt

Focus on these risk categories: $categories"
    else
        echo "$base_prompt

Analyze these risk categories:
- Critical failures (system-breaking)
- Security vulnerabilities (attack vectors, data exposure)
- Data risks (loss, corruption, inconsistency)
- Performance risks (bottlenecks, scalability limits)
- Dependency risks (external service failures)
- Operational risks (deployment, monitoring, maintenance)
- Compliance risks (regulatory, privacy)"
    fi
}

main() {
    parse_args "$@"
    
    if [[ "$VIDEO" != true ]] && [[ "$REPORT" != true ]]; then
        log_error "Specify --video, --report, or --both"
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
    
    local focus_prompt=$(get_focus_prompt "$CATEGORIES")
    
    echo ""
    echo "RISK ASSESSMENT"
    echo "==============="
    echo "Notebook: $NOTEBOOK_ID"
    echo ""
    
    if [[ "$VIDEO" == true ]]; then
        cat << EOF

NOTEBOOKLM MCP COMMAND - RISK VIDEO
===================================
notebooklm_studio_create({
  notebook_id: "$NOTEBOOK_ID",
  artifact_type: "video",
  video_format: "explainer",
  visual_style: "professional",
  focus_prompt: "$(echo "$focus_prompt" | tr '\n' ' ')",
  confirm: true
})

EOF
        log_success "Risk video command ready"
    fi
    
    if [[ "$REPORT" == true ]]; then
        cat << EOF

NOTEBOOKLM MCP COMMAND - RISK REPORT
====================================
notebooklm_studio_create({
  notebook_id: "$NOTEBOOK_ID",
  artifact_type: "report",
  report_format: "Briefing Doc",
  focus_prompt: "Risk Assessment Report: $(echo "$focus_prompt" | tr '\n' ' ')",
  confirm: true
})

EOF
        log_success "Risk report command ready"
    fi
    
    echo ""
    echo "RISK CATEGORIES ANALYZED"
    echo "========================"
    echo ""
    echo "  🔴 CRITICAL - System-breaking failures"
    echo "     • Complete service outages"
    echo "     • Data loss scenarios"
    echo "     • Security breaches"
    echo ""
    echo "  🟠 HIGH - Major feature failures"
    echo "     • Core functionality broken"
    echo "     • Significant user impact"
    echo "     • Revenue-affecting issues"
    echo ""
    echo "  🟡 MEDIUM - Degraded experience"
    echo "     • Partial functionality loss"
    echo "     • Performance degradation"
    echo "     • Workaround available"
    echo ""
    echo "  🟢 LOW - Minor issues"
    echo "     • Cosmetic problems"
    echo "     • Edge case failures"
    echo "     • Low user impact"
    echo ""
    echo "NEXT STEPS"
    echo "=========="
    echo "1. Execute the MCP commands above"
    echo "2. Review identified risks"
    echo "3. Prioritize critical/high risks for mitigation"
    echo "4. Update specs with mitigation strategies"
    echo "5. Re-run after changes to verify risk reduction"
}

main "$@"
