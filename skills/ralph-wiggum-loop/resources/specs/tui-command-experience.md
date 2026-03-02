# OpenCode Slash Commands - TUI Interactive Experience

## Overview

OpenCode slash commands (`/command`) run in the **local TUI** (Terminal User Interface). This is different from `opencode serve` which runs an HTTP server.

**With slash commands**:
- Agent runs locally on your machine
- You see everything in your terminal
- Agent can suggest and execute commands
- Fully interactive, no server needed

## TUI Experience Flow

### Step 1: Start with OpenCode CLI

```bash
# Navigate to your project
cd my-project

# Start OpenCode
opencode
```

**You see**:
```
┌──────────────────────────────────────────────────────────────┐
│ OpenCode v1.2.10                                    [help] │
├──────────────────────────────────────────────────────────────┤
│ Type / for commands, or ask me anything...                    │
│                                                               │
│ >                                                             │
└──────────────────────────────────────────────────────────────┘
```

---

### Step 2: Agent Suggests a Command

You type a request:

```
> Build authentication system with login and registration
```

**Agent processes** your prompt and responds:

```
I'll build the authentication system. Let me suggest running the 
/planner command first to create the implementation plan.

Should I run /planner to get started? [Enter to continue]
```

**Key**: The agent is suggesting a slash command, not automatically running it.

---

### Step 3: You Execute (or Don't)

**Option A - Press Enter**: Agent executes `/planner`
```bash
> /planner
```

**Option B - Ask questions**:
```
> What will planner do?

Planning authentication system will:
1. Analyze requirements
2. Design database schema  
3. Plan API endpoints
4. Create task breakdown

Proceed with /planner?
```

---

### Step 4: Command Executes in Your Terminal

```bash
> /planner
```

**TUI shows real-time execution**:
```
┌──────────────────────────────────────────────────────────────┐
│ 📋 Planning Authentication System                           │
├──────────────────────────────────────────────────────────────┤
│ Analyzing requirements...                                      │
│ ✓ Identified need for user model                              │
│ ✓ Plan login endpoint                                        │
│ ✓ Plan registration endpoint                                  │
│ ✓ Design JWT schema                                          │
│                                                               │
│ 📋 Implementation Plan Created                              │
│                                                               │
│ Next Steps:                                                   │
│ 1. /builder - Create user models                             │
│ 2. /builder-api - Build endpoints                            │
│ 3. /verifier - Verify implementation                        │
│                                                               │
│ Output saved to: .ralph/plan.json                            │
│                                                               │
│ <promise>PLAN_COMPLETE</promise>                              │
└──────────────────────────────────────────────────────────────┘
```

**You can scroll up** to see what the agent wrote:

```bash
[Press Up Arrow to see previous output]

Analyzing authentication requirements...

# Authentication System Plan

## User Model
- id: string (UUID)
- email: string (unique)
- password_hash: string  
- created_at: timestamp
- ...
```

---

### Step 5: Agent Suggests Next Command

```
Plan complete. Ready to build? 

Next: /builder

Run /builder to create user models and endpoints? [Enter or type question]
```

**You press Enter**:

```bash
> /builder
```

**TUI shows live coding**:
```
┌──────────────────────────────────────────────────────────────┐
│ 🔨 Building Authentication System                           │
├──────────────────────────────────────────────────────────────┤
│ Creating user model...                                        │
│                                                               │
│ > src/auth/User.ts                                           │
│ │ export interface User {                                   │
│ │   id: string;                                              │
│ │   email: string;                                            │
│ │   passwordHash: string;                                    │
│ │ }                                                          │
│                                                              │
│ Creating login endpoint...                                   │
│                                                              │
│ > src/api/login.ts                                           │
│ │ import express from 'express';                            │
│ │ import { authenticate } from './auth';                     │
│ │                                                            │
│ │ export const login = async (req, res) => {                │
│ │   const { email, password } = req.body;                  │
│ │   const user = await authenticate(email, password);       │
│ │   // ...                                                  │
│ │ };                                                         │
│                                                              │
│ ✓ User model created                                        │
│ ✓ Login endpoint built                                      │
│ ⏳ Registration endpoint in progress...                      │
└──────────────────────────────────────────────────────────────┘
```

**Live updates** appear as the agent works. You can:
- Watch code being written in real-time
- See files being created/edited
- Scroll through the output
- Ask questions anytime

---

### Step 6: Pause Mid-Execution

**You want to check something**:

```bash
[Ctrl+C] Paused! Agent suspended at:

> src/api/register.ts (line 15)
```

**Ask about what you see**:
```
> What are you doing with the password hashing?

Agent: I'm using bcrypt with 10 rounds to hash passwords securely 
before storing. Let me show you the relevant code:

> src/auth/password.ts:10-15
│ export async hashPassword(password: string): Promise<string> {
│   const salt = await bcrypt.genSalt(10);
│   return bcrypt.hash(password, salt);
│ }

Continue with /builder or ask more questions?
```

---

### Step 7: Verification Step

