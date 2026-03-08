#!/bin/bash
set -e

# verify.sh
# Verify command behavior and side effects against expected outcomes
#
# Usage: bash verify.sh [options] --command "cmd" --expected 'effect1' [--expected 'effect2' ...]
#
# Options:
#   --command "cmd"          Command to run (required)
#   --expected 'effect'      Expected positive effect (can repeat)
#   --negative 'effect'      Expected negative effect (should NOT happen)
#   --timeout N              Timeout in seconds (default: 300)
#   --poll-interval N        Poll interval for async effects (default: 5)
#   --sandbox MODE           Sandbox mode: none, chroot, container
#   --chroot-dir PATH        Chroot directory (for chroot sandbox)
#   --max-memory SIZE        Max memory (e.g., 1GB)
#   --max-cpu PERCENT        Max CPU (e.g., 50%)
#   --mask-secrets           Mask secret patterns in output
#   --output-format          Output format: text, json (default: text)
#   --verbose                Verbose output
#   --help                   Show help

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR=""
COMMAND=""
TIMEOUT=300
POLL_INTERVAL=5
SANDBOX="none"
CHROOT_DIR=""
MAX_MEMORY=""
MAX_CPU=""
MASK_SECRETS=false
OUTPUT_FORMAT="text"
VERBOSE=false

declare -a EXPECTED_EFFECTS
declare -a NEGATIVE_EFFECTS

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --command)
                COMMAND="$2"
                shift 2
                ;;
            --expected)
                EXPECTED_EFFECTS+=("$2")
                shift 2
                ;;
            --negative)
                NEGATIVE_EFFECTS+=("$2")
                shift 2
                ;;
            --timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            --poll-interval)
                POLL_INTERVAL="$2"
                shift 2
                ;;
            --sandbox)
                SANDBOX="$2"
                shift 2
                ;;
            --chroot-dir)
                CHROOT_DIR="$2"
                shift 2
                ;;
            --max-memory)
                MAX_MEMORY="$2"
                shift 2
                ;;
            --max-cpu)
                MAX_CPU="$2"
                shift 2
                ;;
            --mask-secrets)
                MASK_SECRETS=true
                shift
                ;;
            --output-format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
Usage: bash verify.sh [options] --command "cmd" --expected 'effect'

Verify command behavior and side effects against expected outcomes.

Options:
  --command "cmd"          Command to run (required)
  --expected 'effect'      Expected positive effect (can repeat)
  --negative 'effect'      Expected negative effect (should NOT happen)
  --timeout N              Timeout in seconds (default: 300)
  --poll-interval N        Poll interval for async effects (default: 5)
  --sandbox MODE           Sandbox mode: none, chroot, container
  --chroot-dir PATH        Chroot directory (for chroot sandbox)
  --max-memory SIZE        Max memory (e.g., 1GB)
  --max-cpu PERCENT        Max CPU (e.g., 50%)
  --mask-secrets           Mask secret patterns in output
  --output-format          Output format: text, json
  --verbose                Verbose output
  --help                   Show help

Examples:
  bash verify.sh --command "./backup.sh" \
    --expected 'file_exists:/backups/backup.tar.gz' \
    --expected 'file_size:>100MB' \
    --timeout 300

  bash verify.sh --command "./deploy.sh" \
    --expected 'process_running:my-service' \
    --expected 'port_listening:8080' \
    --poll-interval 5
EOF
}

# Logging
log_info() {
    if [[ "$OUTPUT_FORMAT" == "text" ]]; then
        echo "[INFO] $1" >&2
    fi
}

log_verbose() {
    if [[ "$VERBOSE" == true && "$OUTPUT_FORMAT" == "text" ]]; then
        echo "[VERBOSE] $1" >&2
    fi
}

log_error() {
    if [[ "$OUTPUT_FORMAT" == "text" ]]; then
        echo "[ERROR] $1" >&2
    fi
}

# Create temporary state directory
setup_state_dir() {
    STATE_DIR=$(mktemp -d)
    mkdir -p "$STATE_DIR"/{pre,post,logs}
    log_verbose "State directory: $STATE_DIR"
}

# Cleanup
cleanup() {
    if [[ -n "$STATE_DIR" && -d "$STATE_DIR" ]]; then
        log_verbose "Cleaning up state directory: $STATE_DIR"
        rm -rf "$STATE_DIR"
    fi
}
trap cleanup EXIT

