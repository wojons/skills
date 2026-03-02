# Manual Loop Pattern (Slash Commands)

## Overview

The **Manual Loop Pattern** uses OpenCode's `/` slash commands to create semi-automated Ralph loops. Instead of running fully autonomous overnight sessions, the agent suggests or executes commands, the user sees results in their TUI, and decides to trigger the next iteration manually.

This pattern offers:
- **Transparency**: See every iteration in real-time
- **Control**: Decide when to continue or stop
- **Context**: Can ask questions about what happened
- **Flexibility**: Adjust approach mid-loop
- **Lower Complexity**: No need for complex orchestration

## How It Works

### Basic Pattern

```latex
User: "Build authentication system"
       ↓
Agent: Suggests "/build-auth"
       ↓
User: Presses Enter to execute
       ↓
Agent: Builds, shows results
       ↓
Agent: "Continue with /verify-auth?"
       ↓
User: Presses Enter or asks questions
       ↓
(Repeat until success)
```

### Command Definition

Define commands in `.opencode/commands/`:

```markdown
.opencode/commands/builder.md
---
description: Builder agent for authentication
agent: build
model: anthropic/claude-sonnet-4-20250514
---
Build the authentication system:
1. Create user models
2. Add login endpoint  
3. Add registration endpoint
4. Write tests

Output: <promise>AUTH_BUILT</promise>
```

```markdown
.opencode/commands/verifier.md
---
description: Verify authentication implementation
agent: plan
model: anthropic/claude-sonnet-4-20250514
---
Verify the build:
- Check code quality
- Run tests
- Review security

Output: <promise>AUTH_VERIFIED</promise> or <promise>NEEDS_FIXES:...</promise>
```

### User Interaction Flow

1. **Agent Suggests Command**:
   ```
   > I'll start by building the auth system. Run /builder?
   ```

2. **User Executes**:
   ```
   > /builder
   ```

3. **Agent Runs**:
   ```
   Building authentication system...
   ✓ Created User model
   ✓ Added login endpoint
   ✓ Added registration endpoint
   ✓ Wrote tests

   <promise>AUTH_BUILT</promise>
   ```

4. **Agent Suggests Next**:
   ```
   Auth system built. Next: /verifier or /continue?
   ```

5. **User Can**:
   - Press Enter to continue
   - Ask questions about what happened
   - Adjust parameters
   - Decide to stop or change approach

### Multi-Step Workflow

Define commands for each workflow step:

```bash
.opencode/commands/
├── 01-planner.md       # Plan the work
├── 02-builder.md       # Build implementation
├── 03-verifier.md      # Verify quality
├── 04-tester.md        # Run tests
└── 05-deployer.md      # Deploy
```

**Usage**:
```bash
> /01-planner
"Planning authentication system..."
<promise>PLAN_COMPLETE</promise>

> /02-builder
"Building auth..."
<promise>BUILD_IN_PROGRESS</promise>

[User sees code being written]

> /02-builder
"Continuing build..."
<promise>BUILD_COMPLETE</promise>

> /03-verifier
"Verifying..."
<promise>NEEDS_FIXES: Add error handling</promise>

> /02-builder
"Adding error handling..."
<promise>BUILD_COMPLETE</promise>

> /03-verifier
<promise>AUTH_VERIFIED</promise>

> /04-tester
"Running tests..."
<promise>TESTS_PASSED</promise>
```

## Advantages

### 1. Visibility
- Watch each iteration in real-time
- See code being written, tests running, errors occurring
- Understand what the agent is doing

### 2. Control
- Stop anytime by not pressing Enter
- Ask questions between iterations
- Override loop when needed

### 3. Debugging
- Can talk to the agent about errors
- Can adjust approach mid-flight
- Can see exactly what went wrong

### 4. Flexibility
- Mix automated and manual steps
- Decide to pause and think
- Adjust parameters between iterations

### 5. Lower Token Cost
- Only pay for iterations you run
- Can stop early if approach changes
- More efficient for learning/experimentation

## Disadvantages

### 1. Slower
- Need to manually trigger each iteration
- Can't run overnight unattended
- More hands-on time required

### 2. Less Autonomous
- Not true "night shift" capability
- Requires user presence
- Not for production automation

### 3. More Mental Overhead
- Need to monitor loop progress
- Must make decisions between iterations
- Can't "set and forget"

## Best Practices

### 1. Clear Command Names
Use numbered prefixes for order:
```bash
> /01-plan
> /02-build
> /03-verify
```

Or descriptive names:
```bash
> /auth-build-front
> /auth-build-back
> /auth-verify
```

### 2. Single Responsibility
Each command should do one thing:
```markdown
.opencode/commands/01-plan.md
---
description: Plan the work
---
Analyze requirements and create implementation plan
```

