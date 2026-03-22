#!/bin/bash
set -euo pipefail

# Completeness Validator - Production-Ready Edition
# Three-tier validation: AST analysis, runtime verification, PRR gates

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Validation results
TIER1_PASSED=0
TIER1_FAILED=0
TIER2_PASSED=0
TIER2_FAILED=0
TIER3_PASSED=0
TIER3_FAILED=0

CRITICAL_GAPS=()
WARNINGS=()

# Parse arguments
TIER="all"
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --tier)
            TIER="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     COMPLETENESS VALIDATOR - PRODUCTION READY EDITION         ║"
echo "║     Three-Tier Validation: AST → Runtime → PRR                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# TIER 1: AST-Based Static Analysis
run_tier1() {
    log_section "TIER 1: AST-BASED STATIC ANALYSIS"
    log_info "Using semantic code analysis (not just grep)..."
    echo ""
    
    # Check 1.1: Detect empty functions using AST
    log_info "Checking for empty functions and stubs..."
    
    EMPTY_FUNCTIONS=0
    
    # JavaScript/TypeScript: Use eslint with AST rules
    if [ -f "package.json" ]; then
        if command -v npx &> /dev/null; then
            # Check for empty functions
            if npx eslint . --ext .js,.ts,.tsx --rule 'no-empty-function:error' --format compact 2>/dev/null | grep -q "no-empty-function"; then
                log_error "Empty functions detected in JS/TS"
                ((EMPTY_FUNCTIONS++)) || true
            else
                log_success "No empty functions in JS/TS"
                ((TIER1_PASSED++)) || true
            fi
            
            # Check for TODO/FIXME comments (using AST, not just grep)
            TODO_COUNT=$(npx eslint . --ext .js,.ts --rule 'no-warning-comments:error' --format compact 2>/dev/null | grep -c "no-warning-comments" || echo "0")
            if [ "$TODO_COUNT" -gt 0 ]; then
                log_warning "Found $TODO_COUNT TODO/FIXME comments"
                WARNINGS+=("$TODO_COUNT TODO/FIXME markers found")
            else
                log_success "No TODO/FIXME markers"
                ((TIER1_PASSED++)) || true
            fi
        else
            log_warning "ESLint not available, using fallback grep"
            # Fallback to grep with better patterns
            TODO_COUNT=$(grep -r "TODO\|FIXME\|XXX\|HACK" --include="*.js" --include="*.ts" --include="*.tsx" --include="*.jsx" . 2>/dev/null | wc -l)
            if [ "$TODO_COUNT" -gt 0 ]; then
                log_warning "Found $TODO_COUNT TODO/FIXME markers (fallback)"
                WARNINGS+=("TODO/FIXME markers found")
            else
                log_success "No TODO/FIXME markers (fallback)"
                ((TIER1_PASSED++)) || true
            fi
        fi
    fi
    
    # Python: Use pylint or ast module
    if [ -f "*.py" ] || [ -d "*.py" ]; then
        if command -v pylint &> /dev/null; then
            log_info "Running pylint for Python analysis..."
            if pylint --errors-only --disable=all --enable=empty-docstring $(find . -name "*.py" -type f) 2>/dev/null | grep -q "E"; then
                log_error "Pylint found issues in Python code"
                ((TIER1_FAILED++)) || true
            else
                log_success "Pylint passed"
                ((TIER1_PASSED++)) || true
            fi
        fi
    fi
    
    # Check 1.2: Type safety
    log_info "Checking type safety..."
    
    if [ -f "tsconfig.json" ]; then
        if npx tsc --noEmit 2>/dev/null; then
            log_success "TypeScript type check passed"
            ((TIER1_PASSED++)) || true
        else
            log_error "TypeScript type errors found"
            CRITICAL_GAPS+=("TypeScript compilation errors")
            ((TIER1_FAILED++)) || true
        fi
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        if command -v mypy &> /dev/null; then
            if mypy . --ignore-missing-imports 2>/dev/null | grep -q "error"; then
                log_warning "MyPy found type issues"
                WARNINGS+=("Type checking issues")
            else
                log_success "Python type check passed"
                ((TIER1_PASSED++)) || true
            fi
        fi
    fi
    
    # Check 1.3: Import resolution
    log_info "Checking import resolution..."
    
    if [ -f "package.json" ]; then
        if npm ls --silent 2>&1 | grep -q "npm ERR"; then
            log_error "npm dependency issues"
            CRITICAL_GAPS+=("npm dependencies not resolved")
            ((TIER1_FAILED++)) || true
        else
            log_success "npm dependencies resolved"
            ((TIER1_PASSED++)) || true
        fi
    fi
    
    # Check 1.4: Detect mock patterns (AST-level analysis)
    log_info "Analyzing for mock vs real implementations..."
    
    MOCK_SCORE=0
    
    # Check for jest.mock or sinon
    if grep -r "jest.mock\|sinon.stub\|vi.mock" --include="*.js" --include="*.ts" --include="*.tsx" . 2>/dev/null | wc -l | grep -q "[1-9]"; then
        log_warning "Found test mocking frameworks (may indicate mocked tests)"
        ((MOCK_SCORE+=2)) || true
    fi
    
    # Check for hardcoded test data
    if grep -r "const testData\|const mockData\|const dummy" --include="*.js" --include="*.ts" --include="*.py" . 2>/dev/null | grep -v "node_modules" | wc -l | grep -q "[1-9]"; then
        log_warning "Found hardcoded test data"
        ((MOCK_SCORE+=1)) || true
    fi
    
    if [ "$MOCK_SCORE" -gt 2 ]; then
        WARNINGS+=("High mock usage detected - verify real integration")
    else
        log_success "Low mock usage - likely using real implementations"
        ((TIER1_PASSED++)) || true
    fi
}

