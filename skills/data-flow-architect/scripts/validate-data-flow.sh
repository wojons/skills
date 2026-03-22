#!/bin/bash
set -euo pipefail
trap 'echo "Error on line $LINENO" >&2; exit 1' ERR

echo "Data Flow Documentation Validator"
echo "================================"
echo ""

validate_spec_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "Error: Directory not found: $dir" >&2
        exit 1
    fi
    if [[ "$dir" =~ \.\. ]]; then
        echo "Error: Directory path contains invalid characters" >&2
        exit 1
    fi
}

check_table_populated() {
    local file="$1"
    local section="$2"
    
    # Find section and extract content until next section
    local section_start=$(grep -n "^## $section$" "$file" 2>/dev/null | head -1 | cut -d: -f1)
    
    if [ -z "$section_start" ]; then
        echo "⚠ Warning: Section not found: $section"
        return 1
    fi
    
    # Count non-header, non-separator table rows after section
    local data_rows=$(tail -n +$((section_start + 1)) "$file" 2>/dev/null | awk '/^## [^#]/{exit} /^\|/{count++} END{print count+0}')
    
    if [ "$data_rows" -lt 1 ]; then
        echo "⚠ Warning: $section table appears empty (no data rows)"
        return 1
    fi
    echo "✓ $section section populated"
    return 0
}

SPEC_DIR=""
LEVEL="container"

while [[ $# -gt 0 ]]; do
    case $1 in
        --spec-dir)
            SPEC_DIR="$2"
            shift 2
            ;;
        --level)
            LEVEL="$2"
            shift 2
            ;;
        --help)
            echo "Usage: validate-data-flow.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --spec-dir DIR    Directory containing data flow documentation"
            echo "  --level LEVEL    Validation level (context, container, component)"
            echo ""
            echo "Example:"
            echo '  ./validate-data-flow.sh --spec-dir "./docs/data-flows"'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$SPEC_DIR" ]; then
    echo "Error: --spec-dir is required"
    exit 1
fi

validate_spec_dir "$SPEC_DIR"

echo "Validating data flow documentation in: $SPEC_DIR"
echo "Level: $LEVEL"
echo ""

PASS_COUNT=0
FAIL_COUNT=0
WARNINGS=()

# Check for required files
REQUIRED_FILES=("data-flow-architecture.md" "container-level.md" "validation-checklist.md")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$SPEC_DIR/$file" ]; then
        echo "✓ Found: $file"
        ((PASS_COUNT++))
    else
        echo "✗ Missing: $file"
        ((FAIL_COUNT++))
    fi
done

echo ""

# Check for consistency in naming
echo "Checking naming consistency..."

ARCH_FILE="$SPEC_DIR/data-flow-architecture.md"
if [ -f "$ARCH_FILE" ]; then
    # Extract component patterns (Service, DB, Cache, Queue, Gateway, etc.)
    COMPONENTS=$(grep -oE '\b[A-Z][a-zA-Z]+ (Service|DB|Database|Cache|Queue|Gateway|API|Server|Worker)\b' "$ARCH_FILE" 2>/dev/null | sort -u)
    COMPONENT_COUNT=$(echo "$COMPONENTS" | grep -c . 2>/dev/null || echo 0)
    
    if [ "$COMPONENT_COUNT" -gt 0 ]; then
        echo "✓ Found $COMPONENT_COUNT unique components in architecture doc"
        ((PASS_COUNT++))
    fi
    
    # Check for inconsistent naming patterns
    if grep -qE 'Auth Service|Authentication Service' "$ARCH_FILE" && ! grep -qE 'Auth Service.*Authentication Service|Authentication Service.*Auth Service' "$ARCH_FILE"; then
        :
    elif grep -qE 'Auth Service' "$ARCH_FILE" && grep -qE 'Authentication Service' "$ARCH_FILE"; then
        echo "⚠ Warning: Inconsistent naming detected (Auth Service vs Authentication Service)"
        WARNINGS+=("Inconsistent naming: 'Auth Service' vs 'Authentication Service'")
    fi
fi

echo ""

# Check for completeness
echo "Checking documentation completeness..."

check_table_populated "$ARCH_FILE" "Data Sources" && ((PASS_COUNT++)) || ((FAIL_COUNT++))
check_table_populated "$ARCH_FILE" "Data Destinations" && ((PASS_COUNT++)) || ((FAIL_COUNT++))
check_table_populated "$ARCH_FILE" "Data Flows" && ((PASS_COUNT++)) || ((FAIL_COUNT++))

