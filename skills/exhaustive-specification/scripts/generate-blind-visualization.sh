#!/bin/bash
set -e

echo "Blind-Person Visualization Report" >&2
echo "===================================" >&2

usage() {
    echo "Usage: $0 [OPTIONS]" >&2
    echo "Options:" >&2
    echo "  --spec-file FILE       Specification file to analyze" >&2
    echo "  --spec-dir DIR         Directory containing specification files" >&2
    echo "  --output FILE          Output file for visualization report (default: blind-visualization-report.md)" >&2
    echo "  --verbose              Enable verbose output" >&2
    echo "  --help                 Show this help message" >&2
    exit 1
}

SPEC_FILE=""
SPEC_DIR=""
OUTPUT="blind-visualization-report.md"
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --spec-file)
            SPEC_FILE="$2"
            shift 2
            ;;
        --spec-dir)
            SPEC_DIR="$2"
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
            usage
            ;;
        *)
            echo "Error: Unknown option $1" >&2
            usage
            ;;
    esac
done

if [ -z "$SPEC_FILE" ] && [ -z "$SPEC_DIR" ]; then
    echo "Error: Either --spec-file or --spec-dir is required" >&2
    usage
fi

if [ -n "$SPEC_FILE" ] && [ ! -f "$SPEC_FILE" ]; then
    echo "Error: Specification file '$SPEC_FILE' does not exist" >&2
    exit 1
fi

if [ -n "$SPEC_DIR" ] && [ ! -d "$SPEC_DIR" ]; then
    echo "Error: Specification directory '$SPEC_DIR' does not exist" >&2
    exit 1
fi

echo "Generating blind-person visualization report..." >&2
if [ -n "$SPEC_FILE" ]; then
    echo "• Specification file: $SPEC_FILE" >&2
    FILES=("$SPEC_FILE")
else
    echo "• Specification directory: $SPEC_DIR" >&2
    FILES=()
    while IFS= read -r -d '' file; do
        FILES+=("$file")
    done < <(find "$SPEC_DIR" -name "*.md" -type f -print0 2>/dev/null)
fi
echo "• Output file: $OUTPUT" >&2
echo "" >&2

TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)

# Blind visualization criteria
CRITERIA=(
    "UI/UX detailed enough for blind visualization"
    "System interactions describable without sight"
    "Error states and recovery procedures clearly defined"
    "Data flows and transformations comprehensible"
    "API sequences and timing understandable"
    "Database relationships visualizable"
    "Component relationships mappable mentally"
    "Animation timing and behavior describable"
    "Layout and spacing precisely defined"
    "Color usage documented for non-visual understanding"
)

# Indicators of good blind visualization
INDICATORS=(
    "describe without seeing"
    "blind person"
    "visualize"
    "imagine"
    "mental model"
    "detailed description"
    "step-by-step"
    "clear sequence"
    "precise timing"
    "exact dimensions"
    "specific positions"
    "auditory cues"
    "tactile feedback"
    "narrative description"
    "comprehensive walkthrough"
)

