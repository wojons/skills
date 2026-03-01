#!/bin/bash
set -e

echo "Adversarial Refinement for Exhaustive Specifications" >&2
echo "====================================================" >&2

usage() {
    echo "Usage: $0 [OPTIONS]" >&2
    echo "Options:" >&2
    echo "  --spec-file FILE       Master specification file to refine" >&2
    echo "  --spec-dir DIR         Directory containing all specification files" >&2
    echo "  --adversary TYPES      Comma-separated adversary types: devils-advocate,redteam,assumption-buster,reality-validation,cross-validation,bible-standard,all (default: all)" >&2
    echo "  --iterations N         Number of refinement iterations (default: 3)" >&2
    echo "  --output-dir DIR       Output directory for refinement reports (default: ./adversarial-refinement)" >&2
    echo "  --verbose              Enable verbose output" >&2
    echo "  --help                 Show this help message" >&2
    exit 1
}

SPEC_FILE=""
SPEC_DIR=""
ADVERSARY="all"
ITERATIONS=3
OUTPUT_DIR="./adversarial-refinement"
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
        --adversary)
            ADVERSARY="$2"
            shift 2
            ;;
        --iterations)
            ITERATIONS="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
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

# Determine which spec to use
if [ -n "$SPEC_FILE" ]; then
    SPEC_PATH="$SPEC_FILE"
    SPEC_BASE=$(dirname "$SPEC_FILE")
else
    SPEC_PATH="$SPEC_DIR/master-specification.md"
    SPEC_BASE="$SPEC_DIR"
    if [ ! -f "$SPEC_PATH" ]; then
        echo "Error: master-specification.md not found in $SPEC_DIR" >&2
        exit 1
    fi
fi

echo "Adversarial refinement configuration:" >&2
echo "• Specification: $SPEC_PATH" >&2
echo "• Specification directory: $SPEC_BASE" >&2
echo "• Adversary types: $ADVERSARY" >&2
echo "• Iterations: $ITERATIONS" >&2
echo "• Output directory: $OUTPUT_DIR" >&2
echo "" >&2

mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)
ITERATION=1

# Parse adversary types
if [ "$ADVERSARY" = "all" ]; then
    ADVERSARY_TYPES=("devils-advocate" "redteam" "assumption-buster" "reality-validation" "cross-validation" "bible-standard")
else
    IFS=',' read -ra ADVERSARY_TYPES <<< "$ADVERSARY"
fi

echo "Starting adversarial refinement with ${#ADVERSARY_TYPES[@]} adversary type(s)..." >&2
echo "" >&2

# Create refinement log
REFINEMENT_LOG="$OUTPUT_DIR/adversarial-refinement-log.md"
cat << EOF > "$REFINEMENT_LOG"
# Adversarial Refinement Log
===========================
Specification: $(basename "$SPEC_PATH")
Directory: $SPEC_BASE
Started: $TIMESTAMP
Adversary Types: ${ADVERSARY_TYPES[*]}
Total Iterations Planned: $ITERATIONS

## Summary

This log documents the adversarial refinement process for exhaustive specification.
Each iteration applies different adversarial thinking patterns to challenge and
improve the specification until nothing is left uncovered.

## Iteration Schedule

EOF