if grep -q "^## Storage Architecture" "$ARCH_FILE"; then
    echo "✓ Storage architecture section exists"
    ((PASS_COUNT++))
else
    echo "✗ Storage architecture section missing"
    ((FAIL_COUNT++))
fi

echo ""

# Check for security documentation
echo "Checking security documentation..."

if grep -qi "authentication\|authorization\|security" "$ARCH_FILE"; then
    echo "✓ Security considerations documented"
    ((PASS_COUNT++))
else
    echo "✗ Security considerations missing"
    ((FAIL_COUNT++))
fi

if grep -qi "encryption\|TLS\|SSL\|HTTPS" "$ARCH_FILE"; then
    echo "✓ Encryption documented"
    ((PASS_COUNT++))
else
    echo "⚠ Warning: Encryption not documented"
    WARNINGS+=("Encryption/TLS not documented")
fi

if grep -qi "error handling\|retry\|fallback\|circuit breaker" "$ARCH_FILE"; then
    echo "✓ Error handling documented"
    ((PASS_COUNT++))
else
    echo "⚠ Warning: Error handling not documented"
    WARNINGS+=("Error handling not documented")
fi

echo ""

# Check for compliance documentation
echo "Checking compliance documentation..."

if [ -f "$SPEC_DIR/compliance-data-flows.md" ]; then
    echo "✓ Compliance documentation found"
    ((PASS_COUNT++))
    
    if grep -qi "PII\|data classification\|GDPR\|HIPAA" "$SPEC_DIR/compliance-data-flows.md"; then
        echo "✓ Data privacy compliance documented"
        ((PASS_COUNT++))
    else
        echo "⚠ Warning: PII/GDPR compliance not documented"
        WARNINGS+=("PII/GDPR compliance not documented")
    fi
else
    echo "⚠ Warning: No compliance documentation found"
    WARNINGS+=("No compliance-data-flows.md for GDPR/HIPAA")
fi

echo ""

# Check for diagrams
echo "Checking diagram coverage..."

if [ -f "$SPEC_DIR/data-flow-diagram.mmd" ]; then
    echo "✓ Mermaid diagram found"
    ((PASS_COUNT++))
    
    # Basic Mermaid syntax validation
    if grep -q "^graph " "$SPEC_DIR/data-flow-diagram.mmd"; then
        echo "✓ Mermaid diagram has valid structure"
    else
        echo "⚠ Warning: Mermaid diagram may have syntax issues"
        WARNINGS+=("Mermaid diagram structure unclear")
    fi
else
    echo "⚠ Warning: No Mermaid diagram found"
    WARNINGS+=("No Mermaid diagram for visual documentation")
fi

echo ""

# Check for edge cases documentation
echo "Checking edge cases..."

if grep -qi "retry\|fallback\|circuit breaker\|dead letter" "$ARCH_FILE"; then
    echo "✓ Resilience patterns documented"
    ((PASS_COUNT++))
else
    echo "⚠ Warning: Resilience patterns (retry, circuit breaker) not documented"
    WARNINGS+=("Resilience patterns not documented")
fi

if grep -qi "multi-region\|failover\|DR\|disaster recovery" "$ARCH_FILE"; then
    echo "✓ Disaster recovery flows documented"
    ((PASS_COUNT++))
else
    echo "⚠ Warning: DR/failover flows not documented"
    WARNINGS+=("Disaster recovery flows not documented")
fi

echo ""

# Check for circular dependencies (simple heuristic)
if [ -f "$ARCH_FILE" ]; then
    # Check if any component appears to call itself directly
    if grep -qE "->.*\1|" "$SPEC_DIR/data-flow-diagram.mmd" 2>/dev/null; then
        echo "⚠ Warning: Possible circular dependency detected in diagram"
        WARNINGS+=("Circular dependency detected")
    fi
fi

echo ""
echo "================================"
echo "Validation Summary"
echo "================================"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "Warnings: ${#WARNINGS[@]}"

if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo ""
    echo "Warnings:"
    for warning in "${WARNINGS[@]}"; do
        echo "  ⚠ $warning"
    done
fi

echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo "⚠ Validation passed with warnings - review recommended"
        exit 0
    else
        echo "✅ Validation passed!"
        exit 0
    fi
else
    echo "❌ Validation failed with $FAIL_COUNT issues"
    exit 1
fi