# Analyze each file
TOTAL_FILES=${#FILES[@]}
SCORES=()
REPORT_SECTIONS=()

for file in "${FILES[@]}"; do
    FILENAME=$(basename "$file")
    CONTENT=$(cat "$file")
    
    # Count lines and words
    LINES=$(wc -l < "$file" 2>/dev/null || echo 0)
    WORDS=$(wc -w < "$file" 2>/dev/null || echo 0)
    
    # Check for blind visualization indicators
    INDICATOR_COUNT=0
    FOUND_INDICATORS=()
    
    for indicator in "${INDICATORS[@]}"; do
        if echo "$CONTENT" | grep -i -q "$indicator"; then
            ((INDICATOR_COUNT++))
            FOUND_INDICATORS+=("$indicator")
        fi
    done
    
    # Check for visual description quality
    # Count descriptive phrases
    DESCRIPTIVE_PHRASES=$(echo "$CONTENT" | grep -i -c -E "(appears|looks like|appearance|layout|position|size|color|spacing|animation)" || true)
    
    # Calculate score (0-100)
    if [ $LINES -gt 0 ]; then
        INDICATOR_SCORE=$(echo "scale=1; $INDICATOR_COUNT * 100 / ${#INDICATORS[@]}" | bc)
        DESCRIPTIVE_SCORE=$(echo "scale=1; $DESCRIPTIVE_PHRASES * 100 / $LINES" | bc)
        OVERALL_SCORE=$(echo "scale=1; ($INDICATOR_SCORE * 0.6) + ($DESCRIPTIVE_SCORE * 0.4)" | bc)
    else
        INDICATOR_SCORE=0
        DESCRIPTIVE_SCORE=0
        OVERALL_SCORE=0
    fi
    
    SCORES+=("$OVERALL_SCORE")
    
    # Generate report section for this file
    REPORT_SECTION="# $FILENAME Blind Visualization Assessment\n\n"
    REPORT_SECTION+="**File**: $file\n"
    REPORT_SECTION+="**Lines**: $LINES | **Words**: $WORDS\n"
    REPORT_SECTION+="**Blind Visualization Score**: ${OVERALL_SCORE}%\n\n"
    
    REPORT_SECTION+="## Indicators Found (${INDICATOR_COUNT}/${#INDICATORS[@]})\n"
    if [ ${#FOUND_INDICATORS[@]} -gt 0 ]; then
        REPORT_SECTION+="\n"
        for indicator in "${FOUND_INDICATORS[@]}"; do
            REPORT_SECTION+="- \`$indicator\`\n"
        done
    else
        REPORT_SECTION+="No blind visualization indicators found.\n"
    fi
    
    REPORT_SECTION+="\n## Descriptive Content\n"
    REPORT_SECTION+="**Descriptive phrases**: $DESCRIPTIVE_PHRASES\n"
    REPORT_SECTION+="**Density**: $(echo "scale=2; $DESCRIPTIVE_PHRASES / $LINES" | bc) phrases per line\n\n"
    
    REPORT_SECTION+="## Sample Descriptive Sections\n"
    # Extract sample descriptive paragraphs
    DESCRIPTIVE_SAMPLES=$(echo "$CONTENT" | grep -i -B2 -A2 -E "(appears|looks like|appearance|layout|position|size|color|spacing|animation)" | head -10 || true)
    if [ -n "$DESCRIPTIVE_SAMPLES" ]; then
        REPORT_SECTION+="\`\`\`\n$DESCRIPTIVE_SAMPLES\n\`\`\`\n"
    else
        REPORT_SECTION+="No descriptive samples found.\n"
    fi
    
    REPORT_SECTION+="\n## Recommendations\n"
    if (( $(echo "$OVERALL_SCORE < 50" | bc -l) )); then
        REPORT_SECTION+="❌ **Poor blind visualization**\n"
        REPORT_SECTION+="- Add detailed descriptions of visual elements\n"
        REPORT_SECTION+="- Use blind visualization indicators\n"
        REPORT_SECTION+="- Describe UI elements for non-visual understanding\n"
    elif (( $(echo "$OVERALL_SCORE < 75" | bc -l) )); then
        REPORT_SECTION+="⚠️ **Moderate blind visualization**\n"
        REPORT_SECTION+="- Increase descriptive content\n"
        REPORT_SECTION+="- Add more blind visualization indicators\n"
        REPORT_SECTION+="- Improve sequence and timing descriptions\n"
    else
        REPORT_SECTION+="✅ **Good blind visualization**\n"
        REPORT_SECTION+="- Maintain current level of detail\n"
        REPORT_SECTION+="- Consider adding auditory/tactile alternatives\n"
        REPORT_SECTION+="- Verify all visual elements are described\n"
    fi
    
    REPORT_SECTIONS+=("$REPORT_SECTION")
done

# Calculate overall average score
if [ ${#SCORES[@]} -gt 0 ]; then
    SUM=0
    for score in "${SCORES[@]}"; do
        SUM=$(echo "$SUM + $score" | bc)
    done
    AVERAGE_SCORE=$(echo "scale=1; $SUM / ${#SCORES[@]}" | bc)
else
    AVERAGE_SCORE=0
fi

# Generate final report
cat << EOF > "$OUTPUT"
# Blind-Person Visualization Assessment Report
=============================================
Generated: $TIMESTAMP
Total Files Analyzed: $TOTAL_FILES
Average Blind Visualization Score: ${AVERAGE_SCORE}%

## Overview

This report assesses whether the specification is detailed enough for a blind
person to visualize and understand the entire system. The "blind-person visualization"
standard requires specifications to be so detailed that someone who cannot see
can fully comprehend the system's appearance, behavior, and interactions.

## Assessment Criteria

A specification meets blind-person visualization standards when:

1. **UI/UX is describable without sight** - Layout, colors, spacing, animations
2. **System interactions are comprehensible** - User flows, data transformations
3. **Error states are clearly defined** - Recovery procedures, error messages
4. **Data flows are visualizable** - How data moves through the system
5. **API sequences are understandable** - Request/response timing and ordering
6. **Component relationships are mappable** - Architecture and dependencies
7. **Animation behavior is describable** - Timing, transitions, effects
8. **Layout is precisely defined** - Exact dimensions, positions, spacing
9. **Color usage is documented** - For non-visual understanding
10. **Auditory/tactile alternatives considered** - For inclusive design

## Overall Assessment

**Average Score**: ${AVERAGE_SCORE}%

**Status**: $(
if (( $(echo "$AVERAGE_SCORE >= 75" | bc -l) )); then
    echo "✅ **MEETS BLIND VISUALIZATION STANDARDS**"
elif (( $(echo "$AVERAGE_SCORE >= 50" | bc -l) )); then
    echo "⚠️ **PARTIALLY MEETS STANDARDS**"
else
    echo "❌ **DOES NOT MEET STANDARDS**"
fi
)

**Summary**: $(
if (( $(echo "$AVERAGE_SCORE >= 75" | bc -l) )); then
    echo "The specification is sufficiently detailed for blind-person visualization."
elif (( $(echo "$AVERAGE_SCORE >= 50" | bc -l) )); then
    echo "The specification has some blind visualization elements but needs improvement."
else
    echo "The specification lacks sufficient detail for blind-person visualization."
fi
)

## Detailed File Analysis

EOF

# Add each file's report section
for section in "${REPORT_SECTIONS[@]}"; do
    echo -e "$section" >> "$OUTPUT"
    echo "---" >> "$OUTPUT"
done

# Add improvement guidelines
cat << EOF >> "$OUTPUT"
## How to Improve Blind Visualization

### 1. Add Detailed Visual Descriptions
For each UI element, describe:
- **Position**: Exact location relative to other elements
- **Size**: Dimensions in pixels or relative units
- **Appearance**: Colors, borders, shadows, transparency
- **Behavior**: How it responds to interaction
- **Animation**: Timing, easing, duration, effects

Example:
\`\`\`
The login button appears in the top-right corner of the screen,
20 pixels from the top edge and 30 pixels from the right edge.
It measures 120 pixels wide by 40 pixels tall. The button has a
solid blue background (#0066CC) with white text. When hovered,
the background lightens to #0088EE over 200ms with ease-out easing.
When clicked, it darkens to #0044AA for 100ms before returning.
\`\`\`

### 2. Describe System Interactions Narratively
Write step-by-step narratives of user interactions:
- **Before action**: System state
- **Action**: What the user does
- **Immediate response**: Visual/auditory feedback
- **Transition**: How the system changes state
- **Result**: New system state

### 3. Define Error States Comprehensively
For each error condition:
- **Cause**: What triggers the error
- **Visual indication**: How it appears
- **User notification**: What the user sees/hears
- **Recovery steps**: How to resolve
- **Fallback behavior**: Alternative workflows

### 4. Map Data Flows Visually
Describe data movement:
- **Source**: Where data originates
- **Transformation**: How it changes
- **Destination**: Where it ends up
- **Timing**: When transformations occur
- **Dependencies**: What other data affects it

### 5. Specify API Sequences Precisely
For API interactions:
- **Request order**: Sequence of calls
- **Timing**: When each call occurs
- **Dependencies**: Which calls depend on others
- **Error handling**: What happens if calls fail
- **Retry logic**: How failures are handled

### 6. Use Blind Visualization Indicators
Include phrases that signal blind visualization:
- "A blind person could visualize..."
- "Describe without seeing..."
- "Imagine the interface..."
- "Visualize the data flow..."
- "Picture the component relationships..."

## Validation Test

To validate blind visualization, have someone (or an AI) read the specification
and attempt to:

1. Draw the UI layout based only on the description
2. Describe user interactions without seeing the interface
3. Explain error recovery procedures
4. Map data flows through the system
5. Understand component relationships

If they can accurately perform these tasks, the specification meets the standard.

## Next Steps

1. **Review low-scoring files** and add detailed descriptions
2. **Run adversarial refinement** with blind visualization focus
3. **Test with actual blind visualization** exercise
4. **Update specification** based on findings
5. **Re-run assessment** to measure improvement

## Conclusion

Blind-person visualization is the gold standard for exhaustive specifications.
When a specification meets this standard, it means every aspect of the system
is described with such detail that nothing is left to visual imagination.
This enables autonomous AI agents to build the system exactly as intended,
without ambiguity or interpretation.

**Target Score**: ≥75% for production-ready exhaustive specifications.
EOF

echo "✅ Blind-person visualization report generated: $OUTPUT" >&2
echo "" >&2
echo "Overall Score: ${AVERAGE_SCORE}%" >&2
echo "Status: $(
if (( $(echo "$AVERAGE_SCORE >= 75" | bc -l) )); then
    echo "✅ Meets blind visualization standards"
elif (( $(echo "$AVERAGE_SCORE >= 50" | bc -l) )); then
    echo "⚠️ Partially meets standards"
else
    echo "❌ Does not meet standards"
fi
)" >&2
echo "" >&2
echo "Review the report for detailed recommendations and improvement guidelines." >&2