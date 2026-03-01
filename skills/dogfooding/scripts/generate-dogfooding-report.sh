#!/bin/bash
set -e

echo "Dogfooding: Report Generation" >&2
echo "==============================" >&2

usage() {
    echo "Usage: $0 [OPTIONS]" >&2
    echo "Options:" >&2
    echo "  --input FILES         JSON report files to aggregate (comma-separated)" >&2
    echo "  --directory DIR       Directory containing JSON reports" >&2
    echo "  --output FILE         Output file for aggregated report (default: dogfooding-aggregated-$(date +%Y%m%d).json)" >&2
    echo "  --format FORMAT       Output format: json, markdown, text (default: json)" >&2
    echo "  --help                Show this help message" >&2
    exit 1
}

INPUT_FILES=""
INPUT_DIR=""
OUTPUT="dogfooding-aggregated-$(date +%Y%m%d).json"
FORMAT="json"

while [[ $# -gt 0 ]]; do
    case $1 in
        --input)
            INPUT_FILES="$2"
            shift 2
            ;;
        --directory)
            INPUT_DIR="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
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

# Validate output file path
if [[ "$OUTPUT" =~ \.\.|^/ ]]; then
    echo "Error: Output file path cannot contain '..' or start with '/'" >&2
    exit 1
fi

# Collect input files
FILES=()

if [ -n "$INPUT_FILES" ]; then
    IFS=',' read -ra FILES <<< "$INPUT_FILES"
fi

if [ -n "$INPUT_DIR" ]; then
    if [ ! -d "$INPUT_DIR" ]; then
        echo "Error: Directory '$INPUT_DIR' does not exist" >&2
        exit 1
    fi
    # Add all JSON files from directory
    while IFS= read -r -d '' file; do
        FILES+=("$file")
    done < <(find "$INPUT_DIR" -name "*.json" -type f -print0 2>/dev/null)
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "Error: No input files specified" >&2
    usage
fi

echo "Aggregating ${#FILES[@]} report file(s)..." >&2
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Warning: File '$file' does not exist, skipping" >&2
    else
        echo "  • $file" >&2
    fi
done
echo "" >&2

# Initialize aggregation data
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)
TOTAL_REPORTS=0
TOTAL_SKILLS_VALIDATED=0
INSTALLATION_PASS_SUM=0
INSTALLATION_FAIL_SUM=0
FUNCTIONALITY_PASS_SUM=0
FUNCTIONALITY_FAIL_SUM=0
CROSS_VALIDATION_PASS_SUM=0
CROSS_VALIDATION_FAIL_SUM=0
OVERALL_SCORE_SUM=0
FAILED_SKILLS=()
WARNINGS=()

# Process each file
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    ((TOTAL_REPORTS++))
    
    # Extract data from JSON using jq if available, otherwise use grep
    if command -v jq > /dev/null 2>&1; then
        TOTAL_SKILLS_VALIDATED=$((TOTAL_SKILLS_VALIDATED + $(jq -r '.dogfooding_validation.total_skills_validated // 0' "$file" 2>/dev/null || echo 0)))
        INSTALLATION_PASS_SUM=$((INSTALLATION_PASS_SUM + $(jq -r '.dogfooding_validation.results.installation_validation.pass // 0' "$file" 2>/dev/null || echo 0)))
        INSTALLATION_FAIL_SUM=$((INSTALLATION_FAIL_SUM + $(jq -r '.dogfooding_validation.results.installation_validation.fail // 0' "$file" 2>/dev/null || echo 0)))
        FUNCTIONALITY_PASS_SUM=$((FUNCTIONALITY_PASS_SUM + $(jq -r '.dogfooding_validation.results.functionality_testing.pass // 0' "$file" 2>/dev/null || echo 0)))
        FUNCTIONALITY_FAIL_SUM=$((FUNCTIONALITY_FAIL_SUM + $(jq -r '.dogfooding_validation.results.functionality_testing.fail // 0' "$file" 2>/dev/null || echo 0)))
        CROSS_VALIDATION_PASS_SUM=$((CROSS_VALIDATION_PASS_SUM + $(jq -r '.dogfooding_validation.results.cross_skill_validation.pass // 0' "$file" 2>/dev/null || echo 0)))
        CROSS_VALIDATION_FAIL_SUM=$((CROSS_VALIDATION_FAIL_SUM + $(jq -r '.dogfooding_validation.results.cross_skill_validation.fail // 0' "$file" 2>/dev/null || echo 0)))
        SCORE=$(jq -r '.dogfooding_validation.overall_score // 0' "$file" 2>/dev/null || echo 0)
        OVERALL_SCORE_SUM=$(echo "$OVERALL_SCORE_SUM + $SCORE" | bc)
        
        # Extract failed skills if present
        if jq -e '.dogfooding_validation.failed_skills' "$file" >/dev/null 2>&1; then
            while IFS= read -r skill; do
                FAILED_SKILLS+=("$skill")
            done < <(jq -r '.dogfooding_validation.failed_skills[]' "$file" 2>/dev/null)
        fi
    else
        # Fallback: simple grep extraction
        echo "⚠️  jq not available, using basic aggregation" >&2
        WARNINGS+=("jq not available, using basic aggregation")
        
        # Just count files for demo purposes
        TOTAL_SKILLS_VALIDATED=$((TOTAL_SKILLS_VALIDATED + 1))
    fi
