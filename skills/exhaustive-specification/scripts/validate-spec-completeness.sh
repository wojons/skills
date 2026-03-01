#!/bin/bash
set -e
shopt -s nullglob

echo "Exhaustive Specification Validation" >&2
echo "====================================" >&2

usage() {
    echo "Usage: $0 [OPTIONS]" >&2
    echo "Options:" >&2
    echo "  --spec-dir DIR          Directory containing specification files" >&2
    echo "  --validation-level LEVEL Validation level: basic, thorough, exhaustive (default: thorough)" >&2
    echo "  --output FILE           Output file for validation report (default: spec-validation-report.json)" >&2
    echo "  --verbose               Enable verbose output" >&2
    echo "  --help                  Show this help message" >&2
    exit 1
}

SPEC_DIR=""
VALIDATION_LEVEL="thorough"
OUTPUT="spec-validation-report.json"
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --spec-dir)
            SPEC_DIR="$2"
            shift 2
            ;;
        --validation-level)
            VALIDATION_LEVEL="$2"
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

if [ -z "$SPEC_DIR" ]; then
    echo "Error: --spec-dir is required" >&2
    usage
fi

if [ ! -d "$SPEC_DIR" ]; then
    echo "Error: Specification directory '$SPEC_DIR' does not exist" >&2
    exit 1
fi

echo "Validating exhaustive specification in: $SPEC_DIR" >&2
echo "Validation level: $VALIDATION_LEVEL" >&2
echo "Output file: $OUTPUT" >&2
echo "" >&2

TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)

# Check for required files
REQUIRED_FILES=("master-specification.md" "components/ui-spec.md" "components/api-spec.md" "components/db-spec.md" "components/security-spec.md" "components/deployment-spec.md" "components/test-spec.md")
OPTIONAL_FILES=("adversarial-refinement-plan.md" "validation/checklist.md")

MISSING_FILES=()
PRESENT_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$SPEC_DIR/$file" ]; then
        PRESENT_FILES+=("$file")
    else
        MISSING_FILES+=("$file")
    fi
done

# Count lines in specification files
TOTAL_LINES=0
FILE_COUNTS=()

