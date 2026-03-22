---
name: baby-steps
description: Core operational directive for incremental development using the Baby Steps Methodology - break work into smallest possible meaningful changes with validation at every step
license: MIT
compatibility: opencode
metadata:
  audience: developers, AI agents, project managers
  category: methodology
---

# Baby Steps Methodology

Core operational directive for incremental development. Every action, every line of code, and every plan must adhere to the principle of taking the smallest possible meaningful step. **The process is the product.**

## When to use me

Use this skill when:
- Starting any new development task or feature
- Breaking down complex work into manageable pieces
- Debugging issues that require systematic approach
- Planning implementation strategies
- Working with AI agents to ensure precise execution
- Reducing risk in development workflows
- Teaching or learning development practices
- Ensuring reproducible, verifiable progress

## When NOT to Use Baby Steps

Do NOT use baby steps for:
- **Emergency hotfixes** - Use direct fix with expedited review; validate in staging/post-deploy
- **Trivial one-line changes** - Typos, comment updates, config tweaks where overhead exceeds value
- **Time-boxed spikes/exploratory work** - Learning requires messy, non-linear exploration
- **Pure configuration changes** - Environment variables, feature flags without code changes
- **Breaking API changes** - Some changes must be atomic (major version bumps, contract changes)
- **Crisis/incident response** - Business continuity takes priority over process purity

## Context Modes

Baby steps should be adapted to your context:

### Production Mode (Default)
- Full methodology with all six rules
- Comprehensive validation after each step
- Complete documentation

### Prototype Mode
- Time-boxed: 2-4 hours maximum
- Skip detailed documentation
- Goal: Learn/Explore/Prototype
- Output: Knowledge, not production code
- When complete: Either discard or baby-step the implementation

### Legacy Mode (Untested Codebases)
- Step 0: Add characterization tests before changing
- Use snapshot/approval testing to capture current behavior
- Validation: "Tests still pass" = "Behavior unchanged"
- Accept higher risk per step

### Crisis Mode (Incidents Only)
- Fix first, validate holistically, document after
- Skip step-by-step validation
- Requires post-incident review
- Log: Why crisis mode was necessary
- **Return to Production Mode immediately after resolution**

## The Six Rules (Guidelines, Not Laws)

### Rule 1: The Smallest Possible Meaningful Change
Break down any task into the smallest possible meaningful change. Never attempt to accomplish multiple things at once. Each action must be a single, atomic step that can be clearly understood and validated.

**Before:**
```
Task: Add user authentication
```

**After (Baby Steps):**
```
Step 1: Add password field to user model
Step 2: Create password hashing utility function
Step 3: Add login endpoint skeleton
Step 4: Implement password verification
Step 5: Add session token generation
Step 6: Create authentication middleware
Step 7: Add login UI form
Step 8: Connect form to endpoint
...
```

### Rule 2: The Process is the Product
The ultimate goal is to understand and demonstrate *how* a task is done. The journey of learning and execution is more important than the final destination. Documentation and clarity of process are deliverables.

**Anti-pattern:**
```javascript
// Committed without explanation
function process(x) { return x.map(v => v * 2).filter(v => v > 10); }
```

**Baby Steps approach:**
```javascript
// Step 1: Define what we're doing
// We need to double all values and keep only those > 10

// Step 2: Create the doubling transformation
function doubleValues(values) {
  return values.map(v => v * 2);
}

// Step 3: Create the filtering logic
function filterGreaterThanTen(values) {
  return values.filter(v => v > 10);
}

// Step 4: Compose the operations
function process(values) {
  const doubled = doubleValues(values);
  const filtered = filterGreaterThanTen(doubled);
  return filtered;
}

// Step 5: Add tests for each step
test('doubleValues doubles all values', () => {
  expect(doubleValues([1, 2, 3])).toEqual([2, 4, 6]);
});

test('filterGreaterThanTen keeps only > 10', () => {
  expect(filterGreaterThanTen([5, 10, 15, 20])).toEqual([15, 20]);
});
```

### Rule 3: One Substantive Accomplishment at a Time
Focus on one, and only one, substantive accomplishment at a time. Do not move on to a new task or component until the current one is fully complete.