done

# Calculate averages
if [ $TOTAL_REPORTS -gt 0 ]; then
    AVG_INSTALL_PASS=$(echo "scale=1; $INSTALLATION_PASS_SUM / $TOTAL_REPORTS" | bc 2>/dev/null || echo 0)
    AVG_INSTALL_FAIL=$(echo "scale=1; $INSTALLATION_FAIL_SUM / $TOTAL_REPORTS" | bc 2>/dev/null || echo 0)
    AVG_FUNC_PASS=$(echo "scale=1; $FUNCTIONALITY_PASS_SUM / $TOTAL_REPORTS" | bc 2>/dev/null || echo 0)
    AVG_FUNC_FAIL=$(echo "scale=1; $FUNCTIONALITY_FAIL_SUM / $TOTAL_REPORTS" | bc 2>/dev/null || echo 0)
    AVG_CROSS_PASS=$(echo "scale=1; $CROSS_VALIDATION_PASS_SUM / $TOTAL_REPORTS" | bc 2>/dev/null || echo 0)
    AVG_CROSS_FAIL=$(echo "scale=1; $CROSS_VALIDATION_FAIL_SUM / $TOTAL_REPORTS" | bc 2>/dev/null || echo 0)
    AVG_OVERALL_SCORE=$(echo "scale=1; $OVERALL_SCORE_SUM / $TOTAL_REPORTS" | bc 2>/dev/null || echo 0)
else
    AVG_INSTALL_PASS=0
    AVG_INSTALL_FAIL=0
    AVG_FUNC_PASS=0
    AVG_FUNC_FAIL=0
    AVG_CROSS_PASS=0
    AVG_CROSS_FAIL=0
    AVG_OVERALL_SCORE=0
fi