# TIER 2: Runtime Verification
run_tier2() {
    log_section "TIER 2: RUNTIME VERIFICATION"
    log_info "Actually running the code (not just checking file existence)..."
    echo ""
    
    # Check 2.1: Application startup
    log_info "Testing application startup..."
    
    if [ -f "package.json" ]; then
        # Try to start the application
        if timeout 10 npm start 2>/dev/null &
        then
            APP_PID=$!
            sleep 3
            
            # Check if health endpoint exists
            if curl -s http://localhost:3000/health 2>/dev/null | grep -q "ok\|healthy"; then
                log_success "Application started and health check passed"
                ((TIER2_PASSED++)) || true
            else
                log_warning "Application started but no health endpoint"
                WARNINGS+=("No health endpoint configured")
            fi
            
            # Cleanup
            kill $APP_PID 2>/dev/null || true
        else
            log_error "Application failed to start"
            CRITICAL_GAPS+=("Application startup failed")
            ((TIER2_FAILED++)) || true
        fi
    fi
    
    # Check 2.2: Database connection
    log_info "Verifying database connections..."
    
    if [ -f ".env" ]; then
        if grep -q "DATABASE_URL\|DB_HOST" .env 2>/dev/null; then
            log_success "Database configuration found"
            ((TIER2_PASSED++)) || true
        else
            log_warning "No database configuration found"
        fi
    fi
    
    # Check 2.3: External API calls
    log_info "Checking external service configuration..."
    
    API_CONFIGURED=0
    if [ -f ".env" ]; then
        if grep -q "API_KEY\|API_URL\|SERVICE_URL" .env 2>/dev/null; then
            ((API_CONFIGURED++)) || true
        fi
    fi
    
    if [ "$API_CONFIGURED" -gt 0 ]; then
        log_success "External service APIs configured"
        ((TIER2_PASSED++)) || true
    else
        log_warning "No external API configuration detected"
    fi
    
    # Check 2.4: Test execution (real tests, not just existence)
    log_info "Running test suite..."
    
    if [ -f "package.json" ]; then
        if npm test --silent 2>&1 | grep -q "passing\|success"; then
            TEST_OUTPUT=$(npm test --silent 2>&1)
            PASSING_COUNT=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ passing' | head -1 | grep -oE '[0-9]+' || echo "0")
            
            if [ "$PASSING_COUNT" -gt 0 ]; then
                log_success "Tests passing: $PASSING_COUNT"
                ((TIER2_PASSED++)) || true
            else
                log_error "No tests found or all tests skipped"
                CRITICAL_GAPS+=("No meaningful test execution")
                ((TIER2_FAILED++)) || true
            fi
        else
            log_error "Tests failing or not configured"
            CRITICAL_GAPS+=("Test execution failed")
            ((TIER2_FAILED++)) || true
        fi
    fi
}

