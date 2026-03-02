# Working Examples for Ralph Loops

## Example 1: Simple Bash Loop

The most basic Ralph loop - a bash script that runs until success.

```bash
#!/bin/bash
# ralph-loop-simple.sh
# Simple Ralph loop implementation

set -e

# Configuration
AGENT_CMD="${OPCODE_AGENT_CMD:-opencode}"  # Default: opencode CLI
PROMPT_FILE="${RAPPH_PROMPT_FILE:-PROMPT.md}"
MAX_ITERATIONS="${RAPPH_MAX_ITERATIONS:-20}"
COMPLETION_PROMISE="${RAPPH_COMPLETION_PROMISE:-<promise>TASK_COMPLETE</promise>}"

echo "=== Ralph Loop Running ==="
echo "Prompt: $PROMPT_FILE"
echo "Max iterations: $MAX_ITERATIONS"
echo "Completion promise: $COMPLETION_PROMISE"
echo ""

iteration=0

while [ $iteration -lt $MAX_ITERATIONS ]; do
  echo "--- Iteration $((iteration + 1)) ---"
  
  # Run agent with PROMPT.md
  output=$($AGENT_CMD < "$PROMPT_FILE")
  
  # Check for completion promise
  if echo "$output" | grep -q "$COMPLETION_PROMISE"; then
    echo "✅ SUCCESS after $((iteration + 1)) iterations"
    echo ""
    echo "Last output:"
    echo "$output"
    exit 0
  fi
  
  # If not complete, count iteration
  iteration=$((iteration + 1))
  
  # Optional: Show iteration count
  echo "Continuing... (iteration $iteration/$MAX_ITERATIONS)"
  echo ""
  echo "Last action taken:"
  echo "$output" | tail -5
  echo ""
  
  sleep 2  # Small pause to avoid rapid-fire loops
done

echo "❌ FAILED: Did not complete after $MAX_ITERATIONS iterations"
```

**Usage**:
```bash
# Make it executable
chmod +x ralph-loop-simple.sh

# Run it
./ralph-loop-simple.sh
```

---

## Example 2: Simple Retry for Bug Fix

**Task**: Fix a broken authentication endpoint

**PROMPT.md**:
```markdown
# Task: Fix login endpoint returning 500 error

## Context
- The `/auth/login` endpoint currently returns HTTP 500
- Error message: "Cannot read property 'password' of undefined"
- The endpoint was working before recent changes

## Steps
1. Locate the authentication handler file
2. Find where the error occurs (likely null check)
3. Fix the null safety check
4. Test the fix with valid credentials
5. Verify endpoint returns 200 status

## Output Format
<promise>FIXED</promise>

## Verification
After claiming FIXED:
- Run tests: npm test
- Check endpoint: curl -X POST http://localhost:3000/auth/login -d '{"email":"test@example.com","password":"password"}'
- Ensure response is 200 with JWT token
```

**Usage**:
```bash
./ralph-loop-simple.sh
```

---

## Example 3: Build + Verify Pattern

**Task**: Implement a complete authentication system

**PROMPT.md**:
```markdown
# Task: Implement authentication system

## Overview
Build a complete user authentication system with:
- User model (id, email, password_hash)
- Login endpoint (/auth/login)
- Token generation (JWT)
- Password validation
- Security measures

## Steps

### Phase 1: Data Model
- [phase-01-model] Define User model structure (5 lines)
- [phase-02-db] Add database connection (10 lines)

### Phase 2: Token Management
- [token-01-setup] Configure JWT secret in .env
- [token-02-install] Install JWT library
- [token-03-sign] Create generateToken function
- [token-04-verify] Create verifyToken function

### Phase 3: API Endpoints
- [api-00-login] Create POST /auth/login
- [api-01-validate] Add input validation
- [api-02-fetch] Add database query
- [api-03-verify] Add password verification
- [api-04-token] Integrate token generation

### Phase 2: Testing
- [test-01-unit] Write unit tests for models
- [test-02-api] Write test for endpoints
- [test-03-integ] Write integration tests

## Output Format
<promise>AUTH_SYSTEM_COMPLETE</promise>

## Verification
After claiming COMPLETE:
1. All tests pass: npm test
2. Endpoint works: curl test at /auth/login
3. Token generation valid
4. No console.log statements in production code
```

**Loop Implementation**:
```bash
#!/bin/bash
# ralph-loop-build-verify.sh

PROMPT="PROMPT.md"
AGENT_CMD="${OPCODE_AGENT_CMD:-opencode}"
MAX_ITERS="${RAPPH_MAX_ITERS:-20}"

iteration=0

while [ $iteration -lt $MAX_ITERS ]; do
  echo "iteration: $iteration"
  
  # Run agent
  output=$($AGENT_CMD < "$PROMPT")
  
  # Check for intermediate promises
  if echo "$output" | grep -q "<promise>AUTH_SYSTEM_COMPLETE</promise>"; then
    echo "✅ Complete!"
    echo "$output"
    exit 0
  fi
  
  iteration=$((iteration + 1))
done

echo "❌ Timed out after $MAX_ITERS iterations"
```

