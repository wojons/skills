#!/bin/bash
set -e

echo "Exhaustive Specification Generation" >&2
echo "====================================" >&2

usage() {
    echo "Usage: $0 [OPTIONS]" >&2
    echo "Options:" >&2
    echo "  --domain DOMAIN        Application domain (e.g., turn-based-game, e-commerce, api-service)" >&2
    echo "  --purpose PURPOSE      System purpose (e.g., benchmark, production-app, research-project)" >&2
    echo "  --output-dir DIR       Output directory for specification files" >&2
    echo "  --adversarial-iterations N   Number of adversarial refinement iterations (default: 3)" >&2
    echo "  --adversary TYPES      Adversary types: devils-advocate, redteam, assumption-buster, all (default: all)" >&2
    echo "  --verbose              Enable verbose output" >&2
    echo "  --help                 Show this help message" >&2
    exit 1
}

DOMAIN=""
PURPOSE=""
OUTPUT_DIR=""
ADVERSARIAL_ITERATIONS=3
ADVERSARY="all"
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --purpose)
            PURPOSE="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --adversarial-iterations)
            ADVERSARIAL_ITERATIONS="$2"
            shift 2
            ;;
        --adversary)
            ADVERSARY="$2"
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

if [ -z "$DOMAIN" ] || [ -z "$PURPOSE" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Error: --domain, --purpose, and --output-dir are required" >&2
    usage
fi

# Validate output directory
if [[ "$OUTPUT_DIR" =~ \.\.|^/ ]]; then
    echo "Error: Output directory path cannot contain '..' or start with '/'" >&2
    exit 1
fi

echo "Generating exhaustive specification for:" >&2
echo "• Domain: $DOMAIN" >&2
echo "• Purpose: $PURPOSE" >&2
echo "• Output directory: $OUTPUT_DIR" >&2
echo "• Adversarial iterations: $ADVERSARIAL_ITERATIONS" >&2
echo "• Adversary types: $ADVERSARY" >&2
echo "" >&2

# Create output directory structure
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/components"
mkdir -p "$OUTPUT_DIR/references"
mkdir -p "$OUTPUT_DIR/validation"

TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)
SPEC_VERSION="1.0.0"

echo "Creating specification scaffold..." >&2

# Create master specification file
MASTER_SPEC="$OUTPUT_DIR/master-specification.md"
cat << EOF > "$MASTER_SPEC"
# EXHAUSTIVE SPECIFICATION: $DOMAIN - $PURPOSE
===============================================
Version: $SPEC_VERSION
Generated: $TIMESTAMP
Adversarial Iterations: $ADVERSARIAL_ITERATIONS
Total Lines: [TBD]
Coverage Score: [TBD]

## 1. SYSTEM PURPOSE & VISION

