# Advanced Patterns: Quality & Structure

## Last Message as Commit Message

### Using the Agent's Final Output as Commit Message

When an agent completes a task, the last message before the completion promise is often an excellent git commit message.

**Why this works well**:
- Agent's output describes what was done and why
- Contains context about the implementation
- Reflects the agent's understanding of the change
- Typically includes technical details in a clear way

### Pattern Implementation

**How to extract and use**:

```bash
# After agent completes, get last message before completion
LAST_MESSAGE=$(opencode messages last --session $SESSION_ID | jq -r '.content')

# Extract commit-worthy portion
COMMIT_MESSAGE=$(echo "$LAST_MESSAGE" | sed -n '1,/^$p' | head -20)

# Use as commit message
git commit -m "$COMMIT_MESSAGE"
```

**Ralph loop integration**:

```yaml
# In workflow hook or script

pre_commit_hook:
  # After agent finishes task
  if agent.message_contains("<promise>COMPLETE</promise>"):
    last_message = get_message_before_promise(session_id)
    
    # Extract first 2-3 sentences or up to 72 characters
    commit_msg = extract_commit_message(last_message, max_lines=2, max_chars=72)
    
    # Commit with that as message
    git commit -m "$commit_msg"

    # Optionally append context if needed
    git commit -m "$commit_msg" -m ""
    git commit -m "$(last_message)" --amend  # If first version wasn't sufficient
```

**Why it produces high-quality commits**:
1. **Context included**: Agent's reasoning is in the message
2. **Technical accuracy**: Reflects what was actually done
3. **Concise typically**: Agent often already summarized the work
4. **Consistent format**: Same style messages across projects
5. **No separate documentation**: Less prone to sync issues

### When This Doesn't Work

**Fallback cases**:
- Agent's message is too long >72 characters (GitHub format limit)
- Agent's message is too vague ("I built it")
- Agent used "we completed the feature"

**Fallback strategies**:

```yaml
# If last_message is unsuitable:
if commit_message_quality_score(last_message) < threshold:
  # Generate from files changed
  files_changed = git status --short
  
  # Build structured message
  commit_msg = "build(auth): Implement login endpoint
  
  Files changed:
$(git status --short)
  
  Tests: Pass all
  Context: User authentication feature completion"
```

### Extracting Best Practices

**Extraction rules for commit messages**:

```markdown
Rules for quality commit messages from agent output:

1. Take FIRST 2-3 sentences (most important)
   - Agent usually summarizes work at start
   - These contain the "what" and "why"
   - Everything after is often implementation details

2. Format to conventional commit style:
   - type: build, fix, feat, refactor, etc.
   - scope: auth, api, ui, etc.
   - message: Clear description

Example extraction:
  
  Agent's full message:
  "I have successfully implemented the user authentication system. 
   The implementation includes a secure JWT token management 
   with 256-bit keys and salt. The login endpoint validates credentials 
   against the database and returns tokens with appropriate expiration.
   I've written unit tests for all three authentication flows..."

  → Commit message:
  "build(auth): Implement JWT-based authentication with secure token management"
```

## Baby Steps: Granular Task Breakdown

### What Are "Baby Steps"?

From the cline/prompts context:

> "Baby Steps™: make the smallest possible meaningful change at any one time. Instead of telling the AI 'build me a website,' I use the memory bank to focus on one, single, well-defined task from a list of known issues."

**The core idea**:
- Break tasks down into atomic, well-defined units
- Each step should be independently verifiable
- Each step should be clearly either "done" or "not done"
- Prevents agent from getting overwhelmed

### What Makes a Powerful Todo List?

**Key characteristics** of well-broken-down tasks:

1. **Atomic and Indivisible**
   - Each task does ONE thing
   - Cannot be divided further
   - Clear success criteria
   
   Bad: "Implement user authentication"
   Good: "Create user model with id, email, password fields"

2. **Clear and Specific**
   - No ambiguity about what must be done
   - Specific about files/functions/techniques
   - Testable
   
   Bad: "Make it work"
   Good: "Return 200 status when API endpoint receives valid input"

3. **Small and Focused**
   - Less complexity = fewer errors
   - Easier to understand
   - Faster completion
   
   Bad: "Fix all authentication bugs (20 items)"
   Good: "Fix JWT token validation in login endpoint"

4. **No Dependencies**
   - A task shouldn't depend on later tasks
   - Each task should be complete on its own
   
   Bad: "Add tests for user model" (depends on "Create user model")
   Good: "Write User model structure definition"

5. **Verifiable**
   - True/False binary outcome
   - Can be verified by test or inspection
   - No subjective completion
   
   Bad: "Improve code quality"
   Good: "Add type annotations to user.ts"

### Breaking Down Tasks

**Example: "Add user authentication"**

**Bad breakdown (too large)**:
```yaml
tasks:
  - name: "Implement user authentication"
    steps:
      - "Build it"
      - "Test it"
      - "Make it work"
```