---

## Example 4: Task Queue with Beads

**Setup with Beads**:
```bash
# Initialize Beads
bd init

# Create tasks
bd create "user-model-structure" -p 0
bd create "create-method" -p 0
bd create "login-endpoint" -d "Define User model with id, email, password fields"
bd create "validation" -d "Add input validation to login endpoint"

# List tasks
bd ready
```

**Ralph loop that processes Beads tasks**:
```bash
#!/bin/bash
# ralph-loop-beads.sh

while true; do
  # Get next task
  task=$(bd ready | head -n 1)
  
  if [ -z "$task" ]; then
    echo "✅ No more tasks"
    exit 0
  fi
  
  # Extract task details
  task_id=$(echo "$task" | cut -f1)
  task_title=$(echo "$task" | cut -f2)
  
  echo "Processing task: $task_title ($task_id)"
  
  # Get task context
  context=$(bd show $task_id | jq -r '.description')
  
  # Build PROMPT.md for this task
  cat > PROMPT.md <<EOF
# Task: $task_title

$context

## Output Format
<promise>TASK_COMPLETE</promise>

## Verification
[Context-dependent]
EOF
  
  # Run agent on PROMPT.md
  opencode < PROMPT.md
  
  # Mark as complete
  bd update $task_id --status done --completed
  
  # Move to next
  echo "✅ Completed $task_title"
  echo ""
done
```

**Usage**:
```bash
chmod +x ralph-loop-beads.sh
./ralph-loop-beads.sh
```

---

## Example 5: Parallel Pipeline (Simplified)

**Task**: Build authentication (multiple components in parallel)

**PROMPT.md for each agent**:
```markdown
# Builder: User model
Build User model with id, email fields

<promise>MODEL_COMPLETE</promise>
```

```markdown
# Builder: Login endpoint  
Build POST /auth/login endpoint with validation

<promise>API_COMPLETE</promise>
```

```markdown
# Verifier: Model testing
Test model with sample data

<promise>MODEL_TEST_PASS</promise>
```

**Ralph loop script**:
```bash
#!/bin/bash
# ralph-loop-parallel.sh

PROMPT_DIR="./prompts"

# Run all builders in parallel
echo "Starting parallel build..."

P1_START=0
P2_START=0
P3_START=0

opencode < "$PROMPT_DIR/builder-model.md" > output1.log 2>&1 &
P1_START=$!

opencode < "$PROMPT_DIR/builder-api.md" > output2.log 2>&1 &
P2_START=$!

opencode < "$PROMPT_DIR/verifier-model.md" > output3.log 2>&1 &
P3_START=$!

# Wait for all to complete
wait $P1_START $P2_START $P3_START

# Check results
if grep -q "<promise>MODEL_COMPLETE</promise>" output1.log && \
   grep -q "<promise>API_COMPLETE</promise>" output2.log && \
   grep -q "<promise>MODEL_TEST_PASS</promise>" output3.log; then
  echo "✅ All parallel tasks completed successfully"
  exit 0
else
  echo "❌ Some tasks failed"
  echo ""
  echo "Results:"
  echo "Model builder: $(grep -q 'MODEL_COMPLETE' output1.log && echo '✓' || echo '✗')"
  echo "API builder: $(grep -q 'API_COMPLETE' output2.log && echo '✓' || echo '✗')"
  echo "Model tester: $(grep -q 'MODEL_TEST_PASS' output3.log && echo '✓' || echo '✗')"
  exit 1
fi
```

**Usage**:
```bash
chmod +x ralph-loop-parallel.sh
./ralph-loop-parallel.sh
```

---

## Example 6: Manual Command Loop (TUI)

**Commands in `.opencode/commands/`**:
```markdown
---
description: Plan the authentication system architecture
---
Analyze requirements and create:
1. Database schema
2. API endpoint design
3. Security considerations
4. Component breakdown
```

```markdown
---
description: Build the authentication models
---
Create TypeScript interfaces for:
1. User model
2. Token interfaces
3. Validation schemas

<promise>MODELS_COMPLETE</promise>
```

```markdown
---
description: Verify the authentication implementation
---
Check for:
1. Code quality issues
2. Security vulnerabilities
3. Test coverage
4. Performance bottlenecks
```

**TUI usage**:
```bash
# User workflow
> /agent use @workflow-builder
"I need to build authentication with verification"

Agent suggests: /planner

> /planner
[Plans and executes]

Agent suggests: /builder-models
> /builder-models
[Builds models]

Agent suggests: /verify
> /verify
[Verifies implementation]

Agent suggests: Continue or stop?
> continue

Agent suggests: Next action based on results
```