**Wrong:**
```
- Adding user model
- Adding post model
- Creating API endpoints for both
- Writing tests for both
```

**Right (Baby Steps):**
```
Step 1: Create user model schema
  [PAUSE - validate user model works]
Step 2: Test user model CRUD operations
  [PAUSE - verify tests pass]
Step 3: Create post model schema
  [PAUSE - validate post model works]
...
```

### Rule 4: Complete Each Step Fully
Each step must be brought to a state of completion before starting the next. A step is not "done" until it is implemented, validated, and documented.

**Definition of Done:**
- Code written and follows project conventions
- Unit tests added and passing
- Code reviewed (self or peer)
- Documentation updated (proportional to step complexity)
- No regressions introduced
- Can be demonstrated/verified independently

### When Validation Fails (Recovery Protocol)

If a step fails validation after implementation:

1. **Stop immediately** - Do not proceed to next step
2. **Revert the change** - Use `git stash` or `git reset` to return to last known good state
3. **Diagnose the failure** - Why did validation fail?
4. **Choose recovery path**:
   - **Re-decompose**: The step was too large; break it down further
   - **Fix forward**: Make a targeted fix and re-validate
   - **Pivot**: The approach was wrong; try a different decomposition
5. **Document the failure** - Record what failed and why for future reference
6. **Resume with corrected approach** - Start the revised step from beginning

**Never leave a step in a "partially working" state.** A failed step should be reverted or fixed before proceeding.

### Rule 5: Incremental Validation is Mandatory
Validate work after every single step. Do not assume a change works. Verify it. This constant feedback loop is critical.

**Validation Checklist Per Step:**
```bash
# After each code change:
1. Run relevant tests
2. Check for compilation/linting errors
3. Verify the specific behavior changed
4. Confirm no side effects
5. Document the validation performed
```

**Example:**
```python
# Step: Add input validation to process_order()
def process_order(order):
    # NEW: Validate input
    if not order or 'items' not in order:
        raise ValueError("Invalid order: missing items")
    
    # ... rest of function

# IMMEDIATELY validate:
# 1. Unit test for valid order still passes
# 2. Unit test for invalid order now raises ValueError
# 3. Integration test for order processing still works
# 4. No other tests broken
```

### Rule 6: Document Every Step with Focus
Document every change with specific, focused detail. Changelogs and progress reports are not an afterthought; they are integral to the process.

**Step Documentation Template:**
```markdown
## Step N: [Clear Title]

**Goal**: What this step accomplishes
**Files Changed**: List of modified files
**Changes Made**:
- Specific change 1
- Specific change 2

**Validation**:
- [ ] Test X passes
- [ ] Test Y passes
- [ ] Manual verification: [description]

**Why This Approach**: Rationale for implementation choice
**Next Step**: What comes next and why
```

## The Baby Steps Workflow

### Phase 1: Decomposition
1. **State the goal clearly** - One sentence describing the end state
2. **Identify dependencies** - What must exist before starting
3. **Break into atomic steps** - Each step should be completable in 15-120 minutes
4. **Order by dependency** - Ensure proper sequencing
5. **Identify integration checkpoints** - Every 3-5 steps, plan cross-step validation

### Phase 2: Execution
For each step:
1. **State the step goal** - What specifically will be accomplished
2. **Implement minimally** - Only what's needed for this step
3. **Validate immediately** - Run tests, check behavior
4. **Document the change** - Record what and why
5. **Commit if appropriate** - Atomic commits per step

### Phase 3: Verification
After completing related steps:
1. **Integration check** - Do the steps work together?
2. **Regression check** - Did anything break?
3. **Documentation review** - Is the journey clear?

### Handling External Blockers

When a step cannot complete due to external dependencies:

1. **Mark step as BLOCKED** in progress tracking
2. **Document blocker details**: who/what is blocking, expected resolution
3. **Switch to independent step** - Work on unrelated component if possible
4. **Set reminder** to check blocker status daily
5. **Escalate if blocker exceeds 2 days** - Notify stakeholders of delay

**Never leave a step "in progress" indefinitely.** Either complete it, block it, or re-decompose around the blocker.

### Handling Interruptions

Development is interrupt-driven. When interrupted mid-step:

1. **Document current state** - What was done, what's pending
2. **Decide: commit or stash?**
   - If stable but incomplete → commit to feature branch with `WIP:` prefix
   - If broken/experimental → stash or discard
3. **Record context** - Why the step was started, what problem it solves
4. **On resumption** - Review documentation before continuing

**A step abandoned without documentation is lost work.**

## Time Guidelines

### Step Duration Targets
| Duration | Assessment |
|----------|------------|
| < 15 min | Too small - combine with related steps |
| 15-45 min | Ideal - focused, completable |
| 45-120 min | Acceptable - complex steps |
| > 2 hours | Too large - re-decompose |

### Under Time Pressure
- **Hotfix scenario**: Switch to Crisis Mode
- **Deadline approaching**: Increase step size slightly (accept more risk), never skip validation
- **Context switching imminent**: Complete current step if < 15 min remaining; stash otherwise

## Version Control Strategy

### Branching
- Create feature branch for multi-step tasks: `feature/user-authentication`
- Use atomic commits per step with format: `Step N: [description]`

### Commit Message Template
```
Step [N]: [Clear Title]

[What was accomplished]

Validation:
- [X] Unit tests pass
- [X] Manual verification completed
```

### When to Create Pull Requests
- **Simple changes**: PR after completing all steps
- **Complex features**: PR after each integration checkpoint (3-5 steps)
- **Never**: Combine unrelated steps in one PR

### Handling Code Review Feedback
1. Treat each review comment as a new baby step
2. Address comments one at a time
3. Validate each fix independently
4. Re-request review only when all comments resolved

## Examples

### Example 1: Adding a New Feature

**Goal**: Add email notifications for new orders

**Baby Steps Breakdown:**
```
Step 1: Create email template for order notification
  - File: templates/order_notification.html
  - Validate: Template renders with test data
  
Step 2: Create email sending utility
  - File: utils/email.py
  - Validate: Unit test sends to test inbox
  
Step 3: Add order notification trigger
  - File: services/orders.py
  - Validate: New order triggers email (checked in logs)
  
Step 4: Add configuration for notification settings
  - File: config.py
  - Validate: Settings can be toggled, behavior changes
  
Step 5: Add user preference for notifications
  - File: models/user.py
  - Validate: User can opt out, email not sent
  
Step 6: End-to-end test
  - Validate: Full flow works with real email service
```

### Example 2: Debugging an Issue

**Goal**: Fix "Order total is sometimes wrong" bug

**Baby Steps Investigation:**
```
Step 1: Reproduce the bug reliably
  - Document exact steps to reproduce
  - Validate: Bug occurs consistently
  
Step 2: Add logging to order total calculation
  - Log each component of the total
  - Validate: Logs capture the discrepancy
  
Step 3: Identify which component is wrong
  - Analyze logs to find discrepancy source
  - Validate: Clear culprit identified
  
Step 4: Write failing test for the bug
  - Test that should pass but fails
  - Validate: Test fails with bug, passes without
  
Step 5: Implement minimal fix
  - Only fix the identified issue
  - Validate: Test now passes
  
Step 6: Verify no regressions
  - Run all order-related tests
  - Validate: All tests pass
```

### Example 3: Refactoring Code

**Goal**: Refactor authentication module for clarity

**Baby Steps Approach:**
```
Step 1: Add comprehensive tests for current behavior
  - Validate: All tests pass with current code
  
Step 2: Extract password hashing to separate function
  - Validate: Tests still pass, behavior unchanged
  
Step 3: Extract token generation to separate function
  - Validate: Tests still pass, behavior unchanged
  
Step 4: Extract session management to separate module
  - Validate: Tests still pass, behavior unchanged
  
Step 5: Update imports and dependencies
  - Validate: Tests still pass, behavior unchanged
  
Step 6: Remove dead code from original module
  - Validate: Tests still pass, behavior unchanged
```

### Example 4: Refactoring Legacy Code (No Tests)

**Goal**: Refactor authentication module in untested legacy codebase