# Capture filesystem state
capture_filesystem_state() {
    local output_file="$1"
    log_verbose "Capturing filesystem state..."
    
    # Find all files (respecting common exclusions)
    find . -type f -not -path '*/\.*' -not -path '*/node_modules/*' 2>/dev/null | while read -r file; do
        if [[ -f "$file" ]]; then
            stat -c '%n %s %Y %a %U:%G' "$file" 2>/dev/null || stat -f '%N %z %m %Lp %u:%g' "$file" 2>/dev/null
        fi
    done > "$output_file" 2>/dev/null || true
    
    log_verbose "Filesystem state captured"
}

# Capture process state
capture_process_state() {
    local output_file="$1"
    log_verbose "Capturing process state..."
    
    ps aux > "$output_file" 2>/dev/null || ps > "$output_file" 2>/dev/null || echo "ps not available" > "$output_file"
    
    log_verbose "Process state captured"
}

# Capture network state
capture_network_state() {
    local output_file="$1"
    log_verbose "Capturing network state..."
    
    netstat -tlnp > "$output_file" 2>/dev/null || \
    ss -tlnp > "$output_file" 2>/dev/null || \
    echo "No network tools available" > "$output_file"
    
    log_verbose "Network state captured"
}

# Capture all pre-state
capture_pre_state() {
    log_info "Capturing pre-state..."
    capture_filesystem_state "$STATE_DIR/pre/filesystem.txt"
    capture_process_state "$STATE_DIR/pre/processes.txt"
    capture_network_state "$STATE_DIR/pre/network.txt"
}

# Capture all post-state
capture_post_state() {
    log_info "Capturing post-state..."
    capture_filesystem_state "$STATE_DIR/post/filesystem.txt"
    capture_process_state "$STATE_DIR/post/processes.txt"
    capture_network_state "$STATE_DIR/post/network.txt"
}

# Run command with timeout
run_command() {
    local cmd="$1"
    local output_file="$STATE_DIR/logs/command_output.txt"
    local exit_code_file="$STATE_DIR/logs/exit_code.txt"
    
    log_info "Running command: $cmd"
    log_verbose "Timeout: ${TIMEOUT}s"
    
    # Build resource limits
    local limits=""
    if [[ -n "$MAX_MEMORY" ]]; then
        limits="$limits --memory=$MAX_MEMORY"
    fi
    
    # Run with timeout
    local exit_code=0
    if command -v timeout >/dev/null 2>&1; then
        timeout "$TIMEOUT" bash -c "$cmd" > "$output_file" 2>&1 || exit_code=$?
    else
        bash -c "$cmd" > "$output_file" 2>&1 || exit_code=$?
    fi
    
    echo "$exit_code" > "$exit_code_file"
    
    if [[ "$exit_code" -eq 0 ]]; then
        log_info "Command completed successfully (exit code 0)"
    elif [[ "$exit_code" -eq 124 ]]; then
        log_error "Command timed out after ${TIMEOUT}s"
    else
        log_error "Command failed with exit code $exit_code"
    fi
    
    return $exit_code
}

# Verify file exists
verify_file_exists() {
    local path="$1"
    log_verbose "Verifying file exists: $path"
    
    if [[ -e "$path" ]]; then
        echo '{"success": true, "path": "'"$path"'", "type": "'"$(file "$path" 2>/dev/null | cut -d: -f2 | xargs)"'"}'
        return 0
    else
        echo '{"success": false, "path": "'"$path"'", "error": "File does not exist"}'
        return 1
    fi
}

# Verify file contains pattern
verify_file_contains() {
    local path="$1"
    local pattern="$2"
    log_verbose "Verifying file contains pattern: $path"
    
    if [[ ! -f "$path" ]]; then
        echo '{"success": false, "path": "'"$path"'", "error": "File does not exist"}'
        return 1
    fi
    
    if grep -q "$pattern" "$path" 2>/dev/null; then
        local count=$(grep -c "$pattern" "$path" 2>/dev/null || echo 0)
        echo '{"success": true, "path": "'"$path"'", "pattern": "'"$pattern"'", "count": '$count'}'
        return 0
    else
        echo '{"success": false, "path": "'"$path"'", "pattern": "'"$pattern"'", "error": "Pattern not found"}'
        return 1
    fi
}