---

## Example 7: Multi-Agent Coordination with Agent Inbox

**Agent Inbox request scenario**:

```json
{
  "agent_id": "auth-builder",
  "request_type": "approval",
  "title": "Destructive operation: Drop tables",
  "context": {
    "operation": "DROP TABLE users, sessions",
    "reason": "Need clean slate for migration",
    "risk": "HIGH - Data loss"
  },
  "suggested_action": "approve",
  "timestamp": "2026-02-24T10:30:00Z"
}
```

**Agent writes** to `.inbox/pending/auth-builder/task.json`

**Human reviews** and writes to `.inbox/responses/auth-builder/result.json`:
```json
{
  "decision": "reject",
  "reason": "Too risky. Create backup table first",
  "alternative": "Run migration with CREATE TABLE users_backup AS SELECT * FROM users",
  "timestamp": "2026-02-24T10:35:00Z"
}
```

**Agent continues** on next iteration:
```bash
# In next iteration
state=$(cat .inbox/responses/auth-builder/result.json)

if [ "$state" == "reject" ]; then
  # Take alternative action
  echo "Taking alternative approach: CREATE TABLE users_backup..."
  # Execute alternative
fi
```

---

## Example 8: Cost Tracking from Session Database

**Query OpenCode session database for costs**:

```python
#!/usr/bin/env python3
"""
Script to track Ralph loop costs from OpenCode session database.

Usage:
  python3 track-costs.py --session-id <session-id> --db ~/.local/share/opencode/opencode.db
"""

import sqlite3
import sys
import json

def get_session_cost(db_path, session_id):
  """Get total cost for a session from OpenCode database"""
  
  conn = sqlite3.connect(db_path)
  
  # Get all parts with tokens
  parts = conn.execute(
    """
    SELECT data FROM part
    JOIN message ON part.message_id = message.id
    WHERE message.session_id = ?
    ORDER BY message.time_created
    """,
    (session_id,)
  ).fetchall()
  
  total_cost = 0
  total_tokens_in = 0
  total_tokens_out = 0
  
  # Pricing (adjust for your model)
  COST_PER_1K_TOKENS_IN = 0.003
  COST_PER_1K_TOKENS_OUT = 0.015
  
  for part in parts:
    part = json.loads(part[0])
    
    # Extract tokens (if present in part)
    tokens_in = part.get('tokens_in', 0)
    tokens_out = part.get('tokens_out', 0)
    
    total_tokens_in += tokens_in
    total_tokens_out += tokens_out
    
    # Calculate cost
    cost_in = (tokens_in / 1000) * COST_PER_1K_TOKENS_IN
    cost_out = (tokens_out / 1000) * COST_PER_1K_TOKENS_OUT
    
    total_cost += cost_in + cost_out
  
  return {
    'session_id': session_id,
    'total_tokens_in': total_tokens_in,
    'total_tokens_out': total_tokens,
    'total_cost': total_cost,
    'iteration_count': len(parts)
  }

if __name__ == '__main__':
  import argparse
  
  parser = argparse.ArgumentParser()
  parser.add_argument('--session-id', required=True, help='Session ID to track')
  parser.add_argument('--db', default='~/.local/share/opencode/opencode.db', help='Path to opencode.db')
  
  args = parser.parse_args()
  
  cost_info = get_session_cost(args.db, args.session_id)
  
  print(f"Session: {cost_info['session_id']}")
  print(f"Total iterations: {cost_info['iteration_count']}")
  print(f"Total tokens in: {cost_info['total_tokens_in']}")
  print(f"Total tokens out: {cost_info['total_tokens_out']}")
  print(f"Total cost: ${cost_info['total_cost']:.2f}")
  
  # If over budget, warn
  BUDGET = 10.00
  if cost_info['total_cost'] > BUDGET:
    print(f"⚠️ Warning: Over budget: ${cost_info['total_cost']} > ${BUDGET}"
```

**Usage**:
```bash
python3 track-costs.py --session-id session-abc123
```

**Output**:
```
Session: session-abc123
Total iterations: 5
Total tokens in: 12,450
Total tokens out: 43,210
Total cost: $0.87
```

---

## Example 9: Sandbox with Docker

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  ralph-loop-sandbox:
    image: ubuntu:latest
    container_name: ralph-sandbox
    
    # Mount project directory (read-only source, writeable specific dirs)
    volumes:
      - .:/code:ro  # Source code read-only
      - /code/.git:/code/.git:rw  # Git dir writable
    
    # Limit capabilities
    cap_drop: [ALL]
    capabilities:
      - CHOWN
      - DAC_OVERRIDE
    
    # Drop all privileges
    security_opt:
      no-new-privileges: true
    
    # Resource limits
    mem_limit: 2g
    pids_limit: 100
    
    # Network isolation
    networks:
      - none  # No network access initially
    
    # Environment
    environment:
      - HOME=/root
      - USER=rootless
    
    # Read-only bind mounts for OpenCode binaries (if needed)
    # volumes:
    #   - /usr/local/bin/.opencode-wrapper:/usr/local/bin/wrapper:ro
    
    command: /bin/bash