# Remove duplicate failed skills
if [ ${#FAILED_SKILLS[@]} -gt 0 ]; then
    UNIQUE_FAILED_SKILLS=($(printf "%s\n" "${FAILED_SKILLS[@]}" | sort -u))
else
    UNIQUE_FAILED_SKILLS=()
fi

# Generate output based on format
case "$FORMAT" in
    json)
        cat << EOF > "$OUTPUT"
{
  "dogfooding_aggregated_report": {
    "timestamp": "$TIMESTAMP",
    "total_reports_aggregated": $TOTAL_REPORTS,
    "total_skills_validated": $TOTAL_SKILLS_VALIDATED,
    "aggregated_results": {
      "installation_validation": {
        "average_pass": $AVG_INSTALL_PASS,
        "average_fail": $AVG_INSTALL_FAIL,
        "total_pass": $INSTALLATION_PASS_SUM,
        "total_fail": $INSTALLATION_FAIL_SUM
      },
      "functionality_testing": {
        "average_pass": $AVG_FUNC_PASS,
        "average_fail": $AVG_FUNC_FAIL,
        "total_pass": $FUNCTIONALITY_PASS_SUM,
        "total_fail": $FUNCTIONALITY_FAIL_SUM
      },
      "cross_skill_validation": {
        "average_pass": $AVG_CROSS_PASS,
        "average_fail": $AVG_CROSS_FAIL,
        "total_pass": $CROSS_VALIDATION_PASS_SUM,
        "total_fail": $CROSS_VALIDATION_FAIL_SUM
      }
    },
    "overall_score_average": $AVG_OVERALL_SCORE,
    "quality_assessment": "$(if (( $(echo "$AVG_OVERALL_SCORE >= 90" | bc -l 2>/dev/null) )); then echo "excellent"; elif (( $(echo "$AVG_OVERALL_SCORE >= 80" | bc -l 2>/dev/null) )); then echo "good"; elif (( $(echo "$AVG_OVERALL_SCORE >= 70" | bc -l 2>/dev/null) )); then echo "fair"; else echo "needs improvement"; fi)",
    "failed_skills_unique": [
      $(if [ ${#UNIQUE_FAILED_SKILLS[@]} -gt 0 ]; then
          printf '"%s",' "${UNIQUE_FAILED_SKILLS[@]}" | sed 's/,$//'
      fi)
    ],
    "failed_skills_count": ${#UNIQUE_FAILED_SKILLS[@]},
    "warnings": [
      $(if [ ${#WARNINGS[@]} -gt 0 ]; then
          printf '"%s",' "${WARNINGS[@]}" | sed 's/,$//'
      fi)
    ],
    "recommendations": [
      "Review and fix failed skills: ${#UNIQUE_FAILED_SKILLS[@]} unique skills need attention",
      "Focus on installation failures first as they block skill usage",
      "Improve functionality testing for skills with low pass rates",
      "Enhance cross-skill validation to ensure ecosystem interoperability",
      "Establish regular aggregation of dogfooding reports for trend analysis"
    ],
    "source_reports": [
      $(printf '"%s",' "${FILES[@]}" | sed 's/,$//')
    ]
  }
}
EOF
        ;;
        
    markdown)
        cat << EOF > "$OUTPUT"
# Dogfooding Aggregated Report

**Generated**: $TIMESTAMP  
**Total Reports Aggregated**: $TOTAL_REPORTS  
**Total Skills Validated**: $TOTAL_SKILLS_VALIDATED  
**Overall Score Average**: ${AVG_OVERALL_SCORE}%

## Aggregated Results

### Installation Validation
- **Average Pass**: ${AVG_INSTALL_PASS}
- **Average Fail**: ${AVG_INSTALL_FAIL}
- **Total Pass**: $INSTALLATION_PASS_SUM
- **Total Fail**: $INSTALLATION_FAIL_SUM

### Functionality Testing
- **Average Pass**: ${AVG_FUNC_PASS}
- **Average Fail**: ${AVG_FUNC_FAIL}
- **Total Pass**: $FUNCTIONALITY_PASS_SUM
- **Total Fail**: $FUNCTIONALITY_FAIL_SUM

### Cross-Skill Validation
- **Average Pass**: ${AVG_CROSS_PASS}
- **Average Fail**: ${AVG_CROSS_FAIL}
- **Total Pass**: $CROSS_VALIDATION_PASS_SUM
- **Total Fail**: $CROSS_VALIDATION_FAIL_SUM

## Quality Assessment

**Overall Quality**: $(if (( $(echo "$AVG_OVERALL_SCORE >= 90" | bc -l 2>/dev/null) )); then echo "🟢 Excellent"; elif (( $(echo "$AVG_OVERALL_SCORE >= 80" | bc -l 2>/dev/null) )); then echo "🟡 Good"; elif (( $(echo "$AVG_OVERALL_SCORE >= 70" | bc -l 2>/dev/null) )); then echo "🟠 Fair"; else echo "🔴 Needs Improvement"; fi)

## Failed Skills

$(if [ ${#UNIQUE_FAILED_SKILLS[@]} -eq 0 ]; then
    echo "✅ No unique failed skills across all reports."
else
    echo "**${#UNIQUE_FAILED_SKILLS[@]} unique skills failed validation:**"
    for skill in "${UNIQUE_FAILED_SKILLS[@]}"; do
        echo "- $skill"
    done
fi)

## Warnings

$(if [ ${#WARNINGS[@]} -eq 0 ]; then
    echo "No warnings."
else
    for warning in "${WARNINGS[@]}"; do
        echo "- ⚠️ $warning"
    done
fi)

## Recommendations

1. **Review and fix failed skills** - ${#UNIQUE_FAILED_SKILLS[@]} unique skills need attention
2. **Focus on installation failures first** - These block skill usage entirely
3. **Improve functionality testing** - For skills with low pass rates
4. **Enhance cross-skill validation** - Ensure ecosystem interoperability
5. **Establish regular aggregation** - For trend analysis and continuous improvement

## Source Reports

$(for file in "${FILES[@]}"; do
    echo "- \`$file\`"
done)

## Continuous Dogfooding

To improve dogfooding effectiveness:

\`\`\`bash
# Run regular validation
./scripts/validate-dogfooding.sh --scope all --output validation-\$(date +%Y%m%d).json

# Aggregate weekly reports
./scripts/generate-dogfooding-report.sh --directory ./validation-reports --format markdown --output weekly-report.md
\`\`\`

**Next Steps**: Address the highest priority failures and establish automated dogfooding pipelines.
EOF
        ;;
        
    text)
        cat << EOF > "$OUTPUT"
DOGFOODING AGGREGATED REPORT
─────────────────────────────
Generated: $TIMESTAMP
Total Reports Aggregated: $TOTAL_REPORTS
Total Skills Validated: $TOTAL_SKILLS_VALIDATED
Overall Score Average: ${AVG_OVERALL_SCORE}%

AGGREGATED RESULTS:
──────────────────
Installation Validation:
  Average Pass: ${AVG_INSTALL_PASS}
  Average Fail: ${AVG_INSTALL_FAIL}
  Total Pass: $INSTALLATION_PASS_SUM
  Total Fail: $INSTALLATION_FAIL_SUM

Functionality Testing:
  Average Pass: ${AVG_FUNC_PASS}
  Average Fail: ${AVG_FUNC_FAIL}
  Total Pass: $FUNCTIONALITY_PASS_SUM
  Total Fail: $FUNCTIONALITY_FAIL_SUM

Cross-Skill Validation:
  Average Pass: ${AVG_CROSS_PASS}
  Average Fail: ${AVG_CROSS_FAIL}
  Total Pass: $CROSS_VALIDATION_PASS_SUM
  Total Fail: $CROSS_VALIDATION_FAIL_SUM

QUALITY ASSESSMENT:
──────────────────
Overall Quality: $(if (( $(echo "$AVG_OVERALL_SCORE >= 90" | bc -l 2>/dev/null) )); then echo "Excellent"; elif (( $(echo "$AVG_OVERALL_SCORE >= 80" | bc -l 2>/dev/null) )); then echo "Good"; elif (( $(echo "$AVG_OVERALL_SCORE >= 70" | bc -l 2>/dev/null) )); then echo "Fair"; else echo "Needs Improvement"; fi)

FAILED SKILLS:
──────────────
$(if [ ${#UNIQUE_FAILED_SKILLS[@]} -eq 0 ]; then
    echo "No unique failed skills across all reports."
else
    echo "${#UNIQUE_FAILED_SKILLS[@]} unique skills failed validation:"
    for skill in "${UNIQUE_FAILED_SKILLS[@]}"; do
        echo "  • $skill"
    done
fi)

WARNINGS:
─────────
$(if [ ${#WARNINGS[@]} -eq 0 ]; then
    echo "No warnings."
else
    for warning in "${WARNINGS[@]}"; do
        echo "  ⚠️ $warning"
    done
fi)

RECOMMENDATIONS:
────────────────
1. Review and fix failed skills: ${#UNIQUE_FAILED_SKILLS[@]} unique skills need attention
2. Focus on installation failures first as they block skill usage
3. Improve functionality testing for skills with low pass rates
4. Enhance cross-skill validation to ensure ecosystem interoperability
5. Establish regular aggregation of dogfooding reports for trend analysis

SOURCE REPORTS:
───────────────
$(for file in "${FILES[@]}"; do
    echo "  • $file"
done)

CONTINUOUS DOGFOODING:
──────────────────────
To improve dogfooding effectiveness:

Run regular validation:
  ./scripts/validate-dogfooding.sh --scope all --output validation-\$(date +%Y%m%d).json

Aggregate weekly reports:
  ./scripts/generate-dogfooding-report.sh --directory ./validation-reports --format markdown --output weekly-report.md

Next Steps: Address the highest priority failures and establish automated dogfooding pipelines.
EOF
        ;;
        
    *)
        echo "Error: Unknown format '$FORMAT'" >&2
        exit 1
        ;;
esac

echo "" >&2
echo "✅ Aggregated report generated: $OUTPUT" >&2
echo "Format: $FORMAT" >&2

# Show summary
echo "" >&2
echo "Report Summary:" >&2
echo "• Total reports aggregated: $TOTAL_REPORTS" >&2
echo "• Total skills validated: $TOTAL_SKILLS_VALIDATED" >&2
echo "• Overall score average: ${AVG_OVERALL_SCORE}%" >&2
echo "• Unique failed skills: ${#UNIQUE_FAILED_SKILLS[@]}" >&2
if [ ${#UNIQUE_FAILED_SKILLS[@]} -gt 0 ]; then
    echo "• Failed skills:" >&2
    for skill in "${UNIQUE_FAILED_SKILLS[@]:0:5}"; do
        echo "  - $skill" >&2
    done
    if [ ${#UNIQUE_FAILED_SKILLS[@]} -gt 5 ]; then
        echo "  ... and $(( ${#UNIQUE_FAILED_SKILLS[@]} - 5 )) more" >&2
    fi
fi