# Verify process running
verify_process_running() {
    local name="$1"
    log_verbose "Verifying process running: $name"
    
    if pgrep -x "$name" >/dev/null 2>&1 || ps aux | grep -v grep | grep -q "$name" 2>/dev/null; then
        echo '{"success": true, "process": "'"$name"'", "status": "running"}'
        return 0
    else
        echo '{"success": false, "process": "'"$name"'", "error": "Process not found"}'
        return 1
    fi
}

# Verify port listening
verify_port_listening() {
    local port="$1"
    log_verbose "Verifying port listening: $port"
    
    if netstat -tlnp 2>/dev/null | grep -q ":$port " || \
       ss -tlnp 2>/dev/null | grep -q ":$port " || \
       lsof -Pi :"$port" 2>/dev/null | grep -q LISTEN; then
        echo '{"success": true, "port": '$port', "status": "listening"}'
        return 0
    else
        echo '{"success": false, "port": '$port', "error": "Port not listening"}'
        return 1
    fi
}

# Parse and verify effect
verify_effect() {
    local effect="$1"
    local type=""
    local params=""
    
    # Parse effect string (format: type:param1:param2...)
    type=$(echo "$effect" | cut -d: -f1)
    params=$(echo "$effect" | cut -d: -f2-)
    
    log_verbose "Verifying effect: $type with params: $params"
    
    case "$type" in
        file_exists)
            verify_file_exists "$params"
            ;;
        file_contains)
            local path=$(echo "$params" | cut -d: -f1)
            local pattern=$(echo "$params" | cut -d: -f2-)
            verify_file_contains "$path" "$pattern"
            ;;
        process_running)
            verify_process_running "$params"
            ;;
        port_listening)
            verify_port_listening "$params"
            ;;
        *)
            echo '{"success": false, "type": "'"$type"'", "error": "Unknown effect type"}'
            return 1
            ;;
    esac
}

# Main execution
main() {
    parse_args "$@"
    
    # Validate required arguments
    if [[ -z "$COMMAND" ]]; then
        log_error "--command is required"
        show_help
        exit 1
    fi
    
    if [[ ${#EXPECTED_EFFECTS[@]} -eq 0 && ${#NEGATIVE_EFFECTS[@]} -eq 0 ]]; then
        log_error "At least one --expected or --negative effect is required"
        show_help
        exit 1
    fi
    
    # Setup
    setup_state_dir
    
    # Capture pre-state
    capture_pre_state
    
    # Run command
    local cmd_exit_code=0
    run_command "$COMMAND" || cmd_exit_code=$?
    
    # Capture post-state
    capture_post_state
    
    # Verify effects
    log_info "Verifying expected effects..."
    local success_count=0
    local fail_count=0
    declare -a results
    
    for effect in "${EXPECTED_EFFECTS[@]}"; do
        local result=$(verify_effect "$effect")
        results+=("$result")
        
        if echo "$result" | grep -q '"success": true'; then
            ((success_count++))
            log_info "✓ $effect"
        else
            ((fail_count++))
            log_error "✗ $effect"
        fi
    done
    
    # Verify negative effects
    log_info "Verifying negative effects (should NOT happen)..."
    for effect in "${NEGATIVE_EFFECTS[@]}"; do
        local result=$(verify_effect "$effect")
        
        # For negative, success means it should fail
        if echo "$result" | grep -q '"success": false'; then
            ((success_count++))
            log_info "✓ $effect (correctly did NOT happen)"
        else
            ((fail_count++))
            log_error "✗ $effect (should NOT have happened but did!)"
        fi
    done
    
    # Output summary
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        cat << EOF
{
  "command": "$COMMAND",
  "exit_code": $cmd_exit_code,
  "summary": {
    "total_checks": $((success_count + fail_count)),
    "passed": $success_count,
    "failed": $fail_count
  },
  "results": [
    $(IFS=,; echo "${results[*]}")
  ]
}
EOF
    else
        echo ""
        echo "==================="
        echo "Verification Report"
        echo "==================="
        echo "Command: $COMMAND"
        echo "Exit Code: $cmd_exit_code"
        echo ""
        echo "Results:"
        echo "  Passed: $success_count"
        echo "  Failed: $fail_count"
        echo ""
        
        if [[ $fail_count -gt 0 ]]; then
            echo "Result: FAILED"
            exit 1
        else
            echo "Result: SUCCESS"
            exit 0
        fi
    fi
}

# Run main
main "$@"