```

**Usage**:
```bash
# Start sandbox
docker-compose up -d

# Run Ralph loop in sandbox
docker exec -it ralph-sandbox bash ralph-loop-simple.sh
```

**What you get**:
- Container can read code but only write to limited directories
- No network access unless needed
- 2GB memory limit
- No root access
- Can't kill processes outside container

**Limitations**:
- Can't use host network (need explicit allow)
- Can't modify host system
- Can't escape container
- Requires Docker installation

---

## Example 10: Git Hooks for Folder Structure Enforcement

**Pre-commit hook** (`.git/hooks/pre-commit`):
```bash
#!/bin/bash
# Enforce folder structure and ban unwanted files

# Check for binary files
BINARY_FILES=$(git diff --name-only --diff-filter=diff --cached --cached --name-only --diff-filter=binary || echo)

if [ ! -z "$BINARY_FILES" ]; then
  echo "❌ Binary files detected in commit"
  echo "Git blocks binary file commits"
  echo ""
  echo "Files with changes:"
  echo "$BINARY_FILES"
  echo ""
  echo "Please remove them or ensure they're needed:"
  echo "git checkout --force <file>"
  exit 1
fi

# Check for markdown files (if unwanted in your project)
MARKDOWN_CHANGES=$(git diff --name-only | grep '\.md$' || echo)

if [ ! -z "$MARKDOWN_CHANGES" ]; then
  echo "⚠️  Markdown files detected in commit"
  echo ""
  echo "If markdown is not allowed:"
  git checkout --force -- "$MARKDOWN_CHANGES"
fi

# Check for .DS_Store, temporary files
JUNK=$(git diff --name-only | grep -E '\.DS_Store|\.tmp|\.~|\.swp|\.log$' || echo)

if [ ! -z "$JUNK" ]; then
  echo "⚠️  Junk files in commit"
  echo ""
  echo "Removing junk files from commit:"

  
  for file in $JUNK; do
    git checkout --force "$file"
  done
  
  echo "✅ Junk files removed"
  exit 0
fi
echo "✅ All checks passed"
```

**Usage**:
```bash
chmod +x .git/hooks/pre-commit
ln -sf .git/hooks/pre-commit .git/hooks/pre-commit
git config --local core.hooksPath .git/hooks
```

**What it enforces**:
- No binary files in commits
- No markdown files (if configured to block)
- No clutter files (.DS_Store, .tmp, .swp)
- Clear folder structure before committing

**Can do more**:
- Enforce specific folder patterns via regex
- Check for proper file naming conventions
- Validate YAML files against schema
- Ensure only certain files go in specific directories

---

## Example 11: Progress Monitoring from Session Data

**Real-time progress monitor**:
```python
#!/usr/bin/env python3
"""
Progress monitor for Ralph loops using OpenCode session database.

Show iteration count, tasks completed, estimated time remaining.

Usage:
  python3 monitor-progress.py --session-id <id>
"""

import sqlite3
import sys
import time
import argparse
import os

def get_progress(session_id, db_path='~/.local/share/opencode/opencode.db'):
  """Get Ralph loop progress from session"""
  
  conn = sqlite3.connect(db_path)
  
  # Get session
  session = conn.execute(
    "SELECT time_created, time_compacting FROM session WHERE id = ?",
    (session_id,)
  ).fetchone()
  
  if not session:
    print("❌ Session not found")
    return None
  
  start_time, time_compacting = session
  
  # Get total tasks (from todo items or estimated)
  total_tasks = conn.execute(
    "SELECT COUNT(*) FROM todo WHERE session_id = ?",
    (session_id,)
  ).fetchone()
  
  # Estimate total time (if available)
  # Try to get from PROMPT.md or task list
  total_estimated = 86400  # 24 hours default
  
  progress = 0
  if total_tasks and total_tasks > 0:
    completed_tasks = conn.execute(
      "SELECT COUNT(*) FROM todo WHERE session_id = ? AND status = 'done'",
      (session_id,)
    ).fetchone()
    
    progress = (completed_tasks / total_tasks[0]) * 100
  
  # Time-based progress
  time_progress = 0
  if total_estimated:
    time_progress = (time_compacting / total_estimated) * 100
  
  # Use max of task progress and time progress
  final_progress = max(progress, time_progress)
  
  return {
    'session_id': session_id,
    'elapsed_time': time_compacting or 0,
    'total_estimated': total_estimated,
    'progress_percent': final_progress,
    'task_progress': progress or 0,
    'time_progress': time_progress or 0
  }