**Good breakdown (baby steps)**:
```yaml
tasks:
  - name: "user-model-00-structure"
    description: "Define User model with id and email fields"
    files: ["src/models/User"]
    criteria: "File created with correct TypeScript interface"
    
  - name: "user-model-01-create-operation"
    description: "Add create() method to User model"
    files: ["src/models/User"]
    criteria: "Method exists with correct types"
    
  - name: "user-model-02-find-operation"
    description: "Add findById() method to User model"
    files: ["src/models/User"]
    criteria: "Method accepts ID, returns User or null"
    
  - name: "auth-api-00-login-endpoint"
    description: "Create POST /auth/login endpoint"
    files: ["src/api/auth/login.ts"]
    criteria: "Endpoint accepts email/password, returns JWT"
    
  - name: "auth-api-01-validate-input"
    description: "Add input validation to login endpoint"
    files: ["src/api/auth/login.ts"]
    criteria: "Returns 400 for invalid email or missing password"
    
  - name: "auth-api-02-fetch-user"
    description: "Add database query for user lookup"
    files: ["src/api/auth/login.ts"]
    criteria: "Queries database for given email"
    
  - name: "auth-api-03-login-verify"
    description: "Add password verification in login endpoint"
    files: ["src/api/auth/login.ts"]
    criteria: "Verifies password hash matches stored"
    
  - name: "auth-token-00-signing-key"
    description: "Config environment variable for JWT signing"
    files: [".env.example"]
    criteria: "JWT_SECRET_KEY=your-secret-key added"
    
  - name: "auth-token-01-jwt-library"
    description: "Install JWT library"
    files: ["package.json"]
    criteria: "jsonwebtoken in dependencies"
    
  - name: "auth-token-02-create-function"
    description: "Create generateToken() function"
    files: ["src/auth/tokens.ts"]
    criteria: "Function returns signed JWT from payload"
    
  - name: "auth-api-04-token-generation"
    description: "Integrate token generation into login endpoint"
    files: ["src/api/auth/login.ts"]
    criteria: "Returns JWT on successful authentication"
```

**What's different**:
- **17 tasks** instead of **3 huge tasks**
- Each task is 5-10 lines of code (not 500 lines)
- Each task clearly defines files and criteria
- No overlap or dependencies beyond necessary
- Progress visible at atomic level

### Why Baby Steps Work Better

**Agent perspective**:
```
Task: "Implement Authentication"
→ Agent: "Sure! I'll start with... [writes 500 lines of code]"
→ Agent: "Oh oops, forgot validation"
→ Agent: "Let me fix... [edits 500 lines again]"
→ Result: Messy, difficult to debug

Task: "User model: structure definition"
→ Agent: "OK, done in 2 lines"
→ [Check] ✓ Task complete! Next task?
→ Task: "User model: create operation"
→ Agent: "Done. Next?"
→ Result: Clean, one-task-at-a-time, easier to debug
```

**Human perspective**:
- **Visibility**: See exactly what done, what's left
- **Control**: Can approve/reject each step with granular control
- **Speed**: Can pick up from any step if interrupted
- **Quality**: Easier to verify each step individually

**Cost perspective**:
- **Smaller context**: Agent processes less code per iteration
- **Fewer failures**: Atomic tasks are easier to get right
- **Less rework**: Debugging is localized
- **Predictable cost**: 500 lines vs 5 lines = big cost difference

### Implementation in Ralph Loops

**Generating breakdown**:

```markdown
# In PROMPT.md:

When breaking down features, use baby steps:

For each feature:
1. Identify all distinct components
2. Break into indivisible operations
3. Ensure each depends only on completed tasks
4. Write atomic, testable task descriptions

Example for "Add authentication":
  → 1. Define User model structure
  → 2. Add create() method
  → 3. Add findById() method
  → 4. Create login endpoint
  → 5. Add input validation
  → 6. Add database lookup
  → 7. Add password verification
  → 8. Configure JWT key
  → 9. Install JWT library
  → 10. Create token generation function
  → 11. Integrate token into login endpoint

This approach ensures:
- Each task is complete on its own
- Progress is clearly visible
- Failures are localized and easy to debug
```

**Todo file structure**:

```markdown
# tasks.md (well-broken tasks file structure)

## Feature: User Authentication

### Phase 1: Data Model

- [ ] [user-model-00-structure] Define User structure
- [ ] [user-model-01-create] Add create() method
- [ ] [user-model-02-find] Add findById() method

### Phase 2: API Endpoints

- [ ] [auth-api-00-login] Create POST /auth/login
- [ ] [auth-api-01-validate] Add input validation
- [ ] [agent-api-02-fetch] Add database query
- [ ] [agent-api-03-verify] Add password verification
- [ ] [agent-api-04-token] Integrate token generation

### Phase 3: Token Management

- [ ] [auth-token-00-signing-key] Configure JWT secret
- [ ] [auth-token-01-jwt] Install JWT library
- [ ] [auth-token-02-create] Create generateToken function

Total: 11 tasks
Target: 2-3 hours
```

