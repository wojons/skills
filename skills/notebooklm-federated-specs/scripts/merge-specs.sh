#!/bin/bash
set -e

# merge-specs.sh
# Merge federated spec files into a single document with source attribution
#
# Usage: bash merge-specs.sh [OPTIONS]
#
# Options:
#   -c, --config FILE      Config file path (default: .notebooklm-specs.json)
#   -s, --specs-dir DIR    Specs directory (default: ./specs)
#   -o, --output FILE      Output file (default: ./merged-specs.md)
#   --max-size SIZE        Maximum output size (e.g., 50MB)
#   --validate             Validate output after merge
#   --batch                Merge into batch files (for NotebookLM optimization)
#   --batch-size N         Files per batch (default: 10)
#   --max-batch-size SIZE  Max batch file size (default: 500KB)
#   --dry-run              Show what would be merged without writing
#   --analyze              Show size breakdown per file
#   -v, --verbose          Verbose output
#   -h, --help             Show help

# Default settings
CONFIG_FILE=".notebooklm-specs.json"
SPECS_DIR="./specs"
OUTPUT_FILE="./merged-specs.md"
MAX_SIZE=""
VALIDATE=false
BATCH_MODE=false
BATCH_SIZE=10
MAX_BATCH_SIZE="500KB"
DRY_RUN=false
ANALYZE=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -s|--specs-dir)
                SPECS_DIR="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --max-size)
                MAX_SIZE="$2"
                shift 2
                ;;
            --validate)
                VALIDATE=true
                shift
                ;;
            --batch)
                BATCH_MODE=true
                shift
                ;;
            --batch-size)
                BATCH_SIZE="$2"
                shift 2
                ;;
            --max-batch-size)
                MAX_BATCH_SIZE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --analyze)
                ANALYZE=true
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
Usage: bash merge-specs.sh [OPTIONS]

Merge federated spec files into a single document with source attribution.

Options:
  -c, --config FILE      Config file path (default: .notebooklm-specs.json)
  -s, --specs-dir DIR    Specs directory (default: ./specs)
  -o, --output FILE      Output file (default: ./merged-specs.md)
  --max-size SIZE        Maximum output size (e.g., 50MB)
  --validate             Validate output after merge
  --batch                Merge into batch files (for NotebookLM optimization)
  --batch-size N         Files per batch (default: 10)
  --max-batch-size SIZE  Max batch file size (default: 500KB)
  --dry-run              Show what would be merged without writing
  --analyze              Show size breakdown per file
  -v, --verbose          Verbose output
  -h, --help             Show help

Examples:
  bash merge-specs.sh
  bash merge-specs.sh --batch --batch-size 10
  bash merge-specs.sh --max-size 10MB --validate
  bash merge-specs.sh --analyze
  bash merge-specs.sh --dry-run -v
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

# Load config if exists
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Loading config from $CONFIG_FILE"
        
        # Parse JSON config (simple key extraction)
        if command -v jq >/dev/null 2>&1; then
            local cfg_specs_dir=$(jq -r '.specs_dir // empty' "$CONFIG_FILE" 2>/dev/null)
            local cfg_output=$(jq -r '.output_file // empty' "$CONFIG_FILE" 2>/dev/null)
            local cfg_max_size=$(jq -r '.max_size_mb // empty' "$CONFIG_FILE" 2>/dev/null)
            
            [[ -n "$cfg_specs_dir" ]] && SPECS_DIR="$cfg_specs_dir"
            [[ -n "$cfg_output" ]] && OUTPUT_FILE="$cfg_output"
            [[ -n "$cfg_max_size" ]] && MAX_SIZE="${cfg_max_size}MB"
        else
            log_warn "jq not installed, skipping config file parsing"
        fi
    fi
}

# Convert size string to bytes
size_to_bytes() {
    local size="$1"
    local num=$(echo "$size" | sed 's/[^0-9.]//g')
    local unit=$(echo "$size" | sed 's/[0-9.]//g' | tr '[:lower:]' '[:upper:]')
    
    case "$unit" in
        KB|K) echo $(echo "$num * 1024" | bc | cut -d. -f1) ;;
        MB|M) echo $(echo "$num * 1024 * 1024" | bc | cut -d. -f1) ;;
        GB|G) echo $(echo "$num * 1024 * 1024 * 1024" | bc | cut -d. -f1) ;;
        B|"") echo "$num" ;;
        *) echo "0" ;;
    esac
}