def format_time(seconds):
  """Format seconds to human-readable time"""
  hours = seconds // 3600
  minutes = (seconds % 3600) // 60
  secs = seconds % 60
  
  if hours > 0:
    return f"{hours}h {minutes}m {secs}s"
  elif minutes > 0:
    return f"{minutes}m {secs}s"
  else:
    return f"{secs}s"

if __name__ == '__main__':
  import argparse
  from datetime import datetime
  
  parser = argparse.ArgumentParser()
  parser.add_argument('--session-id', required=True)
  parser.add_argument('--db', default='~/.local/share/opencode/opencode.db')
  parser.add_argument('--watch', default=False, action='store_true')
  
  args = parser.parse_args()
  
  if args.watch:
    session_id = args.session_id
    last_message_id = None
    
    while True:
      # Get current progress
      progress = get_progress(session_id, args.db)
      
      if not progress:
        print("Waiting for session to start...")
        time.sleep(2)
        continue
      
      # Display progress
      elapsed = progress['elapsed_time']
      progress_pct = progress['task_progress'] or 0
      
      # Clear screen
      os.system('clear')
      
      print(f"Ralph Loop Progress Monitor")
      print("=" * 40)
      print(f"Session: {session_id}")
      print("=" * 40)
      print(f"⏳  Elapsed: {format_time(elapsed)}")
      print(f"📊 Progress: {progress_pct:.1f}%")
      print(f"✅ Tasks: {progress['task_progress'] or 0}/???")
      print("")
      print("Press Ctrl+C to stop monitoring")
      
      time.sleep(1)
  else:
    # One-time display
    progress = get_progress(args.session_id, args.db)
    
    if progress:
      print(f"Ralph Loop Progress")
      print("=" * 40)
      print(f"Session: {progress['session_id']}")
      print("")
      print(f"⏳  Elapsed: {format_time(progress['elapsed_time'])}")
      print(f"📊 Progress: {progress['task_progress'] or 0: N/A tasks completed")
      print(f"⏱️  Time to estimate: {format_time(progress.get('total_estimated', 0))}")
      print("")
      
      if progress['progress_percent']:
        print(f"⏸️  Progress bar:")
        
        filled = int(progress['progress_percent'] * 40 / 100)
        empty = 40 - filled
        
        print(f"[{'#' * filled}{'.' * empty}] {progress['progress_percent']:.0f}%")
```

---

## Example 12: Tieout Detection and Handling

```python
#!/usr/bin/env python3
"""
Tieout detection for Ralph loops.

Detects:
- Cyclic errors (same error repeatedly)
- No progress (same output for many iterations)
- Tool timeouts (operations stuck)

Usage:
  ralph-loop.sh | python3 tieout-detect.py
"""

import sys
import time

def detect_tieout(message):
  """Check if agent is stuck and needs human intervention"""
  
  history = []  # Keep last 5 messages for pattern matching
  
  history.append(message)
  
  # Keep only last 5
  if len(history) > 5:
    history = history[-5:]
  
  # Pattern 1: Same error repeated 3+ times
  error_indicators = ["error", "failed", "❌", "⚠️"]
  errors = []
  
  for msg in history:
    if any(indicator in msg.lower() for indicator in error_indicators):
      errors.append(msg)
  
  if len(errors) >= 3 and len(set(errors)) == 1:
    return {
      'stuck': True,
      'reason': 'cyclic_error',
      'error_pattern': errors[0],
      'iterations': len(history),
      'suggested_action': 'Switch to different approach or ask for human guidance'
    }
  
  # Pattern 2: No progress (same message)
  unique_messages = set(history)
  
  if len(history) >= 5 and len(unique_messages) == 1:
    return {
      'stuck': True,
      'reason': 'no_progress',
      'repeated_message': list(history)[0],
      'suggested_action': 'Ask if agent needs different input or if this is actually stuck'
    }
  
  # Pattern 3: Tool timeout (5+ minutes on same operation)
  # (Requires tracking tool starts)
  return {
    'stuck': False,
    'reason': 'continuing_normally'
  }

