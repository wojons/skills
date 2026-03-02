# Git Hooks: Agent Guidance & Protection in Ralph Loops

## Overview

**Git hooks are the most powerful mechanism for Ralph loops** because they:

1. **Provide fixed logic** - Guardrails that models MUST follow
2. **Guide the model** - Explain failures, steer to right approach  
3. **Protect the system** - Prevent dangerous commits
4. **Capture failures** - Show exactly what went wrong

When the AI calls `git commit`, the hook can:
- ✅ Guide: "You forgot X, add it before committing"
- ✅ Protect: "Don't commit - this breaks production"
- ✅ Explain: "Here's the error, here's how to fix it"

This turns git hooks from **passive validators** into **active AI steering mechanisms**.

---

## Why Git Hooks Matter for Ralph Loops

### The Problem

Without hooks:
```
Agent: [ Builds feature ]
Agent: [ Writes tests ]
Agent: git commit
Result: Code may be broken, patterns may be broken, tests may fail
```

### The Solution  

With hooks:
```
Agent: [ Builds feature ]
Agent: [ Writes tests ]
Agent: git commit → Hook checks → FAILED
       ↓
Hook: "Missing error handling! Add try-catch blocks"
Agent: [ Adds error handling ]
Agent: git commit → Hook approves → SUCCESS
Result: Only good code gets committed
```

### Power of This Approach

**Not just validation** - hooks are **active guidance**:
- Tell model what it did wrong
- Show how to fix it
- Block commits of bad code
- Ensure quality standards

---

## How Agent Hooks Work

### Natural Language Hooks

Hooks can be written in **plain English** (like GitHub Actions but local):

```markdown
# .ralph/hooks/pre-commit
---
trigger: pre-commit
instructions: |
  Before allowing a commit, check for:
  1. No hardcoded secrets or API keys
  2. All new files have corresponding tests
  3. Code follows project's error handling pattern
  4. No console.log statements in production code
  
  If any issues found, reject commit and explain how to fix.
  
  Show me exactly what failed and what needs to be done.
---
```

This is much more powerful than traditional bash scripts - it's **AI agent steering**.

### Event-Based Triggers

Hooks trigger on:
- **pre-commit**: Before git commit
- **pre-push**: Before git push  
- **commit-msg**: Validate commit message
- **post-commit**: After successful commit
- **post-merge**: After merge operations
- **pre-rebase**: Before rebasing
- Manual triggers: Anytime

### Two Execution Modes

**Mode 1: Agent Prompt** (most powerful):
```yaml
action: agent_prompt
instructions: |
  Review changes and verify:
  - All new code has tests
  - No breaking changes
  - Follows our patterns
```

**Mode 2: Shell Command**:
```yaml
action: shell_command  
command: "npm run lint && npm test"
```

Agent prompts are better because they can adapt, explain, and guide.

---

## Hook Examples for Ralph Loops

### Hook 1: Pre-Commit Quality Gate

**File**: `.ralph/hooks/pre-commit-quality.md`

```yaml
---
trigger: pre-commit
action: agent_prompt
instructions: |
  Before allowing this commit, verify:
  
  1. Code Quality
     - All new code is properly type-annotated
     - Error handling follows project patterns
     - No debugging statements (console.log) in production code
     - Functions are small and well-named
  
  2. Test Coverage
     - Every new file has corresponding tests
     - Test coverage exceeds minimum threshold (80%)
     - All tests pass
  
  3. Security
     - No hardcoded secrets or API keys
     - No exposed sensitive data
     - Dependencies are up-to-date and have no known vulnerabilities
  
  4. Documentation
     - API changes are reflected in docs/API.md
     - New features have clear documentation
  
  If ANY of these fail:
  - Reject the commit
  - Explain exactly what failed
  - Show the specific lines that caused failure  
  - Provide clear instructions on how to fix
  - Don't block - just guide and reject
  
  Only allow commit when ALL checks pass.
  
  When done, report: "✓ All checks passed, commit allowed"
---
```