```bash
> /verifier
```

**Agent runs verification**:
```
┌──────────────────────────────────────────────────────────────┐
│ ✅ Verifying Implementation                                  │
├──────────────────────────────────────────────────────────────┤
│ Checking code quality...                                      │
│ ✓ TypeScript types are correct                              │
│ ✓ Error handling implemented                                 │
│                                                               │
│ Running tests...                                              │
│ npm test                                                      │
│                                                               │
│ PASS  src/auth/User.test.ts                                 │
│ PASS  src/api/login.test.ts                                 │
│ PASS  src/api/register.test.ts                              │
│                                                               │
│ All 3 tests passed ✓                                         │
│                                                               │
│ <promise>AUTH_VERIFIED</promise>                             │
└──────────────────────────────────────────────────────────────┘
```

---

### Step 8: Error Handling

**What if something fails?**

```bash
> /builder-test
```

```
┌──────────────────────────────────────────────────────────────┐
│ ❌ Build Failed                                              │
├──────────────────────────────────────────────────────────────┤
│ Error: Database connection timeout                           │
│                                                               │
│ Attempted Actions:                                           │
│ 1. Connection to: localhost:5432                              │
│ 2. Waited 30 seconds                                         │
│ 3. Retried 3 times                                           │
│                                                               │
│ Details:                                                     │
│ Error: connect ECONNREFUSED                                │
│                                                               │
│ Suggested Fixes:                                             │
│ 1. Check if PostgreSQL is running                            │
│ 2. Update connection string                                  │
│ 3. Try different port                                        │
│                                                               │
| Next Steps:                                                   │
| 1. Retry /builder-test                                       │
│ 2. Ask for manual intervention                               │
│ 3. Switch approach                                           │
│                                                               │
| What would you like to do? [type command or question]         │
└──────────────────────────────────────────────────────────────┘
```

---

## Agent Command Suggestions

Agents can actively suggest commands:

### Pattern 1: Sequential Suggestion

```
Planning complete.

Next: /builder (to create models and endpoints)

Run /builder? [Enter to continue]
```

**You press Enter** → command executes

---

### Pattern 2: Menu of Options

```
Build complete. What's next?

Options:
1. /verifier - Check code quality and run tests
2. /deployer - Deploy to staging
3. /documenter - Write API documentation

Type /command or ask for help with an option...
```

**You type**:
```
> Should I run tests or write docs first?

Agent: I recommend running /verifier first. Tests should pass 
before documenting. The verifier will catch any issues you need 
to fix. Documentation comes after everything works.

Proceed with /verifier?
```

---

### Pattern 3: Conditional Routing

```
Tests passed. Decision time:

Login endpoint: ✓ pass
Registration endpoint: ✗ fail (port conflict)

Options:
1. Fix registration and retry /verifier
2. Run /deployer (deploy working parts)
3. Ask user for direction

What should I do? [1/2/3/different]
```

---

## Command Definition Examples

### Simple Command

Create `.opencode/commands/builder.md`:

```markdown
---
description: Build authentication endpoints
agent: build
model: anthropic/claude-sonnet-4-20250514
---
Build authentication system for the application.

Tasks:
1. Create user model with TypeScript
2. Implement login endpoint
3. Implement registration endpoint
4. Add JWT authentication
5. Write tests for each endpoint

Output: <promise>BUILD_COMPLETE</promise>

When complete, suggest: /verifier
```

**Usage in TUI**:
```bash
> /builder

[Agent executes defined tasks]

Build complete. Next: /verifier

Run /verifier? [Enter to continue]
```

---

### Command with Arguments

```markdown
---
description: Create component
---
Create a new React component named $ARGUMENTS with TypeScript support.

Use this structure:
- Functional component with hooks
- Proper TypeScript types
- Default props where needed

Example /component Button creates Button component.
```

**Usage**:
```bash
> /component Button
```

---

### Command with Shell Output Injection

```markdown
---
description: Analyze test coverage
---
Here are the current test results:

!`npm test -- --coverage`

Based on these results, suggest improvements to increase coverage 
to at least 80%. Focus on the files with lowest coverage.
```

**Usage**:
```bash
> /analyze-coverage
```

**Agent sees output like**:
```
Here are the current test results:

File                  | % Stmts | % Branch | % Funcs | % Lines
---------------------|---------|----------|---------|---------
src/auth/User.ts       |    90   |    85    |   92    |   88
src/api/login.ts      |    75   |    60    |   80    |   70
src/api/register.ts   |    82   |    75    |   85    |   80
```

---

### Command with File References

```markdown
---
description: Review component
---
Review the component in @src/components/Button.tsx.

Check for:
- Performance issues
- Accessibility concerns
- TypeScript safety

Suggest improvements as needed.
```

---

## TUI Interactions

### Command Autocomplete

Type `/` and see available commands:

```
> /<TAB>
/builder         Build implementation
/planner         Create plans
/verifier        Verify code quality
/tester          Run tests
/deployer        Deploy to environments
/documenter     Write documentation
```