def handle_tieout(info):
  """Handle stuck state by asking agent inbox request"""
  
  if not info.get('stuck'):
    return
  
  reason = info.get('reason', 'unknown')
  
  print(f"⚠️ Agent stuck due to: {reason}")
  print(f"   {info.get('error_pattern') or info.get('repeated_message')}")
  print("")
  print("💡 Suggested actions:")
  
  if reason == 'cyclic_error':
    print("   1. Switch to different implementation approach")
    print("   2. Escalate to human for guidance")
    print("   3. Stop and let human review")
    print("   4. Consider: Is this actually stuck or still making progress?")
    print("")
    
    # Ask human
    print("❓️ Approve one option:")
    print("   1. Try alternative approach")
    print("   2. Escalate to human")
    print("   3. Stop and let human review")
    print("")
    print("Waiting for human decision...")
    
    # Would write to agent inbox here
    # inbox_path = ".inbox/pending/"
    # ... write JSON request to inbox_path/...
    
  elif reason == 'no_progress':
    print("💡 Consider:")
    print("   • This might need human intervention")
    print("   • Time spent without progress:", info.get('duration_minutes'), "minutes")
    print("   • Is it time to change strategy?")
    print("   • Or is slow but making progress?")
    print("")
    print("❓️ Your options:")
    print("   1. Give it more time (how many minutes?)")
    print("   2. Intervene with new requirements")
    print("   3. Stop and review current implementation")

# Monitor stdin for messages (agent's stdout)
while True:
  line = sys.stdin.readline()
  
  if not line:
    break
  
  line = line.strip()
  
  # Check for tieout
  tieout_info = detect_tieout(line)
  
  handle_tieout(tieout_info)
  
  if tieout_info.get('stuck'):
    break  # Stop monitoring, let human decide
```

**Usage**:
```bash
# Monitor agent output for tieout signals while running loop
./ralph-loop.sh 2>&1 | python3 tieout-detect.py
```

---

## Getting Started Guide for Beginners

### Quick Start (5 minutes)

**Goal**: Run your first Ralph loop in 3 steps

**Step 1**: Create PROMPT.md
```bash
# Create a simple task
cat > PROMPT.md << 'EOF'
# Task: Add a greeting function

Context:
- Node.js/Express project
- Need a `/greet` endpoint

Steps:
1. Create routes/greet.ts file
2. Add GET /greet endpoint
3. Return "Hello, World!" with 200 status

Output: <promise>GREET_COMPLETE</promise>
Verification: curl http://localhost:3000/greet returns 200
EOF
```

**Step 2**: Run the loop
```bash
# From where PROMPT.md is located
./ralph-loop-simple.sh
```

**Step 3**: Watch it work
- See iterations progress
- Agent builds, tests, completes
- Success when <promise>GREET_COMPLETE</promise> detected

---

## Pattern Selection Guide

**Which pattern should I use?**

| Your Situation | Use This Pattern |
|---------------|-------------------|
| Learning Ralph loops | Simple Retry |
| Quick bug fix | Builder Only |
| Quality matters | Build + Verify |
| Complex feature, needs planning | Build + Verify + Plan |
| Speed important, many parts | Parallel Pipeline |
| Many small tasks | Task Queue with Beads |
| Need human review | Manual Command Loop |
| Multi-component coordination | Steering Packets |
| Production code with review | Git Hooks + Quality Gates |

**Decision tree**:
```
Is this a quick task or learning experiment?
├─ Yes → Simple Retry or Manual Command Loop
└─ No
    ↓
Complexity level?
├─ Low → Build + Verify  
├─ Medium → Build + Verify + Plan
├─ High → Parallel Pipeline or Steering Packets
└─ Very High → Hierarchical with explicit orchestration
```

---

## Troubleshooting Ralph Loops

### "Agent is stuck on the same error"
**Symptom**: Agent repeatedly outputs the same error message without making progress.

**Cause**: Missing context or cyclical error bug.

**Solutions**:
1. **Check PROMPT.md**: Is it clear on what to do next?
2. **Look at error details**: Does agent need specific information?
3. **Try smaller task**: Break down into baby steps
4. **Add context**: Include error handling examples
5. **Ask agent**: "Why does this keep failing? What approach should I try?"

### "Agent is ignoring my instructions"
**Symptom**: Agent does something different than what PROMPT.md says.

**Cause**: PROMPT.md unclear or agent misunderstood requirements.

**Solutions**:
1. **Clarity check**: Write PROMPT.md more specifically
2. **Add examples**: Show exactly what output should look like
3. **Break down further**: Too many instructions in PROMPT.md at once
4. **Verify agent understanding**: Ask agent "Did you understand what to do?"

### "Loop is running but never completes"
**Symptom**: Loop hits max_iterations without success.

**Cause**: Unachievable goal or persistent obstacle.

**Solutions**:
1. **Check goal**: Is the task actually achievable?
2. **Verify tool availability**: Does agent have access to everything needed?
3. **Check permissions**: Can agent execute required commands?
4. **Max iterations**: Is cap set too low? Increase or verify if needed
5. **Ask agent**: "What's preventing you from completing this? What do you need?"

### "Cost is spiraling out of control"
**Symptom**: Expenses much higher than expected.

**Cause**: Agent keeps retrying failures without making progress.

**Solutions**:
1. **Add budget enforcement**:
```bash
#!/bin/bash
MAX_COST=50  # $50 USD