**What happens**:
```
Agent: git commit

Hook: Checking...
Hook: ❌ FAILED: Missing tests for src/auth/login.ts

[src/auth/login.ts:15] New file needs tests
Line 15 defines authenticate() but no test file found

Fix by:
1. Test file: src/auth/__tests__/login.test.ts
2. Should test: successful login, wrong password, token validation

Commit rejected. Fix issues and try again.
```

**Agent responds**:
```
Agent: Oh right, I forgot tests. Let me create them...

[Creates src/auth/__tests__/login.test.ts]

Agent: git commit

Hook: Checking...
Hook: ✓ All checks passed, commit allowed
[Commit succeeds]
```

---

### Hook 2: Pre-Push Protection

**File**: `.ralph/hooks/pre-push-deployment.md`

```yaml
---
trigger: pre-push  
action: agent_prompt
instructions: |
  Before pushing to remote repository, verify:
  
  1. Branch State
     - We're on a feature branch, not main
     - Branch is up to date with latest main
     - No unmerged conflicts
  
  2. Testing State  
     - All tests passing locally
     - Linting clean
     - No breaking changes without migration plan
  
  3. Deployment Readiness
     - Feature is feature-complete
     - Has been tested in staging
     - Has documentation update
  
  4. Code Review
     - Pull request has been created
     - At least one approval from maintainer
     - CI/CD checks all pass on remote
  
  If pushing would violate ANY of these:
  - Reject the push
  - Explain what needs to be done first
  - Suggest next steps
  
  Only allow push when branch is feature-complete and all checks pass.
  
  When rejected, show me the remote branch status so I can see what's out of date.
---
```

---

### Hook 3: Pre-Rebase Conflict Prevention

**File**: `.ralph/hooks/pre-rebase-conflict.md`

```yaml
---
trigger: pre-rebase  
action: agent_prompt
instructions: |
  Before rebasing onto main/develop branch:
  
  1. Check for potential conflicts
     - Look at files that will change
     - Check if others are modified
     - Identify conflict risk level
  
  2. If high conflict risk:
     - Don't attempt the rebase
     - Explain which files might conflict
     - Suggest creating merge branch instead
  
  3. If safe to rebase:
     - Proceed with rebase
     - Note any conflicts that arise
     - Help resolve them if they occur
  
  The goal is to prevent the agent from getting stuck in unresolvable 
  rebase conflicts. Better to choose a different strategy.
  
  After rebase, run tests to ensure nothing broke.
---
```

---

### Hook 4: Post-Commit Cleanup

**File**: `.ralph/hooks/post-commit-cleanup.md`

```yaml
---
trigger: post-commit
action: agent_prompt
instructions: |
  After a successful commit:
  
  1. Cleanup
     - Remove any temporary test files
     - Clear old logs larger than 100MB
     - Archive last 10 commit messages to .ralph/commit-log/
  
  2. Update Documentation
     - Mark feature as implemented if commit message contains "FEATURE_COMPLETE"
     - Update CHANGELOG if major changes
     - Link commit to tracking issue if reference exists
  
  3. Status Updates  
     - Update task tracking if using Beads/Todo system
     - Mark tasks as complete
     - Prepare steering packet for next step
  
  This ensures the repository stays clean and documentation stays synced.
---
```

---

### Hook 5: Commit Message Validation

**File**: `.ralph/hooks/commit-msg-format.md`

```yaml
---
trigger: commit-msg
action: agent_prompt
instructions: |
  Validate the commit message follows required format:
  
  Format must be:
  <type>(<scope>): <subject>
  
  <body>
  
  <footer>
  
  Valid types:
  - feat: New feature
  - fix: Bug fix  
  - docs: Documentation only
  - refactor: Code refactoring
  - test: Test only changes
  - chore: Maintenance tasks
  
  Scope should be the component/team affected.
  
  Body should explain:
  - Why the change is being made
  - What was changed
  - How testing was performed
  
  Footer should include:
  - BREAKING CHANGES if applicable
  - Closes #<issue> if fixing an issue
  - References #<pr> if related to PR
  
  If format is wrong:
  - Show what's wrong
  - Suggest correction
  - Reject commit
---
```