for file in "$SPEC_DIR"/*.md "$SPEC_DIR"/components/*.md; do
    if [ -f "$file" ]; then
        lines=$(wc -l < "$file" 2>/dev/null || echo 0)
        TOTAL_LINES=$((TOTAL_LINES + lines))
        FILE_COUNTS+=("$(basename "$file"):$lines")
    fi
done

# Check for blind-person visualization indicators
BLIND_VISUALIZATION_INDICATORS=("visualize" "describe without seeing" "blind person" "detailed enough to imagine" "comprehensive description")
BLIND_SCORE=0
BLIND_FOUND=()

# Check for autonomous readiness indicators
AUTONOMOUS_INDICATORS=("autonomous" "without human" "no interpretation" "explicit" "unambiguous" "complete coverage")
AUTONOMOUS_SCORE=0
AUTONOMOUS_FOUND=()

# Check for adversarial refinement evidence
ADVERSARIAL_INDICATORS=("devil's advocate" "red team" "assumption" "challenge" "adversarial" "refinement")
ADVERSARIAL_SCORE=0
ADVERSARIAL_FOUND=()

# Check for Bible Standard indicators
BIBLE_STANDARD_INDICATORS=("deterministic" "identical implementation" "cross-implementation" "canonical" "bible standard" "implementation-agnostic" "test-driven" "no interpretation" "unambiguous")
BIBLE_STANDARD_SCORE=0
BIBLE_STANDARD_FOUND=()

# Analyze master specification
if [ -f "$SPEC_DIR/master-specification.md" ]; then
    MASTER_CONTENT=$(cat "$SPEC_DIR/master-specification.md")
    
    # Check for section completeness
    SECTIONS=("SYSTEM PURPOSE" "COMPREHENSIVE REQUIREMENTS" "DETAILED DESIGN" "IMPLEMENTATION GUIDE" "VALIDATION SUITE" "ADVERSARIAL REFINEMENT LOG" "CROSS-REFERENCE INDEX")
    SECTION_COUNT=0
    
    for section in "${SECTIONS[@]}"; do
        if echo "$MASTER_CONTENT" | grep -q "$section"; then
            ((SECTION_COUNT++))
        fi
    done
    
    # Check for blind visualization
    for indicator in "${BLIND_VISUALIZATION_INDICATORS[@]}"; do
        if echo "$MASTER_CONTENT" | grep -i -q "$indicator"; then
            ((BLIND_SCORE++))
            BLIND_FOUND+=("$indicator")
        fi
    done
    
    # Check for autonomous readiness
    for indicator in "${AUTONOMOUS_INDICATORS[@]}"; do
        if echo "$MASTER_CONTENT" | grep -i -q "$indicator"; then
            ((AUTONOMOUS_SCORE++))
            AUTONOMOUS_FOUND+=("$indicator")
        fi
    done
    
    # Check for adversarial refinement
    for indicator in "${ADVERSARIAL_INDICATORS[@]}"; do
        if echo "$MASTER_CONTENT" | grep -i -q "$indicator"; then
            ((ADVERSARIAL_SCORE++))
            ADVERSARIAL_FOUND+=("$indicator")
        fi
    done
    
    # Check for Bible Standard indicators
    for indicator in "${BIBLE_STANDARD_INDICATORS[@]}"; do
        if echo "$MASTER_CONTENT" | grep -i -q "$indicator"; then
            ((BIBLE_STANDARD_SCORE++))
            BIBLE_STANDARD_FOUND+=("$indicator")
        fi
    done
fi

# Calculate coverage scores
REQUIRED_FILES_COUNT=${#REQUIRED_FILES[@]}
PRESENT_FILES_COUNT=${#PRESENT_FILES[@]}
FILE_COVERAGE_PERCENT=$(echo "scale=1; $PRESENT_FILES_COUNT * 100 / $REQUIRED_FILES_COUNT" | bc)

SECTION_COVERAGE_PERCENT=$(echo "scale=1; $SECTION_COUNT * 100 / ${#SECTIONS[@]}" | bc)

# Calculate blind visualization score (max 5)
BLIND_SCORE_PERCENT=$(echo "scale=1; $BLIND_SCORE * 100 / ${#BLIND_VISUALIZATION_INDICATORS[@]}" | bc)

# Calculate autonomous readiness score (max 6)
AUTONOMOUS_SCORE_PERCENT=$(echo "scale=1; $AUTONOMOUS_SCORE * 100 / ${#AUTONOMOUS_INDICATORS[@]}" | bc)

# Calculate adversarial refinement score (max 6)
ADVERSARIAL_SCORE_PERCENT=$(echo "scale=1; $ADVERSARIAL_SCORE * 100 / ${#ADVERSARIAL_INDICATORS[@]}" | bc)

# Calculate Bible Standard score (max 9)
BIBLE_STANDARD_SCORE_PERCENT=$(echo "scale=1; $BIBLE_STANDARD_SCORE * 100 / ${#BIBLE_STANDARD_INDICATORS[@]}" | bc)

# Calculate overall score (weighted average)
OVERALL_SCORE=$(echo "scale=1; ($FILE_COVERAGE_PERCENT * 0.25) + ($SECTION_COVERAGE_PERCENT * 0.15) + ($BLIND_SCORE_PERCENT * 0.15) + ($AUTONOMOUS_SCORE_PERCENT * 0.15) + ($ADVERSARIAL_SCORE_PERCENT * 0.15) + ($BIBLE_STANDARD_SCORE_PERCENT * 0.15)" | bc)

# Determine validation level thresholds
case "$VALIDATION_LEVEL" in
    basic)
        PASS_THRESHOLD=60
        ;;
    thorough)
        PASS_THRESHOLD=75
        ;;
    exhaustive)
        PASS_THRESHOLD=90
        ;;
    *)
        PASS_THRESHOLD=75
        ;;
esac

# Determine pass/fail status
if (( $(echo "$OVERALL_SCORE >= $PASS_THRESHOLD" | bc -l) )); then
    VALIDATION_STATUS="pass"
else
    VALIDATION_STATUS="fail"
fi

# Generate validation report
cat << EOF > "$OUTPUT"
{
  "exhaustive_specification_validation": {
    "timestamp": "$TIMESTAMP",
    "spec_directory": "$SPEC_DIR",
    "validation_level": "$VALIDATION_LEVEL",
    "pass_threshold": $PASS_THRESHOLD,
    "overall_score": $OVERALL_SCORE,
    "validation_status": "$VALIDATION_STATUS",
    "file_analysis": {
      "required_files": $REQUIRED_FILES_COUNT,
      "present_files": $PRESENT_FILES_COUNT,
      "missing_files": [
        $(if [ ${#MISSING_FILES[@]} -gt 0 ]; then
            printf '"%s",' "${MISSING_FILES[@]}" | sed 's/,$//'
        fi)
      ],
      "file_coverage_percent": $FILE_COVERAGE_PERCENT,
      "total_lines": $TOTAL_LINES,
      "line_counts_by_file": [
        $(if [ ${#FILE_COUNTS[@]} -gt 0 ]; then
            for item in "${FILE_COUNTS[@]}"; do
                file="${item%:*}"
                lines="${item#*:}"
                printf '{"file": "%s", "lines": %s},' "$file" "$lines"
            done | sed 's/,$//'
        fi)
      ]
    },
    "content_analysis": {
      "section_coverage": {
        "required_sections": ${#SECTIONS[@]},
        "present_sections": $SECTION_COUNT,
        "coverage_percent": $SECTION_COVERAGE_PERCENT
      },
      "blind_visualization": {
        "score": $BLIND_SCORE,
        "max_possible": ${#BLIND_VISUALIZATION_INDICATORS[@]},
        "percent": $BLIND_SCORE_PERCENT,
        "indicators_found": [
          $(if [ ${#BLIND_FOUND[@]} -gt 0 ]; then
              printf '"%s",' "${BLIND_FOUND[@]}" | sed 's/,$//'
          fi)
        ]
      },
      "autonomous_readiness": {
        "score": $AUTONOMOUS_SCORE,
        "max_possible": ${#AUTONOMOUS_INDICATORS[@]},
        "percent": $AUTONOMOUS_SCORE_PERCENT,
        "indicators_found": [
          $(if [ ${#AUTONOMOUS_FOUND[@]} -gt 0 ]; then
              printf '"%s",' "${AUTONOMOUS_FOUND[@]}" | sed 's/,$//'
          fi)
        ]
      },
      "adversarial_refinement": {
        "score": $ADVERSARIAL_SCORE,
        "max_possible": ${#ADVERSARIAL_INDICATORS[@]},
        "percent": $ADVERSARIAL_SCORE_PERCENT,
        "indicators_found": [
          $(if [ ${#ADVERSARIAL_FOUND[@]} -gt 0 ]; then
              printf '"%s",' "${ADVERSARIAL_FOUND[@]}" | sed 's/,$//'
          fi)
        ]
      },
      "bible_standard": {
        "score": $BIBLE_STANDARD_SCORE,
        "max_possible": ${#BIBLE_STANDARD_INDICATORS[@]},
        "percent": $BIBLE_STANDARD_SCORE_PERCENT,
        "indicators_found": [
          $(if [ ${#BIBLE_STANDARD_FOUND[@]} -gt 0 ]; then
              printf '"%s",' "${BIBLE_STANDARD_FOUND[@]}" | sed 's/,$//'
          fi)
        ]
      }
    },
    "validation_criteria": {
      "file_coverage_weight": 0.25,
      "section_coverage_weight": 0.15,
      "blind_visualization_weight": 0.15,
      "autonomous_readiness_weight": 0.15,
      "adversarial_refinement_weight": 0.15,
      "bible_standard_weight": 0.15
    },
    "recommendations": [
      $(if [ ${#MISSING_FILES[@]} -gt 0 ]; then
          echo "\"Add missing required files: ${MISSING_FILES[*]}\","
      fi)
      $(if (( $(echo "$BLIND_SCORE_PERCENT < 70" | bc -l) )); then
          echo "\"Improve blind-person visualization indicators\","
      fi)
      $(if (( $(echo "$AUTONOMOUS_SCORE_PERCENT < 70" | bc -l) )); then
          echo "\"Enhance autonomous readiness indicators\","
      fi)
       $(if (( $(echo "$ADVERSARIAL_SCORE_PERCENT < 70" | bc -l) )); then
          echo "\"Add more adversarial refinement evidence\","
       fi)
       $(if (( $(echo "$BIBLE_STANDARD_SCORE_PERCENT < 70" | bc -l) )); then
          echo "\"Improve Bible Standard indicators (deterministic, canonical, implementation-agnostic)\","
       fi)
      $(if (( $(echo "$TOTAL_LINES < 20000" | bc -l) )); then
          echo "\"Increase specification detail (target: 20,000+ lines)\","
      fi)
      "Review and complete all specification sections",
      "Run adversarial refinement using adversarial thinking skills",
      "Validate cross-file consistency using spec-gap-analysis skill"
    ],
    "next_steps": [
      "Address missing files and low-scoring areas",
      "Run adversarial refinement: ./scripts/run-adversarial-refinement.sh",
      "Generate blind-visualization report: ./scripts/generate-blind-visualization.sh",
      "Validate with cross-skill integration"
    ]
  }
}
EOF

echo "Validation Results Summary:" >&2
echo "───────────────────────────" >&2
echo "Overall Score: ${OVERALL_SCORE}% (Threshold: ${PASS_THRESHOLD}%)" >&2
echo "Status: $([ "$VALIDATION_STATUS" = "pass" ] && echo "✅ PASS" || echo "❌ FAIL")" >&2
echo "" >&2
echo "File Coverage: ${FILE_COVERAGE_PERCENT}% (${PRESENT_FILES_COUNT}/${REQUIRED_FILES_COUNT} files)" >&2
if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "Missing files:" >&2
    for file in "${MISSING_FILES[@]}"; do
        echo "  • $file" >&2
    done
fi
echo "" >&2
echo "Total Lines: $TOTAL_LINES (target: 20,000+)" >&2
echo "" >&2
echo "Content Analysis:" >&2
echo "• Section Coverage: ${SECTION_COVERAGE_PERCENT}%" >&2
echo "• Blind Visualization: ${BLIND_SCORE_PERCENT}%" >&2
echo "• Autonomous Readiness: ${AUTONOMOUS_SCORE_PERCENT}%" >&2
echo "• Adversarial Refinement: ${ADVERSARIAL_SCORE_PERCENT}%" >&2
echo "• Bible Standard: ${BIBLE_STANDARD_SCORE_PERCENT}%" >&2
echo "" >&2

if [ "$VALIDATION_STATUS" = "fail" ]; then
    echo "❌ Specification does not meet exhaustive standards" >&2
    echo "Recommendations:" >&2
    if [ ${#MISSING_FILES[@]} -gt 0 ]; then
        echo "  • Add missing files" >&2
    fi
    if (( $(echo "$TOTAL_LINES < 20000" | bc -l) )); then
        echo "  • Increase detail (currently $TOTAL_LINES lines, target 20,000+)" >&2
    fi
    if (( $(echo "$BLIND_SCORE_PERCENT < 70" | bc -l) )); then
        echo "  • Improve blind-person visualization" >&2
    fi
    if (( $(echo "$BIBLE_STANDARD_SCORE_PERCENT < 70" | bc -l) )); then
        echo "  • Improve Bible Standard (deterministic, canonical specs)" >&2
    fi
    echo "" >&2
    exit 1
else
    echo "✅ Specification meets exhaustive standards!" >&2
    echo "Next steps: Run adversarial refinement and cross-validation." >&2
    echo "" >&2
fi

echo "📊 Detailed report saved to: $OUTPUT" >&2