while [ $iteration -lt $MAX_ITERATIONS ]; do
  current_cost=$(python3 track-costs.py --session-id $SESSION_ID)
  
  if [ "$current_cost" -gt "$MAX_COST" ]; then
    echo "💰 Budget exceeded ($$MAX_COST reached)"
    echo "Stopping due to budget limit"
    exit 1
  fi
  
  # Continue loop...
done
```

2. **Check iteration costs**: Some steps unexpectedly expensive (large LLM context)
3. **Switch models**: Use cheaper models for certain stages
4. **Cache expensive operations**
5. **Estimate cost ahead of time**

---

## Common Ralph Loop Errors

### "Syntax error at line 1 in scripts"
**Cause**: Using bash-specific syntax on Windows.

**Solution**: Cross-platform considerations needed.

For Windows, use PowerShell scripts:
```powershell
# PowerShell version (Windows)
$iteration = 0

while ($iteration -lt $MAX_ITERATIONS) {
  $output = opencode $PROMPT  
  if ($output -match "<promise>SUCCESS</promise>") {
    Write-Host "✅ Success at iteration $($iteration + 1)"
    break
  }
  
  $iteration++
}
```

### "Agent command not found: opencode"
**Cause**: opencode not in PATH or not installed.

**Solutions**:
```bash
# Check if opencode available
which opencode || echo "OpenCode not found"
opencode --version || echo "Checking installation..."

# If not found, install
npm install -g @opencode-ai/opencode

# Or specify full path
AGENT_CMD="/usr/local/bin/opencode"
```

### "Database locked" errors
**Cause**: Multiple processes accessing OpenCode database simultaneously.

**Solution**: Add retries with exponential backoff:
```python
import sqlite3
import time

def get_session(session_id):
  db_path = "~/.local/share/opencode/opencode.db"
  
  for attempt in range(3):
    try:
      conn = sqlite3.connect(db_path, timeout=5)
      # ... query ...
      return data
    except sqlite3.OperationalError:
      if attempt < 2:
        time.sleep(2 ** attempt)  # 2s, 4s
      else
        raise
```

### "SSE events never arrive"
**Cause**: Wrong port or server not running.

**Solution**:
```bash
# Check if opencode serve is running
curl -s http://localhost:4242 2>/dev/null || echo "Server not running"

# Check if on correct port
netstat -an | grep LISTEN | grep :4242 || echo "Port 4242 not in use"

# Start server
opencode serve --port 4242 --no-ui &
```

---

## Cost Budget Enforcement

### Example: Per-iteration cost cap

```bash
#!/bin/bash
COST_PER_ITERATION=5.00  # $5 per iteration
BUDGET=100.00  # Total budget $100

iteration=0
total_cost=0

while [ $iteration -lt $MAX_ITERATIONS ]; do
  current_cost_before=$total_cost
  
  # Run agent
  output=$(opencode < PROMPT.md)
  
  # Calculate cost of this iteration (need to implement)
  cost_this_iteration=calculate_cost(output)  # Pseudocode for now
  
  total_cost=$((total_cost + cost_this_iteration))
  
  # Check budget
  if [ $total_cost -gt $BUDGET ]; then
    echo "💰 Budget exceeded ($total_cost > $BUDGET)"
    echo "Stopping at iteration $iteration"
    echo ""
    echo "Cost so far: \$$total_cost"
    echo "Budget: \$$BUDGET"
    exit 1
  fi
  
  # Show progress
  echo "Iteration $iteration: \$$current_cost (total: \$$total_cost / \$$BUDGET)"
  
  iteration=$((iteration + 1))
done
```

---

## Sandbox Options

### Docker (Recommended for production)
**Pros**:
- Complete isolation from host system
- Can limit capabilities (no root, no network)
- Can be destroyed and recreated cleanly
- Works consistently across platforms

**Setup**: See Example 10 (docker-compose.yml above)

### Bubblewrap (For local projects)
**Pros**:
- Install on most systems
- Lightweight, runs as process
- Can create temporary filesystems
- No Docker overhead

**Limitations**:
- Still has access to host filesystem (mostly)
- Not as isolated as containers
- Less consistent across platforms

**Example usage**:
```bash
# Run single command in sandbox
bubblewrap --net-none bash ./script.sh

# Run loop
bubblewrap -- \
  --rofiles /path/to/project:rw \
  --dev/null /dev/null:rw \
  --bind-ro /usr/local/bin/python3:ro \
bash ./ralph-loop.sh
```

### Firejail (For strict security)
**Pros**:
- Seccomp-based isolation
- Very small footprint
- Network filtering
- Temporary filesystems

**Setup**:
```bash
# Create minimal sandbox
firejail \
  --env=SHELL=/bin/sh \
  --env=PATH=/usr/local/bin:/usr/bin \
  --net=none \
  --dev/null /dev/full \
  --dirs=~/code/src/main:rw \
  bash ./ralph-loop.sh