**Example**:

Agent tries to commit:
```bash
git commit -m "fixed the login bug"
```

Hook rejects:
```
❌ Invalid commit message

Expected format:
  fix(auth): Handle expired JWT tokens

Issues found:
  1. Scope missing - should be (auth) for this change
  2. Should use lowercase "fix" not "fixed"
  3. Add body explaining the fix

Suggested message:
  fix(auth): Handle expired JWT tokens

The login endpoint was throwing 500 errors when JWT tokens expired.
Now properly validates token expiration and returns 401 with refresh flow.

Closes #123
```

---

## YAML Configuration Integration

Hooks can be triggered from the main loop configuration:

```yaml
# ralph-wiggum-loop.yaml
workflow:
  git_hooks:
    pre_commit:
      enabled: true
      hook: pre-commit-quality
      reject_on_failure: true
      
    pre_push:
      enabled: true  
      hook: pre-push-deployment
      reject_on_failure: true
      
    post_commit:
      enabled: true
      hook: post-commit-cleanup
      reject_on_failure: false  # Cleanup can fail without blocking
      
  settings:
    max_iterations: 20
    stop_on_hook_failure: true
```

When a hook is defined in YAML:
1. Agent runs loop normally
2. When `git commit` is called
3. Hook automatically triggers
4. Hook can approve or reject
5. If rejected, loop iteration can retry with guidance

---

## Which Agent Manages Git Operations?

### Planning Agent - Primary Git Orchestrator

The planning agent typically manages git lifecycle because:

1. **It knows the whole workflow**
2. **It creates the plan** including branch strategy
3. **It can coordinate** merges, pulls, pushes
4. **It handles conflicts** and escalates if needed

**Typical responsibilities**:
```yaml
planner:
  git_lifecycle:
    - Choose branching strategy (Git Flow, GitHub Flow, trunk-based)
    - Create feature branches from main/develop
    - Coordinate merges and PR creation
    - Handle remote sync
    - Manage cleanup after PR complete
```

### But Any Agent Can Handle Git

Depending on workflow, different agents manage git:

**Builder Agent** (for single-agent loops):
```yaml
builder:
  git:
    auto_commit: true    # Auto-commit after building
    auto_push: false      # Don't push automatically
    branch_policy: create-feature-branch
```

**Verifier Agent**:
```yaml
verifier:
  git:
    only_commit_if_verified: true  # Only commit if verification passes
    branch_policy: feature-branch-from-main
```

**Merger Agent** (in hierarchical patterns):
```yaml
merger:
  git:
    handle_prs: true
    resolve_conflicts: true
    requires_approval: true
```

---

## Branching Strategies in Ralph Loops

### Pattern: Git Flow

```yaml
# For production environments
git_strategy:
  branches:
    main: production-ready code
    develop: development code
    feature/*: feature branches (from develop)
    release/*: release branches (from develop)
    hotfix/*: hotfixes (from main)
  
  workflow:
    1. Planner creates feature branch from develop
    2. Builder commits to feature branch
    3. Verifier checks feature branch
    4. Creator reviews and approves PR
    5. Merger merges into develop
    6. Release manager creates release from develop
    7. Release manager tags and merges to main
```

### Pattern: GitHub Flow

```yaml
# Safer for small teams
git_strategy:
  branches:
    main: protected, requires approval for direct push
    feature-*: feature branches
  
  workflow:
    1. Planner creates feature branch from main
    2. Builder commits to feature branch
    3. CI runs tests on feature branch
    4. Creator opens PR to main
    5. At least 1 approval required
    6. CI runs on PR automatically
    7. Merger (or maintainer) squashes to main
```

