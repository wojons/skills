#!/bin/bash
set -e

# pack.sh
# Pack a folder or ZIP into LLM-friendly context format
#
# Usage: bash pack.sh [OPTIONS] <path>
#
# Options:
#   -i, --include PATTERN      Include files matching pattern
#   -e, --exclude PATTERN      Exclude files matching pattern
#   -d, --include-dir DIR      Include only this directory
#   --include-binary            Include binary files as Base64
#   --max-files N              Maximum number of files
#   --max-size SIZE            Maximum total size (e.g., 10MB, 1GB)
#   --max-tokens N             Maximum token estimate
#   -o, --output FILE          Output file (default: stdout)
#   --format FORMAT            Output format: markdown, json, plain
#   --clipboard                Copy output to clipboard
#   --interactive              Interactive file selection
#   -v, --verbose              Verbose output
#   -h, --help                 Show help

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEXT_EXTENSIONS="txt md js ts jsx tsx json html htm css scss sass less py java c cpp h hpp cs go rs php xml yml yaml sh bat pl rb ini conf toml csv tsv log env"
BINARY_EXTENSIONS="png jpg jpeg gif ico webp bmp exe bin app dll so dylib zip tar gz rar 7z pdf doc docx xls xlsx ppt pptx mp3 mp4 wav avi mov ttf otf woff woff2"

# Default settings
SOURCE_PATH=""
OUTPUT_FILE=""
OUTPUT_FORMAT="markdown"
INCLUDE_PATTERNS=()
EXCLUDE_PATTERNS=(".git" "node_modules" ".next" "dist" "build" "__pycache__" ".pytest_cache" ".coverage" ".env" ".venv" "*.pyc" ".DS_Store" "Thumbs.db")
INCLUDE_BINARY=false
MAX_FILES=0
MAX_SIZE=0
MAX_TOKENS=0
CLIPBOARD=false
INTERACTIVE=false
VERBOSE=false

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -i|--include)
                INCLUDE_PATTERNS+=("$2")
                shift 2
                ;;
            -e|--exclude)
                EXCLUDE_PATTERNS+=("$2")
                shift 2
                ;;
            -d|--include-dir)
                INCLUDE_DIR="$2"
                shift 2
                ;;
            --include-binary)
                INCLUDE_BINARY=true
                shift
                ;;
            --max-files)
                MAX_FILES="$2"
                shift 2
                ;;
            --max-size)
                MAX_SIZE="$2"
                shift 2
                ;;
            --max-tokens)
                MAX_TOKENS="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --clipboard)
                CLIPBOARD=true
                shift
                ;;
            --interactive)
                INTERACTIVE=true
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
            -*)
                echo "Unknown option: $1" >&2
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$SOURCE_PATH" ]]; then
                    SOURCE_PATH="$1"
                else
                    echo "Multiple paths specified: $SOURCE_PATH and $1" >&2
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
Usage: bash pack.sh [OPTIONS] <path>

Pack a folder or ZIP into LLM-friendly context format.

Options:
  -i, --include PATTERN      Include files matching pattern
  -e, --exclude PATTERN      Exclude files matching pattern
  -d, --include-dir DIR      Include only this directory
  --include-binary            Include binary files as Base64
  --max-files N              Maximum number of files
  --max-size SIZE            Maximum total size (e.g., 10MB, 1GB)
  --max-tokens N             Maximum token estimate
  -o, --output FILE          Output file (default: stdout)
  --format FORMAT            Output format: markdown, json, plain
  --clipboard                Copy output to clipboard
  --interactive              Interactive file selection
  -v, --verbose              Verbose output
  -h, --help                 Show help

Examples:
  bash pack.sh .                          # Pack current directory
  bash pack.sh ./my-project               # Pack specific directory
  bash pack.sh . --include-binary       # Include binary files
  bash pack.sh . -e "*test*" -e "*.log"   # Exclude tests and logs
  bash pack.sh . -o context.md            # Output to file
  bash pack.sh . --format json            # JSON output
  bash pack.sh project.zip              # Pack ZIP archive
EOF
}

