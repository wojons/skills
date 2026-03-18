#!/bin/bash
set -e

echo "Sherlock Holmes Debugging Session"
echo "=================================="
echo ""

# Check if case name is provided
if [ $# -eq 0 ]; then
    echo "Usage: sherlock-debug <case-name> [options]"
    echo ""
    echo "Options:"
    echo "  --priority <low|medium|high|critical>  Set case priority"
    echo "  --type <bug|performance|security>      Type of investigation"
    echo "  --template <basic|detailed>            Investigation template"
    echo ""
    echo "Example:"
    echo "  sherlock-debug login-failure-production --priority critical"
    echo ""
    exit 1
fi

CASE_NAME="$1"
PRIORITY="medium"
TYPE="bug"
TEMPLATE="detailed"

# Parse arguments
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --priority)
            PRIORITY="$2"
            shift 2
            ;;
        --type)
            TYPE="$2"
            shift 2
            ;;
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
CASE_DIR="./sherlock-cases/${CASE_NAME}"

# Create case directory
mkdir -p "$CASE_DIR"
mkdir -p "$CASE_DIR/evidence"
mkdir -p "$CASE_DIR/hypotheses"
mkdir -p "$CASE_DIR/elimination"

echo "Creating new investigation: $CASE_NAME"
echo "Priority: $PRIORITY"
echo "Type: $TYPE"
echo "Directory: $CASE_DIR"
echo ""

# Create case file
cat > "$CASE_DIR/case-file.md" << EOF
# Case: $CASE_NAME

**Opened**: $TIMESTAMP  
**Priority**: $PRIORITY  
**Type**: $TYPE  
**Status**: OPEN  
**Investigator**: $(whoami)

---

## Phase 1: The Observation Phase

> "It is a capital mistake to theorize before one has data."
> — Sherlock Holmes

### Initial Symptoms
[Document exactly what is happening. Be precise.]

### Environment Details
- OS: 
- Version: 
- Dependencies: 
- Recent Changes: 

### Timeline
- First observed: 
- Frequency: 
- Last occurrence: 

### Data Gathered
- [ ] Error logs
- [ ] Stack traces
- [ ] System metrics
- [ ] Configuration files
- [ ] Recent commits
- [ ] Environment variables

---

## Phase 2: The Analysis Phase

> "You see, but you do not observe. The distinction is clear."
> — Sherlock Holmes

### Patterns Identified
[What patterns do you see in the data?]

### Anomalies Detected
[What unusual things have you noticed?]

### Correlations
[What events always happen together?]

### Timeline Reconstruction
[Chronological order of events]

---

## Phase 3: The Hypothesis Phase

> "Data! Data! Data! I can't make bricks without clay."
> — Sherlock Holmes

### Possible Causes

#### Hypothesis 1: [Name]
- **Evidence For**: 
- **Evidence Against**: 
- **Test**: 
- **Status**: UNTESTED

#### Hypothesis 2: [Name]
- **Evidence For**: 
- **Evidence Against**: 
- **Test**: 
- **Status**: UNTESTED

#### Hypothesis 3: [Name]
- **Evidence For**: 
- **Evidence Against**: 
- **Test**: 
- **Status**: UNTESTED

---

## Phase 4: The Elimination Phase

> "When you have eliminated the impossible, whatever remains, however improbable, must be the truth."
> — Sherlock Holmes

### Elimination Checklist

- [ ] Database issues - Reason: 
- [ ] Network problems - Reason: 
- [ ] Memory/performance - Reason: 
- [ ] Configuration errors - Reason: 
- [ ] Logic errors - Reason: 
- [ ] External dependencies - Reason: 
- [ ] Race conditions - Reason: 
- [ ] Data corruption - Reason: 

### Testing Results

| Hypothesis | Test | Result | Ruled Out |
|------------|------|--------|-----------|
| | | | |

---

## The Solution

> "There is nothing more deceptive than an obvious fact."
> — Sherlock Holmes

### Root Cause
[What was the truth, however improbable?]

### Fix Applied
[What changes were made?]

### Verification
[How was it confirmed fixed?]

### Prevention
[How to prevent this in the future?]

---

## Lessons Learned

> "It has long been an axiom of mine that the little things are infinitely the most important."
> — Sherlock Holmes

### What Was Overlooked
[What did you miss initially?]

### Wrong Assumptions
[What did you assume incorrectly?]

### Key Insight
[What was the crucial observation?]

---

## Case Closed

**Closed**: [Date]  
**Resolution**: [FIXED/WORKAROUND/OPEN]  
**Time Invested**: [Duration]  

### Sherlock Holmes Principles Applied
- ✓ Eliminated the impossible systematically
- ✓ Data gathered before theory
- ✓ Little things mattered
- ✓ No guessing, only evidence
- ✓ Observation, not just seeing

---

**"I never guess. It is a shocking habit—destructive to the logical faculty."**
EOF

echo "✓ Case file created: $CASE_DIR/case-file.md"
echo ""

# Create evidence template
cat > "$CASE_DIR/evidence/README.md" << EOF
# Evidence for Case: $CASE_NAME

Place all evidence in this directory:
- Log files
- Screenshots
- Stack traces
- Configuration files
- Metrics data
- Database dumps

## Evidence Log

| File | Description | Date Added |
|------|-------------|------------|
| | | |

---

> "There is nothing like first-hand evidence."
> — Sherlock Holmes
EOF

echo "✓ Evidence directory created"
echo ""

# Create instructions
cat << EOF
## Next Steps

1. **Gather Data** (Phase 1)
   - Document symptoms precisely
   - Collect logs and metrics
   - Note environment details
   - Create reproduction steps

2. **Analyze** (Phase 2)
   - Look for patterns
   - Identify anomalies
   - Reconstruct timeline

3. **Form Hypotheses** (Phase 3)
   - List all possible causes
   - Gather evidence for each
   - Create test plans

4. **Eliminate** (Phase 4)
   - Test each hypothesis
   - Rule out impossibilities
   - Find the truth

## Useful Commands

# Add evidence
mv /path/to/logfile $CASE_DIR/evidence/

# Check assumptions
./scripts/verify-assumptions.sh --case $CASE_NAME

# Test hypothesis
./scripts/test-hypothesis.sh --case $CASE_NAME --hypothesis "database-timeout"

# Update case status
./scripts/update-case.sh $CASE_NAME --status "investigating"

## Remember

- "It is a capital mistake to theorize before one has data."
- "When you have eliminated the impossible, whatever remains, however improbable, must be the truth."
- "The little things are infinitely the most important."

Good luck, detective!
EOF

echo "Case opened. Begin your investigation in: $CASE_DIR"