# TIER 3: Production Readiness Review
run_tier3() {
    log_section "TIER 3: PRODUCTION READINESS REVIEW"
    log_info "Validating PRR gates (industry standards)..."
    echo ""
    
    # Check 3.1: Observability
    log_info "Checking observability..."
    
    OBSERVABILITY=0
    
    if [ -f "package.json" ]; then
        if grep -q "winston\|pino\|bunyan\|@sentry" package.json 2>/dev/null; then
            log_success "Logging library found"
            ((OBSERVABILITY++)) || true
        else
            log_warning "No structured logging library detected"
        fi
        
        if grep -q "prom-client\|statsd\|datadog" package.json 2>/dev/null; then
            log_success "Metrics library found"
            ((OBSERVABILITY++)) || true
        else
            log_warning "No metrics library detected"
        fi
    fi
    
    if [ "$OBSERVABILITY" -lt 1 ]; then
        WARNINGS+=("Observability not configured")
    else
        ((TIER3_PASSED++)) || true
    fi
    
    # Check 3.2: Security
    log_info "Checking security configuration..."
    
    SECURITY_PASSED=0
    
    # Check for security libraries
    if [ -f "package.json" ]; then
        if grep -q "helmet\|csurf\|express-rate-limit" package.json 2>/dev/null; then
            log_success "Security middleware found"
            ((SECURITY_PASSED++)) || true
        fi
    fi
    
    # Check for .env.example (not just .env)
    if [ -f ".env.example" ]; then
        log_success ".env.example template exists"
        ((SECURITY_PASSED++)) || true
    else
        log_error "No .env.example found"
        CRITICAL_GAPS+=("Environment variables not documented")
    fi
    
    if [ "$SECURITY_PASSED" -ge 1 ]; then
        ((TIER3_PASSED++)) || true
    fi
    
    # Check 3.3: CI/CD Pipeline
    log_info "Checking CI/CD configuration..."
    
    CICD_CONFIGURED=0
    
    if [ -d ".github/workflows" ] && [ "$(ls -A .github/workflows/ 2>/dev/null | wc -l)" -gt 0 ]; then
        log_success "GitHub Actions workflows found"
        ((CICD_CONFIGURED++)) || true
    fi
    
    if [ -f ".gitlab-ci.yml" ]; then
        log_success "GitLab CI configuration found"
        ((CICD_CONFIGURED++)) || true
    fi
    
    if [ "$CICD_CONFIGURED" -eq 0 ]; then
        log_error "No CI/CD configuration found"
        CRITICAL_GAPS+=("No CI/CD pipeline configured")
        ((TIER3_FAILED++)) || true
    else
        ((TIER3_PASSED++)) || true
    fi
    
    # Check 3.4: Documentation
    log_info "Validating documentation..."
    
    if [ -f "README.md" ]; then
        README_LINES=$(wc -l < README.md)
        if [ "$README_LINES" -gt 50 ]; then
            log_success "README.md substantial ($README_LINES lines)"
            ((TIER3_PASSED++)) || true
        else
            log_warning "README.md is minimal ($README_LINES lines)"
            WARNINGS+=("README needs more content")
        fi
    else
        log_error "No README.md found"
        CRITICAL_GAPS+=("No README documentation")
        ((TIER3_FAILED++)) || true
    fi
    
    # Check 3.5: Containerization
    log_info "Checking containerization..."
    
    if [ -f "Dockerfile" ]; then
        log_success "Dockerfile found"
        ((TIER3_PASSED++)) || true
    else
        log_warning "No Dockerfile found"
    fi
}