### Pattern: Trunk-Based Development

```yaml
# Fastest for continuous integration
git_strategy:
  branches:
    main: all development
  
  workflow:
    1. Planner creates branch for major changes
    2. Otherwise, commit directly to main
    3. CI runs tests on every commit
    4. Protected main requires approvals
    5. Rollback capability for bad commits
  
  hooks:
    pre_commit: require_tests_passing
    pre_push: require_ci_checks
```

---

## Real-World Hook Scenarios

### Scenario 1: Agent Tries to Commit Broken Code

```
Agent: [Writes code]
Agent: git commit -m "feat(auth): Add login endpoint"

Hook: Pre-Commit Check
  Checking...

Issue 1: No tests for new login endpoint
Issue 2: console.log on line 45
Issue 3: Error handling missing

❌ Commit rejected

Fix by:
1. Create tests in src/auth/__tests__/login.test.ts
2. Remove console.log on src/api/login.ts:45
3. Add try-catch blocks around database calls

After fixing, commit again.
```

**Agent fixes and retries**:
```
Agent: [Creates tests]
Agent: [Removes console.log]
Agent: [Adds error handling]

Agent: git commit -m "feat(auth): Add login endpoint"

Hook: Pre-Commit Check
  Checking...
✓ All checks passed, commit allowed

[Commit succeeds]
```

---

### Scenario 2: Agent Tries to Push to Wrong Branch

```
Agent: git push origin feature-add-login

Hook: Pre-Push Check
  Checking remote branch status...

⚠️  Remote branch feature-add-login is ahead by 3 commits

Issue: Feature branch not up to date. Need to pull first.

Do:
  git pull origin main

After pulling, resolve any conflicts and push again.
```

**Agent pulls first**:
```
Agent: git pull origin main

Hook: Checking for conflicts...
No conflicts found

Agent: git push origin feature-add-login

Hook: Pre-Push Check
  Checking...

Issue: Missing required approval
⚠️  PR #123 not merged yet. Need at least 1 maintainer approval.

Go to: https://github.com/org/repo/pull/123
Request review from a maintainer before pushing.
```

---

### Scenario 3: Agent Gets Stuck in Rebase

```
Agent: git rebase main

Hook: Pre-Rebase Check
  Checking for conflicts...

⚠️  High conflict risk detected

Files likely to conflict:
- src/auth/User.ts
- src/api/login.ts

Suggest alternative strategy:
1. Create merge branch: git checkout -b merge-add-login
2. Or create fix branch and separate PR

The goal is to avoid getting stuck in unresolvable conflicts.

Proceed with merge branch: [y/N]?
```

```
Agent: y

[Creates merge branch]

[Continues building on merge branch instead of rebasing]

[Later commits to main cleanly]
```

---

## Best Practices for Git Hooks in Ralph Loops

### 1. Keep Hooks in Plain English

Why: AI agents understand natural language better than bash scripts

Good:
```yaml
instructions: |
  Before committing, check:
  - No debugging statements
  - All new code has tests
  - Error handling follows our patterns
```

Bad:
```bash
#!/bin/bash
if grep -r "console\." src/; then
  exit 1
fi
```

### 2. Always Explain Failures

Don't just reject - explain why and how to fix:

Good:
```
❌ Failed: No tests for src/auth/login.ts

The file src/auth/login.ts:15 defines authenticate() but no test file found.

Fix by:
1. Create: src/auth/__tests__/login.test.ts
2. Test: successful login, wrong password, token validation
```

Bad:
```
exit 1  # No explanation
```

### 3. Guide Don't Block (When Possible)

For guidance-type checks:

Good:
```
⚠️  Found console.log on src/api/login.ts:45

Comment it out before committing:
  // TODO: Remove console.log after debugging
```

Bad:
```
❌ Failed: Console.log found
Commit rejected.
```

### 4. Provide Clear Success Messages

When hooks pass:

Good:
```
✓ All pre-commit checks passed
- Code quality: ✓
- Tests: ✓
- Security: ✓
- Documentation: ✓

Commit allowed.
```

### 5. Use Hooks Contextually

Different hooks for different purposes:

- **pre-commit**: Local quality, basic checks
- **pre-push**: Deployment readiness, remote state
- **post-commit**: Cleanup, documentation updates
- **manual**: On-demand checks (like security scan)

### 6. Test Hooks Individually

Before using in production:

```bash
# Test hook manually
ralph-hook run pre-commit-quality

# Expected output:
# ✓ Test passed
# Or: ❌ Failed with explanation
```

### 7. Version Control Hooks

Since hooks are in `.ralph/hooks/`, they're tracked in git:

```bash
.ralph/hooks/
├── pre-commit-quality.md
├── pre-push-deployment.md
├── post-commit-cleanup.md
└── ...
```

Team can collaborate on hook definitions.

### 8. Make Hooks Iterative

Start simple, add complexity:

**Week 1**:
```yaml
pre-commit-basic:
  - No console.log
  - Tests exist for new files
```

**Week 2**:
```yaml
pre-commit-quality:  # Upgrade name
  - No console.log
  - Tests exist  
  - Code linting passes
  - No breaking changes without migration
```

### 9. Log Hook Execution

For debugging:

```yaml
post_commit:
  action: agent_prompt
  instructions: |
    Log this commit to .ralph/commit-log/history.json
    Include: commit hash, timestamp, file count, lines changed
```

---

## Hook Integration Patterns

### Pattern 1: Hook → Steering Packet

Hook can create steering packets to guide next action:

```yaml
pre_commit_failed:
  action: agent_prompt
  instructions: |
    Create steering packet for next agent:
    
    <steering>
      <status>blocked</status>
      <routing>
        <action type="unblock">
          <next_agent>fixer</next_agent>
          <unblock_keywords>missing_tests console_log</unblock_keywords>
        </action>
      </routing>
      <payload>
        <fixes_required>
          <fix type="add_tests">src/auth/login.ts</fix>
          <fix type="remove_console">src/api/login.ts:45</fix>
        </fixes_required>
      </payload>
    </steering>
```

Next agent receives steering packet and acts on it.

---

### Pattern 2: Hook → Command Retry

When hook rejects, agent can retry with different approach:

```yaml
agent_loop:
  on_hook_rejection:
    action: retry
    with_strategy: fix_issues_first
    
    example:
      hook: pre-commit-check
      result: failed - missing tests
      
      agent: [Creates tests]
      agent: git commit
      hook: check
      result: passed
      
      agent: [Proceeds with next step]
```

---

### Pattern 3: Hook → Manual Escalation

For critical failures, escalate to human:

```yaml
critical_hook:
  action: agent_prompt
  instructions: |
    If this critical issue is found:
    
    1. Create detailed report
    2. Open GitHub issue tracking the failure
    3. Stop the loop
    4. Ask user for manual resolution
    
    Don't continue automatically. This requires human decision.
```

---

## Summary

Git hooks in Ralph loops:

**Are powerful because they**:
- Provide **fixed logic** for the AI to follow
- **Guide** the model when it makes mistakes  
- **Protect** the system from bad code
- **Explain** failures so the AI can learn

**Are easy to create**:
- Written in **plain English**
- Event-driven triggers
- Can run agent prompts or shell commands
- Integrated with YAML configuration

**Transform Ralph loops from**:
```
Code → (maybe good or bad) → Commit
```

**To**:
```
Code → Hook verifies quality →  
  Fix issues →  
  Hook approves →  
  Commit only good code
```

This is the **steering mechanism** that makes Ralph loops safe and reliable!

---

**Remember**: The model WILL try to commit code. With hooks, it can only commit GOOD code. The hooks guide it, protect it, and explain what it needs to fix. That's why git hooks are so powerful for Ralph loops! 
