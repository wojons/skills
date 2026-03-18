#!/bin/bash

# Sherlock Holmes Method: Systematic Elimination
# "When you have eliminated the impossible, whatever remains, however improbable, must be the truth."

echo "Eliminate the Impossible - Sherlock Holmes Debugging Method"
echo "=========================================================="
echo ""

# Parse arguments
SYMPTOMS=""
DATA_DIR=""
OUTPUT=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --symptoms)
            SYMPTOMS="$2"
            shift 2
            ;;
        --data-dir)
            DATA_DIR="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: eliminate-impossible [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --symptoms TEXT        Description of the symptoms"
            echo "  --data-dir DIR         Directory containing logs and data"
            echo "  --output FILE          Output file for report"
            echo "  --verbose              Enable verbose output"
            echo ""
            echo "Example:"
            echo '  eliminate-impossible --symptoms "intermittent-500-errors" --data-dir ./logs'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$SYMPTOMS" ]; then
    echo "Error: --symptoms is required"
    exit 1
fi

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

if [ -z "$OUTPUT" ]; then
    OUTPUT="elimination-report-$(date +%Y%m%d-%H%M%S).md"
fi

echo "Symptoms: $SYMPTOMS"
if [ -n "$DATA_DIR" ]; then
    echo "Data directory: $DATA_DIR"
fi
echo "Output: $OUTPUT"
echo ""

# Common causes to investigate
declare -a CAUSES=(
    "Database connection/timeout"
    "Network connectivity"
    "Memory exhaustion/OOM"
    "CPU throttling/high load"
    "Disk space/full filesystem"
    "Configuration error"
    "Dependency/version mismatch"
    "Authentication/authorization"
    "Race condition/concurrency"
    "Data corruption"
    "External API failure"
    "Recent deployment/change"
)

echo "Starting systematic elimination of ${#CAUSES[@]} possible causes..."
echo ""

# Create elimination report
cat > "$OUTPUT" << EOF
# Systematic Elimination Report
## Generated: $TIMESTAMP

### Symptoms
$SYMPTOMS

### Methodology
Following Sherlock Holmes' principle: "When you have eliminated the impossible, whatever remains, however improbable, must be the truth."

---

## Elimination Matrix

| # | Possible Cause | Evidence Checked | Ruled Out | Reason/Notes |
|---|----------------|------------------|-----------|--------------|
EOF

# Process each cause
COUNT=0
for cause in "${CAUSES[@]}"; do
    ((COUNT++))
    echo "[$COUNT/${#CAUSES[@]]} Investigating: $cause"
    
    # Generate evidence checks based on cause type
    case "$cause" in
        "Database connection/timeout")
            EVIDENCE="Connection logs, Query times, Connection pool status"
            ;;
        "Network connectivity")
            EVIDENCE="Ping tests, DNS resolution, Firewall logs"
            ;;
        "Memory exhaustion/OOM")
            EVIDENCE="Memory metrics, OOM killer logs, Heap dumps"
            ;;
        "CPU throttling/high load")
            EVIDENCE="CPU usage, Load average, Process list"
            ;;
        "Disk space/full filesystem")
            EVIDENCE="df -h, inode usage, Log rotation"
            ;;
        "Configuration error")
            EVIDENCE="Config files, Environment variables, Recent changes"
            ;;
        "Dependency/version mismatch")
            EVIDENCE="Package versions, Lock files, Dependency tree"
            ;;
        "Authentication/authorization")
            EVIDENCE="Auth logs, Token validity, Permission checks"
            ;;
        "Race condition/concurrency")
            EVIDENCE="Thread dumps, Synchronization logs, Timing analysis"
            ;;
        "Data corruption")
            EVIDENCE="Checksums, Data validation, Backup comparison"
            ;;
        "External API failure")
            EVIDENCE="API logs, Response times, Error rates"
            ;;
        "Recent deployment/change")
            EVIDENCE="Git log, Deployment history, Change timeline"
            ;;
    esac
    
    echo "    Evidence to check: $EVIDENCE"
    echo "    [ ] Rule out based on evidence"
    echo ""
    
    # Add to report
    printf "| %d | %s | %s | [ ] | |\n" "$COUNT" "$cause" "$EVIDENCE" >> "$OUTPUT"
done

cat >> "$OUTPUT" << EOF

---

## Investigation Checklist

For each cause above:
1. [ ] Gather relevant evidence
2. [ ] Analyze the data objectively
3. [ ] Determine if cause is possible or impossible
4. [ ] Document your reasoning
5. [ ] Mark as ruled out or remains possible

---

## Remaining Possibilities

After elimination, list here what remains:

1. 
2. 
3. 

---

## Next Steps

1. Focus on the remaining possibilities
2. Design tests to confirm/deny each
3. "The truth, however improbable"

---

> "It is a capital mistake to theorize before one has data."
> — Sherlock Holmes

EOF

echo "✓ Elimination report created: $OUTPUT"
echo ""
echo "Next steps:"
echo "1. Open the report: $OUTPUT"
echo "2. Investigate each cause systematically"
echo "3. Mark causes as ruled out with evidence"
echo "4. Focus on what remains"
echo ""
echo "Remember: When you have eliminated the impossible, whatever remains, however improbable, must be the truth."