**Baby Steps with Characterization Tests:**
```
Step 1: Add characterization tests for current behavior
  - Use snapshot/approval testing to capture inputs/outputs
  - Don't change code yet - just observe and record
  - Validate: Tests capture current behavior (will fail when behavior changes)

Step 2: Extract password hashing to separate function
  - Minimal extraction, no logic changes
  - Validate: Characterization tests still pass (behavior unchanged)

Step 3: Add unit tests for extracted function
  - Now that it's isolated, add proper unit tests
  - Validate: Unit tests pass, characterization tests still pass

Step 4: Extract token generation to separate function
  - Validate: All tests still pass

Step 5: Continue with standard refactoring approach...
```

## Step Size Guidelines

### Too Big (Not Baby Steps)
- "Implement user authentication" - Multiple concerns
- "Fix all the bugs in payment processing" - Vague, unbounded
- "Refactor the codebase" - No clear scope

### Too Small (Inefficient)
- "Create file auth.py" - No meaningful progress
- "Add empty function login()" - No implementation
- "Write a comment" - Not a substantive change

### Just Right (Baby Steps)
- "Add password hashing function with tests" - Complete, atomic, verifiable
- "Fix null pointer in payment validation" - Clear scope, testable
- "Extract validation logic to separate function" - Single responsibility

## Anti-Pattern Detection

**WARNING: You may be misusing baby steps if:**

- Steps are artificially inflated (create file, add comment, write signature as separate steps)
- Documentation volume exceeds code volume 3:1
- More time spent planning than doing
- Team dreads the process
- Velocity metrics look good but features don't ship
- Used to avoid making decisions ("let's break it down more first...")
- Steps don't produce testable, demonstrable progress

**Recovery**: If you detect these patterns, recalibrate step sizes or switch to Prototype Mode.

## Team Coordination

### Parallel Baby Steps
When multiple developers work on related features:

1. **Coordinate decomposition** - Share step breakdowns to avoid conflicts
2. **Assign step ownership** - Who does which steps
3. **Define integration points** - When steps must combine
4. **Communication protocol**:
   - Step started → Notify team
   - Step completed → Update shared tracking
   - Blocker encountered → Immediate escalation

### Merge Conflict Prevention
- Rebase feature branch daily against main
- Avoid modifying same files in parallel steps
- When conflicts are inevitable, pair program the integration step

## Integration with Other Skills

- **@skills/stepwise-testing**: Validate each baby step with exhaustive testing
- **@skills/sherlock-debugging**: Use baby steps when investigating issues
- **@skills/trust-but-verify**: Verify each step independently
- **@skills/test-orchestrator**: Coordinate testing of incremental changes

## Output Format

### Step Completion Report
```
BABY STEPS PROGRESS
===================
Task: [Overall task description]
Step: [N] of [Total]
Status: [COMPLETE/IN PROGRESS/BLOCKED]

STEP N: [Step Title]
Goal: [What was accomplished]
Changes:
  - [file1]: [description]
  - [file2]: [description]
Validation:
  - [X] Unit tests pass (12 tests)
  - [X] Integration test pass (3 tests)
  - [X] Manual verification: [result]
  
Next Step: [What comes next]
Blockers: [Any blockers, or "None"]
```

## Notes

- **Resist the urge to combine steps** - Smaller is better, but not infinitesimally small
- **Each step should be commit-worthy** - Atomic commits per step
- **Validation is not optional** - Every step must be verified
- **Documentation is the artifact** - Future readers should understand the journey (proportional to complexity)
- **Speed comes from consistency** - Small steps prevent large rewrites
- **Embrace the pause** - The validation pause prevents cascade failures
- **Baby steps scale** - Even massive projects are built one step at a time
- **The methodology applies to debugging, features, refactoring, and learning**
- **Rules are guidelines, not laws** - Context matters; adapt to your situation
- **Methodology serves the work, not vice versa** - If baby steps are hurting more than helping, recalibrate

## Cost-Benefit Framework

Baby steps add ~20-40% overhead per step. This is **justified when**:
- Risk of failure > Overhead cost
- Code will be maintained long-term
- Team is learning the codebase
- Working on critical path

Baby steps are **NOT justified when**:
- Speed is critical and quality risk is low
- Exploratory/throwaway work
- Team has high trust and deep expertise
- Codebase has excellent test coverage