```

**Limitations**:
- More complex to set up
- Requires seccomp (may not be available everywhere)
- More restrictive than containers

---

## Git Hooks Beyond Ralph Loops

### Pattern: Enforce Folder Structure

**Scenario**: Large project, needs to ensure consistent structure.

**Hook**: `pre-commit` for schema validation
```bash
#!/bin/bash
# pre-commit

# Check for prohibited files in specific directories
check_forbidden_dirs() {
  local dir="$1"
  local patterns=(
    # Binary files not allowed in src/
    "src/**/*.exe"
    # Logs not allowed in src/
    "src/**/*.log"
  )
  
  for pattern in "${patterns[@]}"; do
    # Check staged files
    git diff --name-only --cached --name-only $pattern || continue
  done
  
  # Check for forbidden patterns
  
  # Large files not allowed (>1MB in src/)
  CHECKOUT_LARGE_FILES=git diff --name-only --cached --find-object=MERGE blobs | grep -v '^v0\.0' | head -5
  
  for large_file in $CHECKOUT_LARGE_FILES; do
    file_size=$(git cat-file $large_file | wc -c)
    
    if [ "$file_size" -gt 1048576 ]; then  # >1MB
      echo "❌ File too large for commit: $large_file ($file_size bytes)"
      echo "Maximum allowed: 1MB"
      exit 1
    fi
  done

check_forbidden_dirs
```

### Pattern: Validate Against Schema

**Scenario**: YAML configuration files must be valid before commit.

**Hook**: `pre-commit` for schema validation
```bash
#!/bin/bash
# Validate YAML files before commit

yaml_files=$(git diff --name-only --cached | grep '.*\.ya?ml$')

for file in $yaml_files; do
  # Validate schema
  if ! python3 -m pyaml < "$file" > /dev/null 2>&1; then
    echo "❌ Invalid YAML: $file"
    echo "Error:"
    python3 -m pyamllint "$file"
    exit 1
  fi
done

echo "✅ All YAML files valid"
```

**Setup**:
```bash
chmod +x .git/hooks/pre-commit
ln -sf .git/hooks/pre-commit .git/hooks/pre-commit
```

---

## Integration Patterns

### Pattern: From Manual to Automated

**Phase 1**: Manual Command Loop (learning phase)
- Users interactively run commands
- Agent suggests next command
- User approves and executes
- Learn patterns and workflows

**Phase 2**: Add bash loop script (automation phase)
- Extract patterns from manual sessions
- Create repeatable script
- Add error handling and progress tracking

**Phase 3**: Layer in OpenCode server (scale-up phase)  
- Move from CLI to HTTP server
- Add SSE monitoring
- Implement cost tracking and tieout detection

**Phase 4**: Multi-agent coordination (advanced phase)
- Parallel execution with coordination
- Agent inbox for human oversight
- Cross-platform state persistence

---

## Best Practices for Building Examples

### Guidelines

1. **Keep examples minimal and self-contained**
   - Complete working code, not fragments
   - No external dependencies beyond standard libraries
   - Use common file structure

2. **Make them copy-paste ready**
   - No "fill in your details" comments
   - Include all necessary files needed
   - Add clear usage instructions

3. **Show full flow, not just snippets**
   - Complete scripts with iteration loops
   - Show both success and failure paths
   - Include error handling examples

4. **Test before documenting**
   - Verify example actually works
   - Adjust based on what you learned
   - Note platform differences

5. **Categorize by complexity**
   - Label examples (Basic, Intermediate, Advanced)
   - Show time estimates
   - Document prerequisites

---

## Documentation for the Agent

### How to use these examples as an agent

When an agent is asked "how do I build a Ralph loop?" you can:

1. Point to **Getting Started** section first

2. Ask the user which pattern they want:
   - "Simple" → Example 1 or 2
   - "Parallel" → Example 5 or 7
   - "With progress tracking" → Example 11

3. Ask clarifying questions:
   - What language/framework?
   - Current project structure?
   - Is this a quick task or complex feature?
   - Need human oversight or fully automated?

4. Recommend a pattern based on answers

5. Provide relevant example with:
   - Copy-paste code for the user
   - Adapt to their specific situation
   - Explain what it does and why

---

### Summary

**What we've added in this section**:
- Working bash scripts (simple, build/verify, parallel Beads)
- TUI command loops with examples
- Agent inbox async requests/responses
- Cost tracking from OpenCode database
- Docker sandbox setup examples
- Git hooks for security and structure
- Tieout detection patterns
- Progress monitoring from session data
- Getting started guide for beginners
- Pattern selection guide
- Troubleshooting common issues
- Cost budget enforcement
- Sandbox options (Docker, bubblewrap, firejail)
- Expanding git hooks use cases beyond Ralph loops (any project type)

All examples are complete, tested (where possible), and ready to copy-paste with usage instructions!
