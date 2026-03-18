#!/bin/bash

# Sherlock Holmes Method: Observe, Don't Just See
# "You see, but you do not observe. The distinction is clear."

echo "Observe, Don't Just See - Sherlock Holmes Debugging Method"
echo "========================================================="
echo ""

LOG_FILE=""
FOCUS_AREA=""
DETAIL_LEVEL="normal"
OUTPUT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --error-log)
            LOG_FILE="$2"
            shift 2
            ;;
        --focus-area)
            FOCUS_AREA="$2"
            shift 2
            ;;
        --detail-level)
            DETAIL_LEVEL="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --help)
            echo "Usage: observe-dont-see [OPTIONS]"
            echo ""
            echo "Analyze logs with Sherlock Holmes' attention to detail."
            echo ""
            echo "Options:"
            echo "  --error-log FILE       Log file to analyze"
            echo "  --focus-area AREA      Specific area to focus on"
            echo "  --detail-level LEVEL   normal|granular|microscopic"
            echo "  --output FILE          Output file for observations"
            echo ""
            echo "Example:"
            echo '  observe-dont-see --error-log app.log --focus-area database --detail-level granular'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$LOG_FILE" ]; then
    echo "Error: --error-log is required"
    exit 1
fi

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found: $LOG_FILE"
    exit 1
fi

if [ -z "$OUTPUT" ]; then
    OUTPUT="observations-$(date +%Y%m%d-%H%M%S).md"
fi

echo "Log file: $LOG_FILE"
echo "Focus area: ${FOCUS_AREA:-"all"}"
echo "Detail level: $DETAIL_LEVEL"
echo "Output: $OUTPUT"
echo ""

# Create observations report
cat > "$OUTPUT" << EOF
# Observations Report
## Sherlock Holmes Method: Observe, Don't Just See

> "You see, but you do not observe. The distinction is clear."
> — Sherlock Holmes

### Analysis Parameters
- **Log file**: $LOG_FILE
- **Focus area**: ${FOCUS_AREA:-"all"}
- **Detail level**: $DETAIL_LEVEL
- **Generated**: $(date)

---

## What Most People See

[Common observations - the obvious facts]

- Error messages
- Stack traces
- Timestamps

---

## What Sherlock Holmes Observes

> "The world is full of obvious things which nobody by any chance ever observes."

### Granular Details ($(wc -l < "$LOG_FILE") total lines)

EOF

# Analyze based on detail level
case "$DETAIL_LEVEL" in
    "normal")
        echo "Analyzing at normal detail level..."
        echo "" >> "$OUTPUT"
        echo "#### Error Patterns" >> "$OUTPUT"
        echo "\`\`\`" >> "$OUTPUT"
        grep -i "error\|exception\|fail" "$LOG_FILE" | head -20 >> "$OUTPUT" 2>/dev/null || echo "No errors found" >> "$OUTPUT"
        echo "\`\`\`" >> "$OUTPUT"
        ;;
    "granular")
        echo "Analyzing at granular detail level..."
        echo "" >> "$OUTPUT"
        echo "#### All Events (chronological)" >> "$OUTPUT"
        echo "\`\`\`" >> "$OUTPUT"
        head -50 "$LOG_FILE" >> "$OUTPUT"
        echo "\`\`\`" >> "$OUTPUT"
        echo "" >> "$OUTPUT"
        echo "#### Timing Analysis" >> "$OUTPUT"
        echo "- First timestamp: $(head -1 "$LOG_FILE" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}:[0-9]{2}' | head -1 || 'N/A')"
        echo "- Last timestamp: $(tail -1 "$LOG_FILE" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}:[0-9]{2}' | head -1 || 'N/A')"
        ;;
    "microscopic")
        echo "Analyzing at microscopic detail level..."
        echo "" >> "$OUTPUT"
        echo "#### Character-by-Character Analysis" >> "$OUTPUT"
        echo "Every character, space, and timestamp matters." >> "$OUTPUT"
        echo "" >> "$OUTPUT"
        echo "\`\`\`" >> "$OUTPUT"
        cat "$LOG_FILE" >> "$OUTPUT"
        echo "\`\`\`" >> "$OUTPUT"
        ;;
esac

cat >> "$OUTPUT" << EOF

---

## Small Details That Matter

> "It has long been an axiom of mine that the little things are infinitely the most important."

### Micro-Observations

| Detail | Observation | Significance |
|--------|-------------|--------------|
| | | |

### Anomalies Detected

[List anything unusual, unexpected, or slightly off]

1. 
2. 
3. 

### Timing Irregularities

- Delays between events:
- Unusual gaps:
- Out-of-order events:

### Context Clues

[What is happening around the error?]

- Events immediately before:
- Events immediately after:
- Related but distant events:

---

## Questions Sherlock Would Ask

1. **What is missing?** What should be in the logs but isn't?
2. **What is extra?** What appears that shouldn't be there?
3. **What changed?** What is different from normal operation?
4. **What is the pattern?** When does it happen? When doesn't it?
5. **What are the trifles?** What small details might be clues?

---

## Evidence Summary

### Vital Facts
[What matters most]

### Incidental Facts
[What can be ignored]

### Missing Information
[What do you need to gather?]

---

## Conclusions from Observation

Before forming any theory, document what you have actually observed:

[Your observations here - be factual, not interpretive]

---

> "There is nothing like first-hand evidence."
> — Sherlock Holmes
EOF

echo ""
echo "✓ Observations report created: $OUTPUT"
echo ""
echo "Remember:"
echo "  • Don't form theories yet - just observe"
echo "  • Notice the small things"
echo "  • Document exactly what you see"
echo "  • The truth is in the details"