# Run refinement iterations
while [ $ITERATION -le $ITERATIONS ]; do
    echo "Iteration $ITERATION/$ITERATIONS" >&2
    echo "──────────────────────────────" >&2
    
    ITERATION_DIR="$OUTPUT_DIR/iteration-$ITERATION"
    mkdir -p "$ITERATION_DIR"
    
    ITERATION_START=$(date +%Y-%m-%dT%H:%M:%S)
    
    # Determine which adversary to use this iteration
    # Rotate through adversary types
    ADVERSARY_INDEX=$(( (ITERATION - 1) % ${#ADVERSARY_TYPES[@]} ))
    CURRENT_ADVERSARY="${ADVERSARY_TYPES[$ADVERSARY_INDEX]}"
    
    echo "Using adversary: $CURRENT_ADVERSARY" >&2
    echo "" >&2
    
    # Create iteration report
    ITERATION_REPORT="$ITERATION_DIR/report.md"
    
    case "$CURRENT_ADVERSARY" in
        devils-advocate)
            cat << EOF > "$ITERATION_REPORT"
# Iteration $ITERATION: Devil's Advocate Review
===============================================
Adversary: devils-advocate
Start Time: $ITERATION_START
Specification: $(basename "$SPEC_PATH")

## Purpose
Challenge every requirement, assumption, and design decision in the specification.
Identify contradictions, ambiguities, and unchallenged assumptions.

## Methodology
1. Load the specification: $SPEC_PATH
2. Apply devil's advocate thinking pattern
3. For each requirement, ask:
   - Why is this needed?
   - What if we didn't have this?
   - What assumptions are we making?
   - Are there contradictions with other requirements?
4. Document all challenges and ambiguities
5. Update specification based on findings

## Questions to Ask

### Challenge Every Requirement
- What is the fundamental purpose of this requirement?
- Can the system function without it?
- What are the consequences of removing it?
- Is there a simpler alternative?

### Identify Assumptions
- What assumptions are explicit in this requirement?
- What implicit assumptions are being made?
- How can each assumption be tested or validated?
- What happens if assumptions are wrong?

### Find Contradictions
- Does this requirement contradict any other requirement?
- Are there conflicting priorities or constraints?
- Do design decisions align with stated goals?
- Are there inconsistencies in terminology or approach?

### Challenge Design Decisions
- Why was this particular design chosen?
- What alternatives were considered?
- What are the trade-offs of this design?
- How does this design handle edge cases?

## Expected Output
1. List of challenged requirements with rationale
2. Documented assumptions (explicit and implicit)
3. Identified contradictions and ambiguities
4. Recommendations for specification improvements
5. Updated specification files

## How to Execute

### Using devils-advocate Skill
\`\`\`bash
# Load the devils-advocate skill
skill devils-advocate

# Provide the specification for review
# The skill will challenge assumptions and identify weaknesses
\`\`\`

### Manual Review Questions
1. Read through the entire specification
2. For each section, apply the questions above
3. Document findings in a structured format
4. Update the specification to address issues

## Success Criteria
- No requirement remains unchallenged
- All assumptions are explicitly documented
- Contradictions are resolved or acknowledged
- Specification clarity improves measurably

## Notes
- Be rigorous but constructive
- Focus on improving the specification, not just criticizing
- Document rationale for all challenges
- Update the adversarial refinement log in the master specification
EOF
            ;;
            
        redteam)
            cat << EOF > "$ITERATION_REPORT"
# Iteration $ITERATION: Red Team Attack
=======================================
Adversary: redteam
Start Time: $ITERATION_START
Specification: $(basename "$SPEC_PATH")

## Purpose
Attack the system specification as an adversary would.
Identify security vulnerabilities, failure points, and edge cases
that could be exploited or cause system failure.

## Methodology
1. Load the specification: $SPEC_PATH
2. Assume the role of a malicious actor
3. Identify attack vectors and vulnerabilities
4. Stress test performance assumptions
5. Document failure scenarios and edge cases
6. Update specification with security improvements

## Attack Vectors to Consider

### Security Vulnerabilities
- Authentication and authorization weaknesses
- Data injection points (SQL, command, XSS)
- Sensitive data exposure
- Insufficient input validation
- Broken access control
- Cryptographic weaknesses

### Failure Points
- Single points of failure
- Resource exhaustion scenarios
- Race conditions and timing issues
- Dependency failures
- Network partition scenarios
- Data corruption possibilities

### Edge Cases
- Extreme input values
- Boundary conditions
- Unusual user behavior
- Concurrent access conflicts
- Recovery from failure states
- Data consistency edge cases

### Performance Stress Tests
- Maximum load beyond specified limits
- Sustained high load over time
- Spikes in traffic or data volume
- Resource contention scenarios
- Degraded performance under attack

## Expected Output
1. List of identified security vulnerabilities
2. Documented failure scenarios
3. Edge case enumeration
4. Performance stress test results
5. Security improvement recommendations
6. Updated specification files

## How to Execute

### Using redteam Skill
\`\`\`bash
# Load the redteam skill
skill redteam

# Provide the specification for security review
# The skill will identify vulnerabilities and attack vectors
\`\`\`

### Manual Attack Simulation
1. Review specification from attacker's perspective
2. Identify all system entry points
3. Consider how each component could fail
4. Document exploitation scenarios
5. Update specification with mitigations

## Success Criteria
- All identified vulnerabilities have mitigation plans
- Failure scenarios are documented and addressed
- Edge cases are explicitly handled in specification
- Performance assumptions are stress-tested

## Notes
- Think like an attacker, not a defender
- Consider both technical and social engineering attacks
- Document worst-case scenarios
- Focus on practical exploitability
- Update security specifications accordingly
EOF
            ;;
            
        assumption-buster)
            cat << EOF > "$ITERATION_REPORT"
# Iteration $ITERATION: Assumption Buster
=========================================
Adversary: assumption-buster
Start Time: $ITERATION_START
Specification: $(basename "$SPEC_PATH")

## Purpose
Identify, document, and test all assumptions in the specification.
Ensure no assumptions remain implicit or untested.

## Methodology
1. Extract all assumptions from the specification
2. Categorize assumptions (explicit vs implicit)
3. Design validation tests for each assumption
4. Identify untestable assumptions for manual review
5. Update specification with assumption validation suite

## Assumption Categories

### Explicit Assumptions
- Clearly stated assumptions in the specification
- "We assume users have internet connectivity"
- "The system assumes database response time < 100ms"

### Implicit Assumptions
- Unstated assumptions that affect system behavior
- Cultural assumptions about users
- Technical assumptions about dependencies
- Business assumptions about market conditions

### Testable Assumptions
- Assumptions that can be validated through testing
- Performance assumptions
- User behavior assumptions
- Dependency availability assumptions

### Untestable Assumptions
- Assumptions that cannot be automatically tested
- Future market conditions
- User preference changes
- Regulatory environment changes

## Expected Output
1. Comprehensive list of all assumptions
2. Categorization of each assumption
3. Validation tests for testable assumptions
4. Manual review plan for untestable assumptions
5. Updated specification with assumption documentation

## How to Execute

### Using assumption-buster Skill
\`\`\`bash
# Load the assumption-buster skill
skill assumption-buster

# Provide the specification for assumption analysis
# The skill will identify and challenge assumptions
\`\`\`

### Manual Assumption Extraction
1. Read specification line by line
2. For each statement, ask "What is being assumed here?"
3. Document both explicit and implicit assumptions
4. Design validation approaches for each
5. Update assumption validation spec

## Success Criteria
- No implicit assumptions remain
- All assumptions are documented
- Testable assumptions have validation tests
- Untestable assumptions have review processes

## Notes
- Be thorough in assumption identification
- Consider cultural and contextual assumptions
- Design practical validation tests
- Document assumption evolution over time
EOF
            ;;
            
        reality-validation)
            cat << EOF > "$ITERATION_REPORT"
# Iteration $ITERATION: Reality Validation
===========================================
Adversary: reality-validation
Start Time: $ITERATION_START
Specification: $(basename "$SPEC_PATH")

## Purpose
Compare the specification against real-world domain knowledge.
Ensure the specification aligns with practical constraints,
domain expertise, and existing successful systems.

## Methodology
1. Identify domain experts or reference materials
2. Compare specification against real-world constraints
3. Validate technical feasibility
4. Check alignment with industry best practices
5. Update specification based on reality checks

## Validation Sources

### Domain Expertise
- Consult with subject matter experts
- Review domain-specific literature
- Analyze existing successful systems
- Consider practical constraints and limitations

### Technical Feasibility
- Validate technology choices
- Check performance expectations
- Verify integration possibilities
- Assess maintenance requirements

### Business Reality
- Market conditions and constraints
- User behavior and preferences
- Competitive landscape
- Regulatory environment

### Operational Reality
- Deployment and maintenance practicalities
- Team skills and capabilities
- Cost constraints and ROI expectations
- Timeline and resource limitations

## Expected Output
1. Domain alignment assessment
2. Technical feasibility review
3. Business reality check
4. Operational practicality evaluation
5. Updated specification with reality-based adjustments

## How to Execute

### Using reality-validation Skill
\`\`\`bash
# Load the reality-validation skill
skill reality-validation

# Provide the specification for reality checking
# The skill will compare against domain knowledge
\`\`\`

### Manual Reality Checking
1. Research domain best practices
2. Consult reference materials and documentation
3. Compare with similar successful systems
4. Validate against practical constraints
5. Update specification with reality-based refinements

## Success Criteria
- Specification aligns with domain expertise
- Technical choices are feasible
- Business assumptions are realistic
- Operational plans are practical

## Notes
- Be honest about constraints and limitations
- Consider both current and future reality
- Document validation sources and methods
- Update specification to reflect reality
EOF
            ;;
            
        cross-validation)
            cat << EOF > "$ITERATION_REPORT"
# Iteration $ITERATION: Cross-Validation
=========================================
Adversary: cross-validation
Start Time: $ITERATION_START
Specification: $(basename "$SPEC_PATH")

## Purpose
Ensure alignment and consistency across all specification files.
Check for conflicts, gaps, and inconsistencies between
different components of the specification.

## Methodology
1. Load all specification files from $SPEC_BASE
2. Check for terminology consistency
3. Validate requirement alignment
4. Verify design compatibility
5. Ensure implementation coherence
6. Update specifications to resolve conflicts

## Validation Areas

### Terminology Consistency
- Consistent naming conventions
- Unified glossary of terms
- Standardized abbreviations
- Clear definition of key concepts

### Requirement Alignment
- No conflicting requirements
- Complete requirement traceability
- Consistent priority levels
- Unified success criteria

### Design Compatibility
- Component interfaces align
- Data formats are consistent
- Protocol versions match
- Architecture patterns are coherent

### Implementation Coherence
- Coding standards are consistent
- Dependency versions align
- Configuration approaches are unified
- Deployment strategies are compatible

## Expected Output
1. Terminology consistency report
2. Requirement alignment assessment
3. Design compatibility check
4. Implementation coherence evaluation
5. Updated specifications with resolved conflicts

## How to Execute

### Using spec-gap-analysis Skill
\`\`\`bash
# Load the spec-gap-analysis skill
skill spec-gap-analysis

# Provide all specification files for cross-validation
# The skill will identify gaps and inconsistencies
\`\`\`

### Manual Cross-Validation
1. Create cross-reference matrix of all specs
2. Check each requirement across all files
3. Validate interface definitions match
4. Ensure consistent terminology
5. Update specs to resolve inconsistencies

## Success Criteria
- No terminology conflicts
- All requirements are aligned
- Designs are compatible
- Implementation is coherent
- Specification files are synchronized

## Notes
- Pay attention to interface boundaries
- Check both forward and backward compatibility
- Document all inconsistencies found
- Update version numbers if needed
EOF
            ;;
        bible-standard)
            cat << EOF > "$ITERATION_REPORT"
# Iteration $ITERATION: Bible Standard Validation
=================================================
Adversary: bible-standard
Start Time: $ITERATION_START
Specification: $(basename "$SPEC_PATH")

## Purpose
Validate that specifications meet the "Bible Standard" - canonical specifications that produce identical implementations across different AI systems, models, and languages. Ensure specs are deterministic, implementation-agnostic, and unambiguous.

## Methodology
1. Load the specification: $SPEC_PATH
2. Test for determinism: Would different AI systems produce identical implementations?
3. Check for implementation-agnostic language: Avoid framework/language biases
4. Verify test-driven specification: Are there executable tests in the spec?
5. Validate cross-implementation consistency: Would the spec produce the same observable behavior regardless of implementation choices?
6. Eliminate all ambiguity: Ensure no human interpretation needed

## Validation Criteria

### Deterministic Implementation
- Same specs should produce identical results across different AI systems
- Consistent behavior across models (GPT-4, Claude, Gemini, etc.)
- Consistent output across programming languages (Python, JavaScript, Go, etc.)
- Consistent results across coding harnesses (Cursor, Claude Code, OpenCode, etc.)

### Implementation-Agnostic Specifications
- Focus on behavior, not implementation details
- Avoid language-specific idioms or framework preferences
- Specify interfaces and contracts, not internal implementations
- Define observable behavior, not algorithmic steps

### Test-Driven Specification
- Include executable tests within the specification
- Define acceptance criteria with clear pass/fail conditions
- Create validation suites that any implementation must pass
- Specify edge cases and boundary conditions explicitly

### Cross-Implementation Consistency
- Would two different engineers get the same result?
- Would different AI coding agents produce identical systems?
- Are there any ambiguous instructions that could be interpreted differently?
- Does the spec rely on implicit knowledge or assumptions?

### Canonical Source Quality
- Is this specification the definitive "Bible" for this system?
- Would future versions build upon this exact specification?
- Are all requirements traceable and unambiguous?
- Is there a single source of truth for every aspect?

## Expected Output
1. Determinism assessment report
2. Implementation-agnostic language review
3. Test-driven specification evaluation
4. Cross-implementation consistency check
5. Updated specification with Bible Standard improvements

## How to Execute

### Using Bible Standard Validation
\`\`\`bash
# Apply Bible Standard thinking
# Focus on: determinism, canonical source, implementation-agnostic design
# Ask: "Would different AI systems produce identical implementations?"
\`\`\`

### Manual Bible Standard Validation
1. Read specification from perspective of different AI systems
2. Identify language or framework biases
3. Check for ambiguous or interpretable instructions
4. Verify tests are implementation-agnostic
5. Update spec to eliminate all ambiguity

## Success Criteria
- Specifications are deterministic across AI systems
- Language and framework biases eliminated
- Executable tests included in specification
- No ambiguous or interpretable instructions
- Canonical source quality achieved

## Notes
- Think like multiple different AI systems would
- Assume minimal shared context between implementers
- Eliminate all cultural or domain assumptions
- Create specs that are "foolproof" across implementations
EOF
            ;;
    esac
    
    echo "Iteration $ITERATION report created: $ITERATION_REPORT" >&2
    echo "Adversary: $CURRENT_ADVERSARY" >&2
    echo "" >&2
    
    # Add to refinement log
    cat << EOF >> "$REFINEMENT_LOG"
### Iteration $ITERATION: $CURRENT_ADVERSARY
**Start**: $ITERATION_START
**Adversary**: $CURRENT_ADVERSARY
**Report**: [iteration-$ITERATION/report.md](iteration-$ITERATION/report.md)

#### Objectives
$(grep -A 5 "## Purpose" "$ITERATION_REPORT" | tail -n +2 | sed 's/^/  /')

#### Status: Pending
**Next Action**: Execute the adversarial review using the guidelines in the report.
**Expected Output**: Updated specification files and findings document.

---
EOF
    
    # Ask user to execute this iteration
    echo "To execute iteration $ITERATION:" >&2
    echo "1. Review the report: $ITERATION_REPORT" >&2
    echo "2. Follow the execution guidelines in the report" >&2
    echo "3. Use the $CURRENT_ADVERSARY skill or manual review process" >&2
    echo "4. Update specification files based on findings" >&2
    echo "5. Document changes in the refinement log" >&2
    echo "" >&2
    
    if [ $ITERATION -lt $ITERATIONS ]; then
        echo "Press Enter to continue to next iteration, or Ctrl+C to stop..." >&2
        read -r
    fi
    
    ((ITERATION++))
done

echo "" >&2
echo "✅ Adversarial refinement planning complete!" >&2
echo "" >&2
echo "Generated files:" >&2
echo "• Refinement log: $REFINEMENT_LOG" >&2
echo "• Iteration reports: $OUTPUT_DIR/iteration-*/report.md" >&2
echo "" >&2
echo "Next steps:" >&2
echo "1. Execute each iteration following the reports" >&2
echo "2. Update specification files based on adversarial findings" >&2
echo "3. Run validation: ./scripts/validate-spec-completeness.sh" >&2
echo "4. Generate final refinement summary" >&2
echo "" >&2
echo "Remember: The goal is to refine until nothing is left uncovered!" >&2