```markdown
.opencode/commands/02-build-schema.md
---
description: Build database schema
---
Create the database models and schema
```

### 3. Progress Indicators
Use promises for tracking:

```markdown
Output: 
<promise>STEP_1_COMPLETE</promise>
<promise>STEP_2_COMPLETE</promise>
<promise>OVERALL_COMPLETE</promise>
```

### 4. Exit Conditions
Define clear success conditions:

```markdown
When tests all pass, output:
<promise>ALL_TESTS_PASSED</promise>

Then suggest:
"Run /deploy or review changes?"
```

### 5. Error Handling
Loop with clear error messages:

```markdown
On error, output:
<promise>ERROR: Database connection failed</promise>

Then suggest retry:
"Run /02-build-schema again or change approach?"
```

## Configuration Pattern

YAML config for manual loops:

```yaml
pattern: manual-command-loop
workflow:
  commands:
    - name: planner
      file: .opencode/commands/01-planner.md
      order: 1
      
    - name: builder-schema
      file: .opencode/commands/02-builder-schema.md
      order: 2
      
    - name: builder-api
      file: .opencode/commands/03-builder-api.md
      order: 3
      
    - name: verifier
      file: .opencode/commands/04-verifier.md
      order: 4
      
    - name: tester
      file: .opencode/commands/05-tester.md
      order: 5
      
  loop:
    on_success: "Continue or deploy?"
    on_failure: "Retry or adjust approach?"
    
  interactive: true
  user_control: true
```

## Real-World Example

### Bug Fix Workflow

```markdown
.opencode/commands/01-reproduce.md
---
description: Reproduce the bug
---
I'll reproduce the authentication bug:
1. Check recent code changes
2. Identify the failing endpoint
3. Reproduce in tests

Output: <promise>BUG_REPRODUCED</promise>
```

```markdown
.opencode/commands/02-analyze.md
---
description: Analyze root cause
---
Analyze why authentication fails:
- Check code paths
- Review error logs
- Identify the bug

Output: <promise>ROOT_CAUSE_FOUND</promise>
```

```markdown
.opencode/commands/03-fix.md
---
description: Fix the bug
---
Fix the authentication bug:
- Implement the fix
- Add tests to prevent regression

Output: <promise>BUG_FIXED</promise>
```

### User Session

```
> /01-reproduce
Reproducing bug...
Checking code changes...
Found failing endpoint: /auth/login
<promise>BUG_REPRODUCED</promise>

Next: /02-analyze

> /02-analyze
Analyzing root cause...
Found issue: JWT token validation uses wrong secret
<promise>ROOT_CAUSE_FOUND</promise>

Next: /03-fix

> /03-fix
Fixing bug...
Updated JWT validation
Added test
<promise>BUG_FIXED</promise>

Run tests? [Y/n]

```

## When to Use

### ✅ Good for:
- Learning Ralph loops
- Debugging and experimentation
- Task requiring oversight
- New features (learning requirements)
- Cases where flexibility > speed

### ❌ Not for:
- Overnight builds
- Large refactorings
- Production deployments
- Fully automated workflows
- Time-critical tasks

## Tooling Integration

### With OpenCode Server

Can combine with `opencode serve` for even more visibility:

```bash
# Terminal 1: Start server
opencode serve --port 4242

# Terminal 2: Run loop
opencode
/01-planner
```

Monitor via web dashboard while running commands.

### With Task Tracking

Update todo lists via commands:

```markdown
.opencode/commands/mark-complete.md
---
description: Mark current task complete
---
Mark the current task complete in the todo list and move to next
```

```markdown
.opencode/commands/log-error.md
---
description: Log this error
---
Record this error to the error log for review later
```

## Pattern Comparison

| Pattern | Autonomy | Visibility | Control | Speed |
|---------|----------|------------|---------|-------|
| Simple Retry | High | Low | Low | Fast |
| Build+Verify | High | Medium | Low | Medium |
| Manual Command | Low | High | High | Slow |
| Human in Loop | Low | High | High | Slow |
| Adaptive | High | Medium | Low | Variable |

## Summary

The **Manual Command Loop Pattern** strikes a balance between automation and control:

- Agent handles execution and strategy
- User maintains oversight and decision-making
- Ideal for learning, debugging, and flexible workflows
- Not suitable for true "set and forget" scenarios

Use this when you want to:
- Understand what's happening
- Have the ability to intervene
- Learn Ralph loops before going autonomous
- Handle tasks requiring judgment

---

**Remember**: This pattern is all about transparency. The user sees the loop running in their TUI, can verify each step, and decides whether to continue or adjust.