**Task naming conventions**:

```yaml
# How to name baby-steps tasks

Format: <component>-<step>-<action>

Examples:
  component: user-model, auth-api, auth-token
  step: 00, 01, 02 (numbered sequence)
  action: structure, create, validate, signing

Why this works:
- Groups by component (easier to find related tasks)
- Sequence numbers show order
- Action describes what happens
- Short, readable IDs for tracking
```

### Baby Steps + Ralph Loops

**Combining with context rot avoidance**:

```markdown
# In PROMPT.md (addressing both ideas):

## Baby Steps Execution Workflow

**Why baby steps**: 
Each iteration, pick ONE well-defined task from the list. Complete it. Mark it done. Move to next.

This ensures:
- Agent's context window stays small (one task)
- Task details in file, not conversation memory
- Progress unambiguously verifiable

**Why Ralph loops**:
Each iteration starts fresh
- No accumulated conversation history
- Agent reads: "What's next?" from task.md
- Completes one atomic task
- Updates task.md
- Exits cleanly (no session pollution)

Together:
→ Agent works in tiny chunks
→ Context window stays clean
→ No context rot
→ High task success rate
```

### Breaking Down Complex Features

**Example: "Payment Integration"**

**Starting feature**: "Add Stripe payment support"

**Baby steps breakdown** (20+ tasks):

1. Feature definition → Write payment specification
2. Environment → Configure Stripe keys (.env)
3. Dependencies → Install Stripe SDK
4. Database → Add Payment model structure
5. Database → Add Order model structure
6. Database → Migrate database schema
7. API → Create payment intent endpoint
8. API → Add input validation for payment amount
9. API → Call Stripe CreatePaymentIntent
10. Server error handling → Handle Stripe errors
11. Server → Add retry logic for network failures
12. Server → Add webhook event verification
13. Server → Create payment succeeded webhook
14. Server → Create payment failed webhook
15. Server → Handle payment_intent.created event
16. Server → Handle payment_intent.succeeded event
17. Testing → Write unit tests for intent generation
18. Testing → Write unit tests for webhook handling
19. Testing → Write integration tests with Stripe mock
20. Documentation → Document webhook protocol
21. Documentation → Add API examples

**Total**: 21 tasks

**Without baby steps**:
- Agent tries → All 21 tasks at once
- Result → Fail at task 4, hard to identify which step broke
- Re-run cost → All 21 tasks again (most complete)
- Total loops → Many retries (high cost)

**With baby steps**:
- Agent does → Task 1 ✓ → Task 2 ✓ → Task 3 ✓ → Task 4 (fails)
- Result → Clear failure at task 4, easy to debug
- Re-run cost → Just task 4 (minimal cost)
- Total loops → 21 successful iterations (one failure)

### Quality Indicators for Todo Lists

**Good todo list indicators**:

| Indicator | Bad | Good |
|------------|-----|------|
| **Task size** | 500 lines | 5-10 lines |
| **Ambiguity** | "Fix the auth" | "Add input validation for /auth/login email" |
| **Dependencies** | Depends on future tasks | Depends only on completed tasks |
| **Verifiability** | Subjective ("make it better") | Objective (".add() returns User | null") |
| **Task ID** | "task_1" | "user-model-00-structure" |

### Integration with Beads/Beads-based systems

**Beads task format works well with baby steps**:

```json
{
  "id": "user-model-00",
  "title": "Define User model with id and email fields",
  "description": "Create src/models/User.ts with TypeScript interface",
  "criteria": "File created with correct interface definition",
  "files": ["src/models/User.ts"],
  "type": "implementation",
  "priority": "high",
  "estimated_time": "5 minutes",
  "tokens_needed": 2000,
  "complexity": "simple"
}
```

**Why Beads + Baby Steps = Powerful**:
- **Beads**: Task storage and state (JSON format)
- **Baby Steps**: Task granularity and structure
- **Together**: Structured breakdown in structured storage
- **Agent can**: Pick up next task from Beads, execute single task, mark done

### Best Practices Summary

**Baby Steps principles**:
1. **Atomic**: One thing per task, no more
2. **Specific**: Clear description of what must happen
3. **Small**: Under 50 lines of code or 10 minutes work
4. **Independent**: No forward dependencies
5. **Verifiable**: Clear success/failure criteria

**Last message commit pattern**:
1. **Extract first 2-3 sentences** (most important content)
2. **Format to conventional commit style** (type/scope: message)
3. **Fallback** to git status if agent message unsuitable

**Why these work together in Ralph loops**:
- Baby steps → Small context per iteration (reduces context rot)
- Last message → Summarized, contextual commit messages
- Atomic tasks → Easy to verify and correct
- Granular progress → Clear visualization of what's done

**Result**: More successful Ralph loops with higher quality output and lower cost!