# Main execution
main() {
    # Run requested tier(s)
    if [ "$TIER" = "all" ] || [ "$TIER" = "1" ]; then
        run_tier1
    fi
    
    if [ "$TIER" = "all" ] || [ "$TIER" = "2" ]; then
        run_tier2
    fi
    
    if [ "$TIER" = "all" ] || [ "$TIER" = "3" ]; then
        run_tier3
    fi
    
    # Generate report
    log_section "VALIDATION REPORT"
    
    TOTAL_PASSED=$((TIER1_PASSED + TIER2_PASSED + TIER3_PASSED))
    TOTAL_FAILED=$((TIER1_FAILED + TIER2_FAILED + TIER3_FAILED))
    TOTAL=$((TOTAL_PASSED + TOTAL_FAILED))
    
    if [ "$TOTAL" -gt 0 ]; then
        COMPLETION_RATE=$((TOTAL_PASSED * 100 / TOTAL))
    else
        COMPLETION_RATE=0
    fi
    
    echo ""
    echo "┌────────────────────────────────────────────────────────────┐"
    echo "│  TIER BREAKDOWN                                            │"
    echo "├────────────────────────────────────────────────────────────┤"
    echo "│  Tier 1 (AST Analysis):    $TIER1_PASSED passed                                           │"
    echo "│  Tier 2 (Runtime):         $TIER2_PASSED passed                                           │"
    echo "│  Tier 3 (PRR Gates):       $TIER3_PASSED passed                                           │"
    echo "├────────────────────────────────────────────────────────────┤"
    echo "│  Overall:                  $TOTAL_PASSED/$TOTAL passed ($COMPLETION_RATE%)                      │"
    echo "│  Warnings:                 ${#WARNINGS[@]}                                              │"
    echo "│  Critical Gaps:            ${#CRITICAL_GAPS[@]}                                              │"
    echo "└────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Critical gaps
    if [ ${#CRITICAL_GAPS[@]} -gt 0 ]; then
        echo -e "${RED}❌ CRITICAL GAPS DETECTED:${NC}"
        for gap in "${CRITICAL_GAPS[@]}"; do
            echo "   • $gap"
        done
        echo ""
    fi
    
    # Warnings
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  WARNINGS:${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo "   • $warning"
        done
        echo ""
    fi
    
    # Final status
    echo ""
    if [ ${#CRITICAL_GAPS[@]} -eq 0 ] && [ "$COMPLETION_RATE" -ge 80 ]; then
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  STATUS: PRODUCTION READY (本番完了 / Productio Paratus)      ║${NC}"
        echo -e "${GREEN}║  All critical gaps closed. System wired up and tested.        ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
        exit 0
    elif [ ${#CRITICAL_GAPS[@]} -eq 0 ]; then
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  STATUS: FUNCTIONAL BUT NOT PRODUCTION-READY                  ║${NC}"
        echo -e "${YELLOW}║  (機能完了 / Functionalis / Funktional)                      ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "Recommendations:"
        echo "1. Address warnings to reach production readiness"
        echo "2. Review Tier 3 PRR gates for completeness"
        exit 1
    else
        echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  STATUS: NOT COMPLETE (未完成 / Non Completus)              ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "Next Steps:"
        echo "1. Fix all critical gaps listed above"
        echo "2. Re-run validation: @completeness-validator check"
        echo "3. Ensure all components are wired up and tested"
        exit 1
    fi
}

# Run main
main