### Command History

Press **Up Arrow** to recall previous commands:

```
> /builder     (1)
> /verifier    (2)
> /tester      (3)
```

### Command Help

Type `/help` or `/? commandname`:

```bash
> /help

Available commands:

/builder  - Build authentication endpoints
/verifier - Verify code quality and run tests
/tester   - Run test suite with coverage
```

```bash
> /help builder

/builder - Build authentication endpoints

Tasks:
1. Create user model
2. Implement login endpoint
3. Implement registration endpoint
4. Add JWT authentication
5. Write tests

Output: <promise>BUILD_COMPLETE</promise>

When complete, suggests: /verifier
```

---

## Error Recovery TUI Pattern

### Agent Detects Error

```
❌ Error: Database connection failed

Suggested Actions:
1. Retry with /builder (attempt 2/5)
2. Ask for manual intervention
3. Change approach

What would you like to do? 
```

**You type**:
```
> What's the exact error?

Agent: The error is:

Error: connect ECONNREFUSED 127.0.0.1:5432

This means PostgreSQL isn't running on port 5432. I'll 
check if it's running on a different port if you retry.

Retry with /builder or handle manually?
```

**You retry**:

```bash
> /builder

Retrying database connection...
Checking alternative ports...
Found PostgreSQL on 5433

✓ Updated connection string
✓ Database connected
✓ Continuing build...
```

---

## Comparison: Local TUI vs Server Mode

| Aspect | Local TUI (Commands) | Server Mode (HTTP) |
|--------|---------------------|-------------------|
| Setup | No setup needed | Requires `opencode serve` |
| Visibility | Real-time in terminal | Via dashboard/API |
| Interactivity | High - ask anytime | Lower - monitoring only |
| Control | Full user control | Server-driven |
| Speed | Direct execution | Overhead via HTTP |
| Complexity | Simple | More complex |
| Offline | Yes | No |
| Best For | Learning, debugging, flexibility | Automation, monitoring, scaling |

**Use Local TUI When**:
- Learning Ralph loops
- Need to ask questions mid-flight
- Want to see everything happening
- Debugging complex issues
- Single developer workflows

**Use Server Mode When**:
- Running overnight builds
- Multi-agent parallel execution
- Need dashboards/monitoring
- Team coordination
- Production workflows

---

## Tips for Great TUI Experiences

### 1. Name Commands Clearly

```bash
# Good
/builder-auth-login
/verify-auth-tests
/deploy-auth-staging

# Less clear  
/command1
/command2
/command3
```

### 2. Include "Next" Suggestions

Always tell the user what comes next:

```markdown
When complete, suggest: /verifier
```

### 3. Promise Patterns

Use promises for chain tracking:

```markdown
Output: <promise>BUILD_COMPLETE</promise>
Output: <promise>VERIFIED</promise>
Output: <promise>DEPLOYED</promise>
```

### 4. Error Context

Provide actionable error messages:

```markdown
Error: Database timeout

Attempted:
- Connection to localhost:5432
- 3 retries
- 30 second timeout

Try: Check if PostgreSQL is running, update credentials
```

### 5. Live Updates

Show progress in real-time:

```
Creating user model... ✓ done  
Building login endpoint... 50% done
Writing tests... 3 of 5 complete
```

### 6. Ask Before Proceeding

Don't surprise the user:

```bash
Build complete. Deploy to staging?

[Enter] Yes  |  [Ctrl+C] No  |  [?] Ask what?
```

---

## Debugging in TUI Mode

### Using /undo and /redo

Mistake happened:

```bash
> /builder
```

**Oops** - broke something.

```bash
> /undo

Changes reverted. 
File: src/api/login.ts (reverted)

Try again or different approach?
```

**Try different approach**:

```bash
> /builder-alt

Using alternative approach...
[New successful build]
```

**Kept old version** via `/redo` if needed:

```bash
> /redo

Restored: src/api/login.ts (version 1)
```

### Viewing Changes

```bash
> /diff

Changed files:
src/api/login.ts +12, -5
src/models/User.ts +3
```

### Getting Context

```bash
> What files were modified by /builder?

Modified in last /builder run:
- src/auth/User.ts (new)
- src/api/login.ts (new)  
- src/api/register.ts (new)
- tests/login.test.ts (new)

Total: 4 files created/modified
```

---

## Best Practices Summary

1. **Define clear commands** in `.opencode/commands/`
2. **Use promises** for tracking completion
3. **Suggest next commands** to keep flow clear
4. **Show progress** with live updates
5. **Handle errors** gracefully with actionable suggestions
6. **Ask before proceeding** on significant changes
7. **Review with /diff** before committing major changes
8. **Use /undo** for mistakes
9. **Document commands** with `/*` comments
10. **Test commands** in isolation before chaining

---

**Remember**: The TUI slash command experience is about **human in the loop**. You see every step, can ask questions, and maintain control while the agent does the work. Perfect for learning, debugging, and flexible workflows!