# Format bytes to human readable
format_size() {
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

# Get file size in bytes
get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Generate header for a source file
generate_header() {
    local filename="$1"
    local filepath="$2"
    local index="$3"
    local total="$4"
    
    cat << EOF


=== ${filename} ===

EOF
}

# Merge specs into batch files
merge_specs_batch() {
    local merged_dir="./merged-specs"
    
    log_info "Scanning specs directory: $SPECS_DIR"
    
    if [[ ! -d "$SPECS_DIR" ]]; then
        log_error "Specs directory not found: $SPECS_DIR"
        exit 1
    fi
    
    # Create merged directory
    mkdir -p "$merged_dir"
    
    # Find all markdown files, sorted
    local spec_files=()
    while IFS= read -r -d '' file; do
        spec_files+=("$file")
    done < <(find "$SPECS_DIR" -name "*.md" -type f ! -name "README.md" ! -name "CHANGELOG.md" -print0 2>/dev/null | sort -z)
    
    local total_files=${#spec_files[@]}
    
    if [[ $total_files -eq 0 ]]; then
        log_error "No spec files found in $SPECS_DIR"
        exit 1
    fi
    
    log_info "Found $total_files spec files"
    
    # Dry run mode
    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo "DRY RUN - Batch plan:"
        echo "====================="
        echo "Batch size: $BATCH_SIZE files"
        echo "Max batch size: $MAX_BATCH_SIZE"
        echo ""
        
        local batch_num=1
        local file_in_batch=0
        local batch_size=0
        local max_bytes=$(size_to_bytes "$MAX_BATCH_SIZE")
        
        for file in "${spec_files[@]}"; do
            local size=$(get_file_size "$file")
            local filename=$(basename "$file")
            
            if [[ $file_in_batch -ge $BATCH_SIZE ]] || [[ $((batch_size + size)) -gt $max_bytes ]]; then
                echo ""
                echo "Batch $batch_num: $(format_size $batch_size), $file_in_batch files"
                ((batch_num++))
                file_in_batch=0
                batch_size=0
            fi
            
            echo "  $filename ($(format_size $size))"
            ((file_in_batch++))
            batch_size=$((batch_size + size))
        done
        
        if [[ $file_in_batch -gt 0 ]]; then
            echo ""
            echo "Batch $batch_num: $(format_size $batch_size), $file_in_batch files"
        fi
        
        exit 0
    fi
    
    # Analyze mode
    if [[ "$ANALYZE" == true ]]; then
        echo ""
        echo "SPEC FILE ANALYSIS"
        echo "=================="
        echo ""
        
        local total_size=0
        printf "%-10s %s\n" "SIZE" "FILE"
        printf "%-10s %s\n" "----" "----"
        
        for file in "${spec_files[@]}"; do
            local size=$(get_file_size "$file")
            local formatted=$(format_size $size)
            local rel_path="${file#$SPECS_DIR/}"
            printf "%-10s %s\n" "$formatted" "$rel_path"
            total_size=$((total_size + size))
        done
        
        echo ""
        printf "%-10s %s\n" "----" "----"
        printf "%-10s %s\n" "$(format_size $total_size)" "TOTAL ($total_files files)"
        echo ""
        echo "Batch plan: $BATCH_SIZE files/batch, max $MAX_BATCH_SIZE per batch"
        echo "Estimated batches: $(( (total_files + BATCH_SIZE - 1) / BATCH_SIZE ))"
        exit 0
    fi
    
    # Clear old merged files
    rm -f "$merged_dir"/merged-specs-*.md
    
    # Process batches
    local batch_num=1
    local file_in_batch=0
    local batch_size=0
    local max_bytes=$(size_to_bytes "$MAX_BATCH_SIZE")
    local batch_content=""
    local batch_files=()
    
    for file in "${spec_files[@]}"; do
        local size=$(get_file_size "$file")
        local filename=$(basename "$file")
        local rel_path="${file#./}"
        
        # Start new batch if needed
        if [[ $file_in_batch -ge $BATCH_SIZE ]] || [[ $((batch_size + size)) -gt $max_bytes && $file_in_batch -gt 0 ]]; then
            # Write current batch
            local batch_file="$merged_dir/merged-specs-$(printf '%02d' $batch_num).md"
            echo -e "$batch_content" > "$batch_file"
            log_success "Created batch $batch_num: $(format_size $batch_size), $file_in_batch files"
            
            ((batch_num++))
            file_in_batch=0
            batch_size=0
            batch_content=""
            batch_files=()
        fi
        
        log_info "Adding to batch $batch_num: $filename"
        
        # Add header and content
        batch_content+="$(generate_header "$filename" "$rel_path" "$((file_in_batch + 1))" "$BATCH_SIZE")"
        batch_content+="$(cat "$file")"
        batch_content+="\n"
        
        batch_files+=("$filename|$size")
        ((file_in_batch++))
        batch_size=$((batch_size + size))
    done
    
    # Write final batch
    if [[ $file_in_batch -gt 0 ]]; then
        local batch_file="$merged_dir/merged-specs-$(printf '%02d' $batch_num).md"
        echo -e "$batch_content" > "$batch_file"
        log_success "Created batch $batch_num: $(format_size $batch_size), $file_in_batch files"
    fi
    
    # Summary
    echo ""
    echo "BATCH MERGE COMPLETE"
    echo "===================="
    echo "Input Files: $total_files"
    echo "Output Batches: $batch_num"
    echo "Batch Size Limit: $BATCH_SIZE files, $MAX_BATCH_SIZE"
    echo ""
    echo "Batch Files:"
    for f in "$merged_dir"/merged-specs-*.md; do
        if [[ -f "$f" ]]; then
            local sz=$(get_file_size "$f")
            echo "  ✓ $(basename $f) ($(format_size $sz))"
        fi
    done
    echo ""
    echo "Ready to sync with NotebookLM."
    echo "Run: bash scripts/sync-notebook.sh --create"
}

# Main merge function
merge_specs() {
    log_info "Scanning specs directory: $SPECS_DIR"
    
    if [[ ! -d "$SPECS_DIR" ]]; then
        log_error "Specs directory not found: $SPECS_DIR"
        exit 1
    fi
    
    # Find all markdown files, sorted
    local spec_files=()
    while IFS= read -r -d '' file; do
        spec_files+=("$file")
    done < <(find "$SPECS_DIR" -name "*.md" -type f ! -name "README.md" ! -name "CHANGELOG.md" -print0 2>/dev/null | sort -z)
    
    local total_files=${#spec_files[@]}
    
    if [[ $total_files -eq 0 ]]; then
        log_error "No spec files found in $SPECS_DIR"
        exit 1
    fi
    
    log_info "Found $total_files spec files"
    
    # Analyze mode - just show sizes
    if [[ "$ANALYZE" == true ]]; then
        echo ""
        echo "SPEC FILE ANALYSIS"
        echo "=================="
        echo ""
        
        local total_size=0
        printf "%-10s %s\n" "SIZE" "FILE"
        printf "%-10s %s\n" "----" "----"
        
        for file in "${spec_files[@]}"; do
            local size=$(get_file_size "$file")
            local formatted=$(format_size $size)
            local rel_path="${file#$SPECS_DIR/}"
            printf "%-10s %s\n" "$formatted" "$rel_path"
            total_size=$((total_size + size))
        done
        
        echo ""
        printf "%-10s %s\n" "----" "----"
        printf "%-10s %s\n" "$(format_size $total_size)" "TOTAL ($total_files files)"
        echo ""
        exit 0
    fi
    
    # Dry run mode
    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo "DRY RUN - Files that would be merged:"
        echo "====================================="
        for file in "${spec_files[@]}"; do
            local size=$(get_file_size "$file")
            local formatted=$(format_size $size)
            echo "  ${file#$SPECS_DIR/} ($formatted)"
        done
        echo ""
        echo "Output would be written to: $OUTPUT_FILE"
        exit 0
    fi
    
    # Build merged content
    local merged_content=""
    local total_size=0
    local file_sizes=()
    
    # Add header
    merged_content="# Merged Specifications\n\n"
    merged_content+="Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")\n"
    merged_content+="Files: $total_files\n\n"
    
    # Process each file
    local index=0
    for file in "${spec_files[@]}"; do
        ((index++))
        local filename=$(basename "$file")
        local rel_path="${file#./}"
        local size=$(get_file_size "$file")
        
        log_info "Processing [$index/$total_files] $filename ($(format_size $size))"
        
        # Add header for this source
        merged_content+="$(generate_header "$filename" "$rel_path" "$index" "$total_files")"
        
        # Add file content
        if [[ -f "$file" ]]; then
            merged_content+="$(cat "$file")"
            merged_content+="\n"
        fi
        
        total_size=$((total_size + size))
        file_sizes+=("$filename|$size")
    done
    
    # Add footer
    merged_content+="\n---\n\n*Merged by notebooklm-federated-specs skill*\n"
    
    # Check size limit
    if [[ -n "$MAX_SIZE" ]]; then
        local max_bytes=$(size_to_bytes "$MAX_SIZE")
        if [[ $total_size -gt $max_bytes ]]; then
            log_error "Merged size ($(format_size $total_size)) exceeds limit ($MAX_SIZE)"
            log_error "Use --analyze to see size breakdown"
            exit 1
        fi
    fi
    
    # Write output
    echo -e "$merged_content" > "$OUTPUT_FILE"
    
    # Validate if requested
    if [[ "$VALIDATE" == true ]]; then
        if [[ ! -f "$OUTPUT_FILE" ]]; then
            log_error "Validation failed: Output file not created"
            exit 1
        fi
        
        local output_size=$(get_file_size "$OUTPUT_FILE")
        if [[ $output_size -eq 0 ]]; then
            log_error "Validation failed: Output file is empty"
            exit 1
        fi
        
        log_success "Validation passed"
    fi
    
    # Print summary
    echo ""
    echo "MERGE COMPLETE"
    echo "=============="
    echo "Input Files: $total_files"
    echo "Output File: $OUTPUT_FILE"
    echo "Total Size: $(format_size $total_size)"
    echo "Est. Tokens: ~$((total_size / 4))"
    echo ""
    echo "Files Merged:"
    for entry in "${file_sizes[@]}"; do
        local fname=$(echo "$entry" | cut -d'|' -f1)
        local fsize=$(echo "$entry" | cut -d'|' -f2)
        echo "  ✓ specs/$fname ($(format_size $fsize))"
    done
    echo ""
    echo "Ready to sync with NotebookLM."
}

# Main execution
main() {
    parse_args "$@"
    load_config
    
    if [[ "$BATCH_MODE" == true ]]; then
        merge_specs_batch
    else
        merge_specs
    fi
}

main "$@"