### 1.1 Why This System Exists
[Describe the fundamental reason for this system's existence]

### 1.2 Problems It Solves
[List specific problems this system addresses]

### 1.3 Perfect Implementation Vision
[Describe what "perfect" looks like for this domain]

### 1.4 Success Metrics
[Quantifiable metrics for success]

## 2. COMPREHENSIVE REQUIREMENTS

### 2.1 Functional Requirements
[Complete list of functional requirements]

### 2.2 Non-Functional Requirements
[Performance, scalability, security, reliability, maintainability]

### 2.3 User Experience Flows
[Complete user journeys and workflows]

### 2.4 Data Requirements
[Schema, storage, retrieval, processing, backup]

### 2.5 Integration Requirements
[External systems, APIs, protocols, formats]

### 2.6 Operational Requirements
[Monitoring, logging, alerting, deployment]

## 3. DETAILED DESIGN

### 3.1 Architecture
[System components, relationships, data flows]

### 3.2 UI/UX Design
[Mockups, interactions, animations, responsive behavior]

### 3.3 API Design
[Endpoints, request/response formats, error codes]

### 3.4 Database Design
[Schema, indexes, queries, migrations]

### 3.5 Algorithm Design
[Business logic, calculations, transformations]

### 3.6 Security Design
[Authentication, authorization, encryption, compliance]

## 4. IMPLEMENTATION GUIDE

### 4.1 Code Structure
[File organization, naming conventions, coding standards]

### 4.2 Dependencies
[Libraries, frameworks, versions, compatibility]

### 4.3 Configuration
[Environment variables, settings, feature flags]

### 4.4 Build & Deployment
[CI/CD pipelines, containerization, orchestration]

### 4.5 Testing Strategy
[Unit, integration, e2e, performance, security tests]

### 4.6 Documentation
[API docs, user guides, developer guides, troubleshooting]

## 5. VALIDATION SUITE

### 5.1 Test Cases
[Comprehensive test coverage for all requirements]

### 5.2 Performance Benchmarks
[Expected performance under various loads]

### 5.3 Security Audit Checklist
[Vulnerability assessments, penetration testing scenarios]

### 5.4 Compliance Verification
[Regulatory requirements, industry standards]

### 5.5 Assumption Validation Tests
[Tests for all documented assumptions]

## 6. ADVERSARIAL REFINEMENT LOG

### Iteration 1: Initial Draft
[Date: $TIMESTAMP]
[Status: Pending]

### Iteration 2: Devil's Advocate Challenges
[Date: Pending]
[Status: Pending]

### Iteration 3: Red Team Attacks
[Date: Pending]
[Status: Pending]

### Iteration 4: Assumption Testing
[Date: Pending]
[Status: Pending]

### Iteration 5: Reality Validation
[Date: Pending]
[Status: Pending]

### Iteration 6: Cross-Validation
[Date: Pending]
[Status: Pending]

### Iteration 7: Exhaustion Check
[Date: Pending]
[Status: Pending]

## 7. CROSS-REFERENCE INDEX

### Requirement → Design → Implementation → Test Mapping
[To be populated during refinement]

### Component Dependencies
[To be populated during refinement]

### File Relationships
[To be populated during refinement]

### Version Compatibility Matrix
[To be populated during refinement]
EOF

echo "✅ Master specification created: $MASTER_SPEC" >&2

# Create component spec templates
COMPONENTS=("ui-spec" "api-spec" "db-spec" "security-spec" "deployment-spec" "test-spec")

for component in "${COMPONENTS[@]}"; do
    COMPONENT_FILE="$OUTPUT_DIR/components/$component.md"
    cat << EOF > "$COMPONENT_FILE"
# $DOMAIN - $component Specification
=========================================
Version: $SPEC_VERSION
Generated: $TIMESTAMP
Domain: $DOMAIN
Purpose: $PURPOSE

## Overview
[Detailed specification for $component]

## Requirements
[Specific requirements for this component]

## Design Details
[Implementation design for this component]

## Implementation Guide
[Step-by-step implementation instructions]

## Validation Criteria
[How to validate this component meets requirements]

## Dependencies
[Other components this depends on]

## Adversarial Challenges
[To be populated during refinement]

## Revision History
- $TIMESTAMP: Initial draft created
EOF
    echo "✅ Component specification created: $COMPONENT_FILE" >&2
done

# Create adversarial refinement plan
REFINEMENT_PLAN="$OUTPUT_DIR/adversarial-refinement-plan.md"
cat << EOF > "$REFINEMENT_PLAN"
# Adversarial Refinement Plan
=============================
Domain: $DOMAIN
Purpose: $PURPOSE
Total Iterations: $ADVERSARIAL_ITERATIONS
Adversary Types: $ADVERSARY
Generated: $TIMESTAMP

## Iteration Schedule

### Iteration 1: Initial Specification Completion
**Goal**: Complete initial draft of all specification files
**Duration**: [TBD]
**Success Criteria**: All template sections filled with detailed content
**Adversary Involvement**: None

### Iteration 2: Devil's Advocate Review
**Goal**: Challenge every requirement and design decision
**Duration**: [TBD]
**Success Criteria**: No unchallenged assumptions remain
**Adversary Involvement**: devils-advocate skill
**Key Questions**:
- Why is this requirement needed?
- What if we didn't have this feature?
- What assumptions are we making?
- Are there contradictions or ambiguities?

### Iteration 3: Red Team Attack
**Goal**: Attack the system as an adversary
**Duration**: [TBD]
**Success Criteria**: All security vulnerabilities identified
**Adversary Involvement**: redteam skill
**Attack Vectors**:
- Security vulnerabilities
- Failure points under stress
- Edge cases and corner conditions
- Performance bottlenecks

### Iteration 4: Assumption Testing
**Goal**: Design tests for all documented assumptions
**Duration**: [TBD]
**Success Criteria**: Every assumption has validation test
**Adversary Involvement**: assumption-buster skill
**Process**:
1. Extract all assumptions from specifications
2. Design validation tests for each
3. Identify untestable assumptions for manual review

### Iteration 5: Reality Validation
**Goal**: Compare spec against real-world domain knowledge
**Duration**: [TBD]
**Success Criteria**: Spec aligns with domain expertise
**Adversary Involvement**: reality-validation skill
**Validation Sources**:
- Domain expert consultation
- Reference materials and documentation
- Similar successful systems analysis

### Iteration 6: Cross-Validation
**Goal**: Ensure alignment between all specification files
**Duration**: [TBD]
**Success Criteria**: No conflicts between component specs
**Adversary Involvement**: spec-gap-analysis skill
**Validation Areas**:
- Terminology consistency
- Requirement alignment
- Design compatibility
- Implementation coherence

### Iteration 7: Exhaustion Check
**Goal**: Verify nothing is left uncovered
**Duration**: [TBD]
**Success Criteria**: No gaps or ambiguities remain
**Adversary Involvement**: adversarial-thinking skill
**Final Questions**:
- Is there anything left uncovered?
- Can a blind person visualize the entire system?
- Are there any aspects left to chance or interpretation?

## Adversary Configuration

### Devil's Advocate
- **Skill**: devils-advocate
- **Focus**: Challenging assumptions, identifying contradictions
- **Output**: List of challenged assumptions and ambiguities

### Red Team
- **Skill**: redteam
- **Focus**: Security vulnerabilities, failure points
- **Output**: Security assessment and attack vectors

### Assumption Buster
- **Skill**: assumption-buster
- **Focus**: Identifying and testing implicit assumptions
- **Output**: Assumption validation test suite

### Reality Validation
- **Skill**: reality-validation
- **Focus**: Domain accuracy and real-world alignment
- **Output**: Domain alignment report

### Cross-Validation
- **Skill**: spec-gap-analysis
- **Focus**: Consistency across specification files
- **Output**: Cross-spec alignment report

## Success Metrics

### Quantitative Metrics
- **Coverage Score**: Percentage of system aspects covered
- **Assumption Count**: Number of explicit vs implicit assumptions
- **Edge Cases**: Number of documented edge cases
- **Test Coverage**: Percentage of requirements with validation tests

### Qualitative Metrics
- **Blind Visualization**: Can a blind person understand the system?
- **Autonomous Readiness**: Can AI agents build without human interpretation?
- **Adversarial Resilience**: Does the spec withstand adversarial challenges?
- **Domain Accuracy**: Does the spec match real-world expectations?

## Next Steps

1. **Complete Initial Draft**: Fill all template sections with exhaustive detail
2. **Run Adversarial Refinement**: Execute each iteration sequentially
3. **Update Specifications**: Incorporate feedback from each iteration
4. **Generate Final Report**: Document refinement process and outcomes
5. **Validate Autonomous Readiness**: Verify AI agents can use specs without human help

## Notes

- Each iteration should produce concrete improvements to the specifications
- Document all changes and rationale in the master specification
- Use cross-skill references to leverage existing adversarial thinking skills
- Aim for "exhaustion" - keep refining until nothing is left uncovered
EOF

echo "✅ Adversarial refinement plan created: $REFINEMENT_PLAN" >&2

# Create validation checklist
VALIDATION_CHECKLIST="$OUTPUT_DIR/validation/checklist.md"
cat << EOF > "$VALIDATION_CHECKLIST"
# Exhaustive Specification Validation Checklist
==============================================
Domain: $DOMAIN
Purpose: $PURPOSE
Generated: $TIMESTAMP

## Blind-Person Visualization Test
- [ ] UI/UX specifications detailed enough for blind visualization
- [ ] System interactions describable without sight
- [ ] Error states and recovery procedures clearly defined
- [ ] Data flows and transformations comprehensible
- [ ] API sequences and timing understandable

## Autonomous Readiness Test
- [ ] No ambiguous requirements requiring human interpretation
- [ ] All edge cases documented and handled
- [ ] Complete test coverage for all requirements
- [ ] Deployment and operations fully specified
- [ ] Monitoring and logging requirements detailed

## Adversarial Resilience Test
- [ ] Withstood devil's advocate challenges
- [ ] Survived red team security attacks
- [ ] All assumptions explicitly tested
- [ ] Reality validation against domain expertise
- [ ] Cross-validation across all component specs

## Implementation Completeness Test
- [ ] Database schema fully specified
- [ ] API endpoints and contracts defined
- [ ] UI components and interactions detailed
- [ ] Security implementation specified
- [ ] Performance requirements quantified

## Cross-Reference Integrity Test
- [ ] Requirements traceable to implementation
- [ ] Component dependencies mapped
- [ ] Version compatibility documented
- [ ] File relationships established
- [ ] Conflict resolution procedures defined

## Quantitative Metrics
- [ ] Coverage score calculated (target: >95%)
- [ ] Line count documented (target: >20,000 lines)
- [ ] Assumption count tracked
- [ ] Edge case count documented
- [ ] Test case count established

## Final Exhaustion Check
- [ ] Asked "Is there anything left uncovered?"
- [ ] Reviewed each component for completeness
- [ ] Verified no aspects left to chance
- [ ] Confirmed autonomous AI readiness
- [ ] Documented final validation results
EOF

echo "✅ Validation checklist created: $VALIDATION_CHECKLIST" >&2

echo "" >&2
echo "✅ Exhaustive specification scaffold created successfully!" >&2
echo "" >&2
echo "Next steps:" >&2
echo "1. Complete the initial draft by filling all template sections" >&2
echo "2. Run adversarial refinement using: ./scripts/run-adversarial-refinement.sh" >&2
echo "3. Validate completeness using: ./scripts/validate-spec-completeness.sh" >&2
echo "" >&2
echo "Remember: The goal is exhaustive detail - aim for 20,000+ lines of specification!" >&2
echo "Use adversarial thinking skills to challenge and refine until nothing is left uncovered." >&2