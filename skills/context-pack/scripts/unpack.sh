#!/bin/bash
set -e

# unpack.sh
# Extract files from a Context Pack back into filesystem
#
# Usage: bash unpack.sh <context-file> [output-dir]
#
# Extracts files from markdown format and reconstructs directory structure

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging
log_info() {
    echo "[INFO] $1" >&2
}

log_error() {
    echo "[ERROR] $1" >&2
}

show_help() {
    cat << 'EOF'
Usage: bash unpack.sh <context-file> [output-dir]

Extract files from a Context Pack back into filesystem.

Arguments:
  context-file    Path to the context pack file (markdown format)
  output-dir      Directory to extract to (default: ./extracted)

Options:
  -h, --help      Show help

Examples:
  bash unpack.sh context.md                    # Extract to ./extracted/
  bash unpack.sh context.md ./my-project         # Extract to ./my-project/
EOF
}

# Parse arguments
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

CONTEXT_FILE="$1"
OUTPUT_DIR="${2:-./extracted}"

# Validate input
if [[ ! -f "$CONTEXT_FILE" ]]; then
    log_error "Context file not found: $CONTEXT_FILE"
    exit 1
fi

log_info "Extracting from: $CONTEXT_FILE"
log_info "Output directory: $OUTPUT_DIR"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Extract files from markdown
# Pattern: ### path/to/file.ext followed by ```language ... ```
in_file_section=false
current_file=""
current_content=""

# Simple extraction - look for file headers and code blocks
awk '
/^### / {
    # Save previous file if we have one
    if (in_block && filename != "") {
        print "FILE_END:" filename
        in_block = 0
    }
    filename = substr($0, 5)  # Remove "### "
    print "FILE_START:" filename
    next
}
/^```/ && in_block {
    print "FILE_END:" filename
    in_block = 0
    filename = ""
    next
}
/^```/ && !in_block {
    in_block = 1
    next
}
in_block {
    print
}
' "$CONTEXT_FILE" | while IFS= read -r line; do
    if [[ "$line" == FILE_START:* ]]; then
        current_file="${line#FILE_START:}"
        current_content=""
        log_info "Extracting: $current_file"
    elif [[ "$line" == FILE_END:* ]]; then
        if [[ -n "$current_file" ]]; then
            # Create directory
            dir=$(dirname "$OUTPUT_DIR/$current_file")
            mkdir -p "$dir"
            
            # Write content
            echo -e "$current_content" > "$OUTPUT_DIR/$current_file"
            log_info "  Created: $OUTPUT_DIR/$current_file"
        fi
        current_file=""
        current_content=""
    elif [[ -n "$current_file" ]]; then
        current_content="${current_content}${line}\n"
    fi
done

log_info "Extraction complete!"
log_info "Files extracted to: $OUTPUT_DIR"