# Logging
log_info() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[INFO] $1" >&2
    fi
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Check if file should be included
should_include_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    # Check explicit excludes first
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$filename" == $pattern ]] || [[ "$file" == */$pattern/* ]]; then
            return 1
        fi
    done
    
    # If include patterns specified, file must match at least one
    if [[ ${#INCLUDE_PATTERNS[@]} -gt 0 ]]; then
        local matched=false
        for pattern in "${INCLUDE_PATTERNS[@]}"; do
            if [[ "$filename" == $pattern ]]; then
                matched=true
                break
            fi
        done
        if [[ "$matched" == false ]]; then
            return 1
        fi
    fi
    
    # Check include directory restriction
    if [[ -n "$INCLUDE_DIR" ]]; then
        if [[ ! "$file" == $INCLUDE_DIR/* ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Check if file is text
is_text_file() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"  # lowercase
    
    for text_ext in $TEXT_EXTENSIONS; do
        if [[ "$ext" == "$text_ext" ]]; then
            return 0
        fi
    done
    
    # Try file command
    if command -v file >/dev/null 2>&1; then
        local file_type=$(file -b --mime-type "$file" 2>/dev/null || echo "")
        if [[ "$file_type" == text/* ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Format bytes
format_bytes() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes} B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$(echo "scale=1; $bytes/1024" | bc) KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$(echo "scale=1; $bytes/1048576" | bc) MB"
    else
        echo "$(echo "scale=1; $bytes/1073741824" | bc) GB"
    fi
}

# Estimate tokens
estimate_tokens() {
    local size=$1
    # Rough estimate: ~3-4 chars per token for code
    echo $((size / 3))
}

# Generate markdown output
generate_markdown() {
    local name="$1"
    local files="$2"
    local stats="$3"
    
    cat << EOF
# Context Pack: $name

## Summary
- **Source**: $SOURCE_PATH
- **Packed**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Files**: $stats

## File Tree
\`\`\`
$(generate_tree "$files")
\`\`\`

## Files

$(generate_file_contents "$files")

---
*Packed with Context Pack skill*
EOF
}

# Generate file tree
generate_tree() {
    local files="$1"
    echo "$files" | while IFS='|' read -r path size type; do
        echo "$path"
    done | tree --fromfile 2>/dev/null || echo "$files" | cut -d'|' -f1
}

# Generate file contents
generate_file_contents() {
    local files="$1"
    echo "$files" | while IFS='|' read -r path size type; do
        if [[ -f "$path" ]]; then
            echo "### $path"
            echo ""
            local ext="${path##*.}"
            echo "\`\`\`${ext}"
            cat "$path" 2>/dev/null || echo "[Error reading file]"
            echo "\`\`\`"
            echo ""
        fi
    done
}

# Main execution
main() {
    parse_args "$@"
    
    # Validate arguments
    if [[ -z "$SOURCE_PATH" ]]; then
        log_error "No path specified"
        show_help
        exit 1
    fi
    
    if [[ ! -e "$SOURCE_PATH" ]]; then
        log_error "Path does not exist: $SOURCE_PATH"
        exit 1
    fi
    
    # Handle ZIP files
    if [[ "$SOURCE_PATH" == *.zip ]]; then
        log_info "Processing ZIP archive: $SOURCE_PATH"
        TEMP_DIR=$(mktemp -d)
        unzip -q "$SOURCE_PATH" -d "$TEMP_DIR"
        SOURCE_PATH="$TEMP_DIR"
    fi
    
    # Find all files
    log_info "Scanning files..."
    local all_files=""
    local file_count=0
    local total_size=0
    local text_count=0
    local binary_count=0
    
    while IFS= read -r -d '' file; do
        if should_include_file "$file"; then
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
            local type="text"
            
            if ! is_text_file "$file"; then
                type="binary"
                ((binary_count++))
            else
                ((text_count++))
            fi
            
            # Skip binary files if not included
            if [[ "$type" == "binary" && "$INCLUDE_BINARY" == false ]]; then
                continue
            fi
            
            # Check limits
            if [[ $MAX_FILES -gt 0 && $file_count -ge $MAX_FILES ]]; then
                break
            fi
            
            if [[ $MAX_SIZE -gt 0 && $total_size -ge $MAX_SIZE ]]; then
                break
            fi
            
            all_files="${all_files}${file}|${size}|${type}\n"
            ((file_count++))
            total_size=$((total_size + size))
        fi
    done < <(find "$SOURCE_PATH" -type f -print0 2>/dev/null)
    
    # Generate stats
    local estimated_tokens=$(estimate_tokens $total_size)
    local stats="$file_count ($text_count text, $binary_count binary), Size: $(format_bytes $total_size), Est. tokens: ~$estimated_tokens"
    
    log_info "Found $stats"
    
    # Check token limit
    if [[ $MAX_TOKENS -gt 0 && $estimated_tokens -gt $MAX_TOKENS ]]; then
        log_error "Estimated tokens ($estimated_tokens) exceeds maximum ($MAX_TOKENS)"
        exit 1
    fi
    
    # Get project name
    local project_name=$(basename "$SOURCE_PATH")
    
    # Generate output
    local output=""
    if [[ "$OUTPUT_FORMAT" == "markdown" ]]; then
        output=$(generate_markdown "$project_name" "$all_files" "$stats")
    else
        # JSON or plain format
        output="Format $OUTPUT_FORMAT not yet implemented"
    fi
    
    # Output
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$output" > "$OUTPUT_FILE"
        log_info "Output written to: $OUTPUT_FILE"
    elif [[ "$CLIPBOARD" == true ]]; then
        if command -v pbcopy >/dev/null 2>&1; then
            echo "$output" | pbcopy
            log_info "Copied to clipboard"
        elif command -v xclip >/dev/null 2>&1; then
            echo "$output" | xclip -selection clipboard
            log_info "Copied to clipboard"
        else
            log_error "No clipboard command found"
            echo "$output"
        fi
    else
        echo "$output"
    fi
    
    # Cleanup temp directory
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Run main
main "$@"
