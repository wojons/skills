# Progress, Telemetry & State Management in Ralph Loops

## Overview

Users of Ralph loops want visibility into progress and cost. This guide covers:
- Progress tracking (stages, steps, completion)
- Cost tracking (iteration costs, total cost)
- State persistence for graceful interruption
- Hotkeys for controlled stopping
- Retrieving session logs from OpenCode
- Tieout features for stuck agents
- **Cross-platform state location discovery**

---

## Finding OpenCode State Across Platforms

### Default State Location

OpenCode stores its database in XDG Base Directory locations:

| Platform | Default Path | Location Type |
|----------|-------------|---------------|
| **macOS** | `~/.local/share/opencode/` | User Library |
| **Linux** | `~/.local/share/opencode/` | XDG Data Home |
| **Windows** | `~/.local/share/opencode/` | User AppData |

### How Agents Find the Database

**Method 1: Environment Variable Detection**

OpenCode typically sets `OPENCODE_STATE_DIR` or can be configured via:

```bash
# On all platforms, check these locations in order:
1. Environment variable: $OPENCODE_STATE_DIR
2. Default: ~/.local/share/opencode/
```

**Detecting state programmatically**:

```python
import os

def find_opencode_db():
  # Check env var first
  env_path = os.getenv('OPENCODE_STATE_DIR')
  if env_path:
    return env_path
  
  # Use platform-specific default
  platform = os.uname().sysname
  
  if platform == 'Windows':
    # Check common Windows locations
    paths = [
      os.path.expanduser("~/.local/share/opencode/"),
      os.path.expanduser("~/AppData/Local/opencode"),
      os.path.expanduser("~/AppData/Roaming/opencode"),
    ]
  else:  # macOS and Linux
    paths = [
      os.path.expanduser("~/.local/share/opencode/"),
      os.path.expanduser("~/.local/state/opencode"),
      os.path.expanduser("~/Library/Application Support/opencode"),
    ]
  
  for path in paths:
    db_path = os.path.join(path, "opencode.db")
    if os.path.exists(db_path):
      return path
  
  return None  # Not found

# Usage
db_path = find_opencode_db()
if db_path:
  print(f"Found OpenCode database at: {db_path}")
else:
  print("OpenCode database not found")
```

**Method 2: Binary Inspection**

```bash
# Find opencode binary to determine install path
which opencode  # /usr/local/bin/opencode

# Get install location
opencode_path=$(which opencode)

# Infer state location
case "$os" in
  Darwin)  # macOS
    STATE_DIR="${opencode_path//bin}/../share/opencode/"
    ;;
  Linux)
    # Check if using Flatpak, Snap, or AppImage
    if [[ "$opencode_path" == */snap/opencode* ]]; then
      STATE_DIR="$HOME/.local/share/opencode/"
    else
      STATE_DIR="$HOME/.local/share/opencode/"
    fi
    ;;
  MINGW*|MSYS*|Windows_NT)  # Windows
    STATE_DIR="$APPDATA/opencode/"
    ;;
esac

echo "State directory: $STATE_DIR"
```

**Method 3: Process Inspection**

```python
import psutil

def find_opencode_process():
  for proc in psutil.process_iter(['name', 'exe']):
    try:
      if 'opencode' in proc.name.lower() or proc.info.get('cwd', ''):
        # Found opencode process
        # Get working directory
        cwd = proc.info.get('cwd', '')
        
        # Check relative paths from cwd
        possible_db_paths = [
          ".opencode/db/opencode.db",
          "share/opencode/db/opencode.db",
          "local/share/opencode/opencode/db",
          "./opencode.db"
        ]
        
        for db_path in possible_db_paths:
          full_path = os.path.join(cwd, db_path)
          if os.path.exists(full_path):
            return full_path
    except (psutil.NoSuchProcess, psutil.AccessDenied):
      continue
  
  return None
```

### Platform-Specific Examples

**macOS**:
```bash
# Default location
~/.local/share/opencode/opencode.db

# Check via opencode CLI
opencode print-state-path  # If available
# Or inspect environment
echo $OPENCODE_STATE_DIR

# Verify location
ls -la ~/.local/share/opencode/opencode.db
```

**Linux**:
```bash
# Check multiple locations
ls ~/.local/share/opencode/
ls ~/.local/state/opencode/

# Or use find
find ~/.local -name "opencode.db" 2>/dev/null

# Get from opencode
opencode --help 2>/dev/null | grep -i state
```

**Windows**:
```powershell
# Check AppData locations
$env:LOCALAPPDATA\opencode\opencode.db
$env:APPDATA\opencode\opencode.db

# Using PowerShell to find
Get-ChildItem -Recurse -Filter "opencode.db" -ErrorAction SilentlyContinue

# Check Registry (if installed via MSI)
Get-ItemProperty 'HKLM:\Software\OpenCode\InstallPath' -ErrorAction SilentlyContinue

# Or inspect process
Get-Process opencode | Select-Object -ExpandProperty *
```

### Generic Algorithm for Any Agent

```python
def find_opencode_state():
  """
  Generic method to find OpenCode database across platforms.
    Returns: path to opencode.db or None
  """
  import os
  import platform
  
  # Step 1: Check environment variable (highest priority)
  env_dir = os.getenv(
    'OPENCODE_STATE_DIR',
    os.getenv('OPENCODE_DB_PATH')  # Alternative name
  )
  
  if env_dir:
    db_path = os.path.join(env_dir, 'opencode.db')
    if os.path.exists(db_path):
      return db_path
  
  # Step 2: Platform-specific defaults
  home = os.path.expanduser('~')
  
  if platform.system() == 'Windows':
    # Windows AppData locations
    locations = [
      home + r'\.local\state\opencode\opencode.db',
      os.environ.get('LOCALAPPDATA', '') + r'\opencode\opencode.db',
      os.environ.get('APPDATA', '') + r'\opencode\opencode.db',
      r'C:\ProgramData\opencode\opencode.db',  # Possible common path
    ]
  else:  # macOS and Linux
    locations = [
      home + '/.local/share/opencode/opencode.db',
      home + '/.local/state/opencode/opencode.db',
      home + '/.opencode-bin/opencode/opencode.db',
      home + '/Library/Application Support/opencode/opencode.db',  # macOS only
    ]
  
  for db_path in locations:
    if os.path.exists(db_path):
      return db_path
  
  # Step 3: Process discovery (last resort)
  try:
    import psutil
    
    for proc in psutil.process_iter(['name', 'cwd', 'exe']):
      try:
        if 'opencode' in (proc.name() or '').lower():
          cwd = proc.info['cwd']
          
          # Search relative to process directory
          search_paths = [
            'opencode.db',
            'share/opencode/opencode.db',
            'db/opencode.db',
            '../.opencode/opencode.db',
          ]
          
          for search in search_paths:
            attempt = os.path.join(cwd, search)
            if os.path.exists(attempt):
              return attempt
      except (psutil.NoSuchProcess, Exception):
        continue
  except ImportError:
    pass  # psutil not available
  
  return None  # Could not find database
```

### Testing State Location Discovery

```bash
# Test script to verify location detection

# macOS/Linux
test_opencode_state_location() {
  python3 -c "
import os
import os.path

paths = [
  '~/.local/share/opencode/opencode.db',
  '~/.local/state/opencode/opencode.db',
  '~/.opencode-bin/opencode/opencode.db'
]

for path in paths:
  expanded = os.path.expanduser(path)
  print(f'Checking: {path}')
  print(f'  Exists: {os.path.exists(expanded)}')
"
}

# Windows
test_windows_state_location() {
  powershell -Command "
    \$paths = @(
      '\$env:LOCALAPPDATA\\opencode\\opencode.db',
      '\$env:APPDATA\\opencode\\opencode.db',
      [System.Environment]::GetFolderPath('LocalApplicationData') + '\\opencode\\opencode.db'
    )
    
    foreach (\$path in \$paths) {
      if (Test-Path \$path) {
        Write-Host \"Found: \$path\"
        return
      }
    }
  "
}
```

### Agent Usage Pattern

**How an agent discovers OpenCode state**:

```markdown
# In PROMPT.md:

When you need information about progress or cost, access the OpenCode database:

Step 1: Find the database
  - Use generic discovery algorithm:
    1. Check OPENCODE_STATE_DIR environment variable
    2. Try platform-specific defaults
    3. Fall back to process discovery

Step 2: Query relevant data
  - Tables to check: session, message, part, project, todo
  - Key fields: time_compacting, tokens_in, tokens_out, time_created

Step 3: Parse JSON data from `data` field
  - Message structure is JSON with: tokens, tool results, content
  - Token counts for cost calculation
  - Time fields for duration tracking
```

**Python helper function agents can import**:

```python
# save as: opencode_utils.py

import sqlite3
import os
import platform

class OpenCodeState:
  """Generic OpenCode state access for Ralph loops"""
  
  def __init__(self):
    self.db_path = self.find_db_path()
    
  def find_db_path(self):
    """Locate opencode.db across platforms"""
    
    # 1. Environment variable
    env_paths = [
      os.getenv('OPENCODE_STATE_DIR'),
      os.getenv('OPENCODE_DB_PATH')
    ]
    for env_path in env_paths:
      if env_path:
        candidate = os.path.join(env_path, 'opencode.db')
        if os.path.exists(candidate):
          return candidate
    
    # 2. Platform defaults
    home = os.path.expanduser('~')
    
    if platform.system() == 'Windows':
      candidates = [
        home + r'\.local\state\opencode\opencode.db',
        os.environ.get('LOCALAPPDATA', '') + r'\opencode\opencode.db',
        os.environ.get('APPDATA', '') + r'\opencode\opencode.db'
      ]
    else:
      candidates = [
        home + '/.local/share/opencode/opencode.db',
        home + '/.local/state/opencode/opencode.db',
        home + '/.local/bin/opencode/opencode.db'
      ]
    
    for candidate in candidates:
      if os.path.exists(candidate):
        return candidate
    
    return None
  
  def get_session(self, session_id):
    """Get session metadata"""
    self._ensure_connected()
    
    return self.conn.execute(
      "SELECT * FROM session WHERE id = ?",
      (session_id,)
    ).fetchone()
  
  def get_messages(self, session_id, limit=None):
    """Get all messages for a session"""
    self._ensure_connected()
    
    limit_clause = f"LIMIT {limit}" if limit else ""
    
    return self.conn.execute(
      f"SELECT data FROM message WHERE session_id = ? ORDER BY time_created {limit_clause}",
      (session_id,)
    ).fetchall()
  
  def get_parts(self, message_id, limit=100):
    """Get parts for a message"""
    self._ensure_connected()
    
    return self.conn.execute(
      f"SELECT data FROM part WHERE message_id = ? ORDER BY time_created LIMIT {limit}",
      (message_id,)
    ).fetchall()
  
  def get_progress(self, session_id):
    """Get progress summary for a session"""
    self._ensure_connected()
    
    session = self.get_session(session_id)
    
    # Get time data
    time_compacting = session['time_compacting'] or 0
    total_time = session.get('time_estimated', 0)
    
    # Calculate progress if total estimated time exists
    progress = (time_compacting / total_time * 100) if total_time else 0
    
    return {
      'time_elapsed': time_compacting,
      'time_total': total_time,
      'progress_percent': progress,
      'status': session.get('status', 'unknown')
    }
  
  def get_cost(self, session_id):
    """Get cost summary for a session"""
    self._ensure_connected()
    
    # Get all message parts with token data
    parts = self.conn.execute(
      f"""
      SELECT data FROM part
      JOIN message ON part.message_id = message.id
      WHERE message.session_id = ?
      ORDER BY message.time_created
      """,
      (session_id,)
    ).fetchall()
    
    total_cost = 0
    tokens_in_total = 0
    tokens_out_total = 0
    iteration_costs = []
    
    # Pricing (adjust these rates for your model)
    COST_PER_1K_TOKENS_IN = 0.003
    COST_PER_1K_TOKENS_OUT = 0.015
    
    for part in parts:
      part = json.loads(part[0])
      
      # Extract tokens
      tokens_in = part.get('tokens_in', 0)
      tokens_out = part.get('tokens_out', 0)
      
      tokens_in_total += tokens_in
      tokens_out_total += tokens_out
      
      # Calculate cost
      cost = (tokens_in / 1000) * COST_PER_1K_TOKENS_IN
      cost += (tokens_out / 1000) * COST_PER_1K_TOKENS_OUT
      
      iteration_costs.append(cost)
      total_cost += cost
    
    return {
      'tokens_in_total': tokens_in_total,
      'tokens_out_total': tokens_out_total,
      'iteration_costs': iteration_costs,
      'total_cost': total_cost,
      'average_cost_per_iteration': total_cost / len(iteration_costs) if iteration_costs else 0,
      'cost_so_far': total_cost
    }
  
  def _ensure_connected(self):
    """Connect to database if not connected"""
    if not hasattr(self, 'conn') or not self.conn:
      self.conn = sqlite3.connect(self.db_path)
      self.conn.row_factory = sqlite3.Row()
```

---

## OpenCode State Architecture

## OpenCode State Architecture

### Database Location

OpenCode session state is stored in:
```
~/.local/share/opencode/opencode.db
```

**Key tables**:
- **session**: Session metadata (time_compacting, time_archived, status)
- **message**: Message data with session_id and timestamps
- **part**: Individual message parts (tokens, tool execution)
- **project**: Project worktree, VCS, commands, sandboxes
- **todo**: TODO items with session linkage

### Session Table Schema

```sql
id              TEXT PRIMARY KEY
project_id      TEXT
parent_id       TEXT
slug            TEXT
directory       TEXT
title           TEXT
version         TEXT
share_url       TEXT
time_created    INTEGER
time_updated    INTEGER
time_compacting  INTEGER  -- Time spent actively working
time_archived   INTEGER
```

### Message Table Schema

```sql
id          TEXT PRIMARY KEY
session_id   TEXT             -- Links message to session
time_created INTEGER
time_updated INTEGER
data         TEXT             -- JSON with message content
```

### Part Table Structure

The `part` table typically contains:
- Message parts (user messages, assistant responses)
- Tool executions (bash, read, write, etc.)
- Token counts (input/output)
- Agent state changes
- Session events

---

## Reading Session Logs

### Accessing Session Data

```bash
# List recent sessions
sqlite3 ~/.local/share/opencode/opencode.db "SELECT id, title, time_updated, time_compacting FROM session ORDER BY time_updated DESC LIMIT 10;"

# Get messages for a session
sqlite3 ~/.local/share/opencode/opencode.db "SELECT * FROM message WHERE session_id = '<session-id>' ORDER BY time_created;"

# Get parts (tokens, tools executed)
sqlite3 ~/.local/share/opencode/opencode/opencode.db "SELECT * FROM part WHERE message_id = '<message-id>';"
```

### Message Data Format

The `data` field in the message table is JSON containing the full message:

```json
{
  "type": "message",
  "id": "msg_abc123",
  "content": "I will build the authentication system...",
  "model": "anthropic/claude-sonnet-4-20250514",
  "tokens_in": 2345,
  "tokens_out": 8231,
  "tools_used": [
    {
      "type": "bash",
      "command": "npm test",
      "exit_code": 0,
      "duration_ms": 1500
    }
  ]
}
```

---

## Progress Tracking

### Tracking Ralph Loop Stages

Ralph loops have distinct "flows" or "stages":

**Example flows**:
```
Planning → Building → Verifying → Testing → Deployment
Planner → Builder → Verifier → Merger → Planner (loop back)
```

**Stage Detection** via part parsing:

```python
import sqlite3
import json

db_path = "~/.local/share/opencode/opencode.db"
conn = sqlite3.connect(db_path)

def get_stages(session_id):
  parts = conn.execute(
    """
    SELECT data FROM part
    JOIN message ON part.message_id = message.id
    WHERE message.session_id = ?
    ORDER BY message.time_created
    """,
    (session_id,)
  ).fetchall()
  
  stages = []
  current_stage = None
  
  for part_data in parts:
    part = json.loads(part_data[0])
    
    if part["type"] == "message":
      content = part["content"]
      
      # Detect stage changes
      if "Building authentication system" in content:
        current_stage = "Building"
      elif "Testing" in content:
        current_stage = "Testing"
      elif "Deployment" in content:
        current_stage = "Deployment"
        
      stages.append({
        "type": "stage",
        "name": current_stage,
        "timestamp": part.get("time_created")
      })
      
  return stages
```

### Task-Level Progress

Counting tasks within a stage:

```python
def count_tasks(session_id):
  parts = conn.execute(
    """
    SELECT data FROM part
    JOIN message ON part.message_id = message.id
    WHERE message.session_id = ? AND part.data LIKE '%done%'
    """,
    (session_id,)
  ).fetchall()
  
  # Count task completions
  task_count = len([p for p in parts if "✓" in p or "</promise>" in p])
  
  return {
    "total_tasks": task_count,
    "completed": 0,  # Need to track task IDs
    "remaining": 0
  }
```

### Progress Bar Display

Using time_elapsed vs. estimated_total:

```python
def get_progress(session_id):
  # Get session duration
  session = conn.execute(
    "SELECT time_compacting FROM session WHERE id = ?",
    (session_id,)
  ).fetchone()
  
  time_compacting = session[0] if session else 0
  
  # Estimated time (prompts can store this)
  estimated_total = conn.execute(
    "SELECT time_estimated FROM session WHERE id = ?",
    (session_id,)
  ).fetchone()
  
  progress = (time_compacting / estimated_total[0]) * 100 if estimated_total else 0
  
  return {
    "time_elapsed": time_compacting,
    "time_total": estimated_total[0],
    "progress_percent": progress,
    "stage": get_current_stage(session_id)
  }
```

---

## Cost Tracking

### Token-Based Cost Calculation

**Pricing** (example, adjust for actual rates):
```python
COST_PER_1K_TOKENS_IN = 0.003  # $0.003 per 1K input tokens
COST_PER_1K_TOKENS_OUT = 0.015  # $0.015 per 1K output tokens
```

**Calculate per iteration**:

```python
def calculate_iteration_cost(session_id):
  parts = conn.execute(
    """
    SELECT data FROM part
    JOIN message ON part.message_id = message.id
    WHERE message.session_id = ?
    """,
    (session_id,)
  ).fetchall()
  
  total_cost = 0
  total_tokens_in = 0
  total_tokens_out = 0
  
  for part_data in parts:
    part = json.loads(part_data[0])
    
    if part.get("tokens_in"):
      tokens_in = part["tokens_in"]
      tokens_out = part.get("tokens_out", 0)
      
      total_tokens_in += tokens_in
      total_tokens_out += tokens_out
      
      # Accumulate cost
      cost = (tokens_in / 1000) * COST_PER_1K_TOKENS_IN
      cost += (tokens_out / 1000) * COST_PER_1K_TOKENS_OUT
      
      total_cost += cost
  
  return {
    "tokens_in_total": total_tokens_in,
    "tokens_out_total": total_tokens_out,
    "cost_this_iteration": total_cost,
    "iteration_count": len(parts)
  }
```

### Accumulated Cost Tracking

**Cumulative costs across iterations**:

```python
def get_total_loop_cost(session_id):
  parts = conn.execute(
    """
    SELECT data FROM part
    JOIN message ON part.message_id = message.id
    WHERE message.session_id = ?
    """,
    (session_id,)
  ).fetchall()
  
  # Sum across all iterations
  total_cost = 0
  iteration_costs = []
  
  for part_data in parts:
    parts = [json.loads(part_data[0])]
    
    for part in parts:
      tokens_in = part.get("tokens_in", 0)
      tokens_out = part.get("tokens_out", 0)
      
      cost = (tokens_in / 0.003) + (tokens_out / 0.015)
      iteration_costs.append(cost)
      total_cost += cost
  
  return {
    "iteration_costs": iteration_costs,
    "total_cost": total_cost,
    "average_cost_per_iteration": total_cost / len(iteration_costs) if iteration_costs else 0,
    "cost_so_far_this_session": total_cost
  }
```

### Real-Time Cost Estimates

**Rate limiter**: Check costs periodically:

```python
import time

def monitor_loop_cost(session_id, interval_seconds=30):
  start_time = time.time()
  
  while True:
    cost_info = get_total_loop_cost(session_id)
    
    elapsed = time.time() - start_time
    rate = cost_info["cost_so_far"] / elapsed_time
    
    print(f"📊 Cost: ${cost_info['cost_so_far']:.2f} | ${rate:.2f}/hr")
    print(f"⏱️  Time: {elapsed/60:.1f}m")
    
    time.sleep(interval_seconds)
    
    # Add stop condition
    # Can be interrupted by Ctrl+C
```

---

## State Persistence for Interruption

### Graceful Stopping with Context Preservation

**When Ctrl+C is pressed in a Ralph loop**:

```python
# 1. Check current state
current_task = get_current_task(session_id)
in_progress_files = get_in_progress_files(session_id)
last_successful_step = get_last_successful_step(session_id)

# 2. Save interrupt point
interrupt_state = {
  "session_id": session_id,
  "interrupted_at": time.time(),
  "current_task_id": current_task.get("id"),
  "current_task_title": current_task.get("title", "Unknown"),
  "in_progress_files": in_progress_files,
  "last_successful_step": last_successful_step,
  "iteration_count": current_task.get("iteration", 0),
  "next_action": "continue"
}

# 3. Write interrupt state
write_interrupt_state(interrupt_state)

# 4. Mark session as interrupted
conn.execute(
  "UPDATE session SET status = 'interrupted', time_updated = ? WHERE id = ?",
  (int(time.time()), session_id)
)

print("✅ Gracefully interrupted with state saved")
print(f"✅ Next action: {interrupt_state['next_action']}")
print(f"✅ Can resume with: opencode continue {session_id}")
```

### Resuming Interrupted Ralph Loop

**Continuation command**:

```python
def resume_ralph_loop(session_id):
  # Read interrupt state
  state = read_interrupt_state(session_id)
  
  if not state:
    print("❌ No saved state found. Cannot resume.")
    return
  
  # Restore context
  last_messages = get_messages_since(
    state["last_successful_step"]["time_created"]
  )
  
  # Inject last successful context into next prompt
  continuation_prompt = f"""
You were interrupted. Continue from where you left off.

Previous task: {state['current_task_title']}
Last successful step: {state['last_successful_step']['title']}
Files in progress: {', '.join(state['in_progress_files'])}

Pick up from there and continue toward:
<promise>TASK_COMPLETE</promise>
"""
  
  # Send continuation message
  # This would be an opencode command or API call
  
  print(f"✅ Resuming Ralph loop {session_id}...")
  print(f"📍 At step: {state['iteration_count']} of 20")
  print(f"→ Next action: {state['next_action']}")
```

---

## Hotkeys for Controlled Stopping

### Implementing TUI Hotkeys

For terminal-based interfaces, bind hotkeys for loop control:

```python
# TUI hotkey handler
import keyboard

def monitor_for_hotkeys(session_id):
  print("⌨️ Ralph Loop Control")
  print("  [Ctrl+C]   - Pause and save state")
  print("  [Ctrl+D]   - Stop after current task")
  print("  [Ctrl+R]   - Resume from checkpoint")
  print("  [Esc]     - Stop immediately (emergency)")
  
  while True:
    key = keyboard.read_key()
    
    if key == '\x03':  # Ctrl+C
      graceful_interrupt(session_id)
    
    elif key == '\x04':  # Ctrl+D
      stop_after_task(session_id)
    
    elif key == '\x12':  # Ctrl+R
      resume_ralph_loop(session_id)
    
    elif key == '\x1b':  # Esc
      emergency_stop(session_id)
```

### Next Phase Stopping

**Stop at safe checkpoint**:

```python
def stop_at_next_phase(session_id):
  # Find next "phase boundary"
  messages = get_messages(session_id)
  
  for msg in reversed(messages):
    msg = json.loads(msg["data"])
    
    # Detect phase boundaries
    if "</promise>" in msg["content"] or "PHASE_COMPLETE" in msg["content"]:
      # Found safe stopping point
      return {
        "safe_to_stop": True,
        "last_message": msg,
        "next_iteration": msg["iteration_count"] + 1
      }
  
  return {
    "safe_to_stop": False,
    "suggestion": "Let current task complete"
  }
```

**Usage**:
```bash
# When user requests stop:
result = stop_at_next_phase(session_id)

if result["safe_to_stop"]:
  print("✅ Safe to stop at current phase")
  print(f"✅ Next iteration will be: {result['next_iteration']}")
else:
  print("⚠️  Not safe to stop - let current task complete")
```

---

## Tieout Features (Agent Stuck Detection)

### Detecting Stuck Agents

Agents can get stuck on:
- Cyclic errors (same failed task repeatedly)
- Dependency not meeting
- Tool execution timeouts
- API rate limits

**Stuck detection algorithm**:

```python
def detect_stuck_state(session_id):
  # Check recent messages for stuck patterns
  
  messages = get_recent_messages(session_id, limit=10)
  
  # Pattern 1: Same error repeatedly
  errors = [msg for msg in messages if "error" in msg["content"].lower()]
  if len(errors) >= 3 and errors == errors[-1]:  # Last 3 are the same
    return {
      "stuck": True,
      "reason": "cyclic_error",
      "error_message": errors[0]["content"]
    }
  
  # Pattern 2: No progress (same message content)
  last_messages = [msg["content"] for msg in messages[-5:]]
  if len(set(last_messages)) == 1 and len(last_messages) == 5:
    return {
      "stuck": True,
      "reason": "no_progress",
      "repeated_message": last_messages[0]
    }
  
  # Pattern 3: Tool timeout (bash command stuck)
  parts = get_recent_parts(session_id, limit=10)
  bash_parts = [p for p in parts if p.get("tool") == "bash"]
  
  for part in bash_parts:
    if part.get("duration_ms", 0) > 300000:  # 5 minutes
      return {
        "stuck": True,
        "reason": "tool_timeout",
        "tool": part.get("command"),
        "duration": part["duration_ms"] / 1000
      }
  
  return {"stuck": False}
```

### Tieout Actions

When stuck, take action:

```python
def handle_tieout(session_id, stuck_info):
  reason = stuck_info["reason"]
  
  if reason == "cyclic_error":
    # Suggest alternative approach
    print("⚠️  Agent stuck on cyclic error")
    print("   💡 Try: Ask agent to switch to different strategy")
    print("   💡 Consider: Escalating to human for guidance")
    
    # Optional: Ask human to intervene
    agent_inbox_request(session_id, {
      "request_type": "tieout",
      "title": "Agent stuck on cyclic error",
      "context": {
        "error_pattern": stuck_info["error_message"],
        "iterations": get_iteration_count(session_id)
      },
      "suggested_resolutions": [
        "Switch to different implementation approach",
        "Escalate to human for guidance",
        "Stop and let human review"
      ]
    })
    
  elif reason == "no_progress":
    print("⚠️  Agent not making progress")
    
    # Check if just slow or truly stuck
    duration = time.time() - get_session_start(session_id)
    
    if duration > 600:  # 10 minutes with no progress
      print(f"💡 Consider: This may need human intervention")
      print(f"💡 Time without progress: {duration/60:.0f} minutes")
    
  elif reason == "tool_timeout":
    print("⚠️  Tool execution stuck")
    print(f"   Tool: {stuck_info['tool']}")
    print(f"   Duration: {stuck_info['duration']}s")
    
    # Option 1: Kill and retry
    print("ℹ️   Options:")
    print("   1. Kill process and retry")
    print("   2. Skip this step")
    print("   3. Ask human for help")
```

---

## Reading OpenCode State Ralph Loop Integration

### Step-by-Step Progress Dashboard

```python
def get_ralph_loop_dashboard(session_id):
  parts = conn.cursor()
  
  # Get all parts in order
  parts.execute(
    f"""
    SELECT part.data, message.time_created
    FROM part
    JOIN message ON part.message_id = message.id
    WHERE message.session_id = ?
    ORDER BY message.time_created
    """",
    (session_id,)
  )
  
  dashboard = {
    "session_id": session_id,
    "stages": [],
    "tasks": {
      "completed": 0,
      "total": 0
    },
    "files": {
      "modified": [],
      "created": []
    },
    "git": {
      "commits": 0,
      "files_changed": []
    },
    "cost": {
      "tokens_in": 0,
      "tokens_out": 0,
      "total": 0.0,
      "breakdown": []
    },
    "time": {
      "elapsed": 0,
      "total_estimated": 0,
      "progress": 0.0
    }
  }
  
  for part_obj in parts:
    part = json.loads(part_obj[0])
    
    # Track messages (agent requests)
    if part["type"] == "message":
      dashboard["tasks"]["total"] += 1
      
      # Check for completions (promises)
      if "✓" in part.get("content", "") or "<promise>" in part:
        dashboard["tasks"]["completed"] += 1
        
      # Check for file operations
      if part.get("tool") == "write":
        dashboard["files"]["created"].append(part.get("source"))
      elif part.get("tool") == "edit":
        dashboard["files"]["modified"].append(part.get("source"))
        
      # Check for git commits
      if part.get("tool") == "bash" and "git commit" in part.get("command", ""):
        dashboard["git"]["commits"] += 1
        
    # Track costs
    if part.get("tokens_in"):
      dashboard["cost"]["tokens_in"] += part.get("tokens_in", 0)
    if part.get("tokens_out"):
      dashboard["cost"]["tokens_out"] += part.get("tokens_out", 0)
      
      # Calculate cost this iteration
      cost_in = part["tokens_in"] / 1000 * 0.003
      cost_out = part["tokens_out"] / 0.015
      dashboard["cost"]["breakdown"].append({
        "iteration": len(dashboard["cost"]["breakdown"]),
        "tokens_in": part["tokens_in"],
        "tokens_out": part["tokens_out"],
        "cost": cost_in + cost_out
      })
      
      dashboard["cost"]["total"] = sum(dashboard["cost"]["breakdown"])
  
  # Calculate time
  sessions = conn.execute(
    "SELECT time_compacting FROM session WHERE id = ?",
    (session_id,)
  ).fetchone()
  
  if sessions:
    start_time = sessions[0] or 0
    elapsed = time.time() - start_time
    dashboard["time"]["elapsed"] = elapsed
    
    # Progress (if estimated total is stored)
    estimated_parts = conn.execute(
      "SELECT total_steps FROM session WHERE id = ?",
      (session_id,)
    ).fetchone()
    
    if estimated_parts and estimated_parts[0]:
      dashboard["time"]["total"] = estimated_parts[0]
      dashboard["time"]["progress"] = (elapsed / estimated_parts[0]) * 100
  
  return dashboard
```

### Real-Time Updates

Using SSE or polling for live progress:

```bash
# Poll current session status
curl -s http://localhost:4096/sessions/current | jq

# Returns:
{
  "id": "session-abc123",
  "status": "running",
  "time_compacting": 450,  # seconds
  "iteration": 5,
  "messages_processed": 142,
  "total_tokens": 50000
}
```

```python
# Poll every 1 second
import requests
import json

def poll_dashboard(session_id):
  url = f"http://localhost:4096/sessions/{session_id}"
  
  while True:
    status = requests.get(url).json()
    
    print(f"⏱️  Iteration: {status['iteration']}")
    print(f"📊 Progress: {status['progress_percent']:.0f}%")
    print(f"💰 Cost: ${status['total_cost']:.2f}")
    print(f"⏱️  Time: {status['time_compacting']/60:.1f}min")
    
    time.sleep(1)
```

---

## Integrating Opencode with Ralph Loops

### Setup Scripts

**1. Progress Monitor**:
```bash
#!/bin/bash
# monitor_ralph.sh

SESSION_ID="$1"

echo "Ralph Loop Progress Monitor"
echo "========================"

# Get session status via opencode CLI or API
while true; do
  STATUS=$(opencode status | jq '.status')
  TIME=$(opencode status | jq '.time_compacting')
  ITER=$(opencode status | jq '.iteration')
  COST=$(opencode status | jq '.total_cost')
  
  clear
  echo "Ralph Loop Status"
  echo "================"
  echo "Status: $STATUS"
  echo "Iteration: $ITERATION"
  echo "Time: $TIME seconds"
  echo "Cost: \$$COST"
  echo ""
  echo "Press Ctrl+C to save and stop"
  
  sleep 1
done
```

**2. Cost Tracker**:
```bash
#!/bin/bash
# track_cost.sh

SESSION_ID="$1"

# Track cost per iteration
sqlite3 ~/.local/share/opencode/opencode/db <<SQL
SELECT 
  iteration,
  SUM(tokens_in),
  SUM(tokens_out),
  (SUM(tokens_in) / 1000 * 0.003) + (SUM(tokens_out) / 1000 * 0.015) as cost
FROM part
JOIN message ON part.message_id = message.id
WHERE message.session_id = '$SESSION_ID'
GROUP BY iteration
ORDER BY iteration;
SQL
```

**3. State Persistence**:
```bash
#!/bin/bash
# save_state.sh

SESSION_ID="$1"

# Get last successful message
LAST_MSG=$(sqlite3 ~/.local/share/opencode/opencode.db <<'SQL'
SELECT data FROM message
WHERE session_id = '$SESSION_ID'
ORDER BY time_created DESC
LIMIT 1
SQL
)

# Save current time and context
STATE=$(cat <<JSON
{
  "session_id": "$SESSION_ID",
  "timestamp": $(date +%s),
  "last_message": "$LAST_MSG",
  "current_directory": "$(pwd)",
  "git_branch": "$(git branch --show-current)",
  "git_count": "$(git rev-list --count)",
  "opencode_files": "$(ls ~/.local/share/opencode/tool-output/ | wc -l)"
}
JSON
)

# Write to state file
mkdir -p ~/.local/share/opencode/
echo "$STATE" > ~/.local/share/opencode/ralph-state.json

echo "✅ State saved to ~/.local/share/opencode/ralph-state.json"
```

**4. Resume Loop**:
```bash
#!/bin/bash
# resume.sh

STATE_FILE=~/.local/share/opencode/ralph-state.json

if [ ! -f "$STATE_FILE" ]; then
  echo "❌ No saved state found"
  exit 1
fi

echo "🔄 Resuming Ralph loop..."
echo ""

# Read state
SESSION_ID=$(jq -r '.session_id' "$STATE_FILE")
LAST_MESSAGE=$(jq -r '.last_message' "$STATE_FILE")
TIMESTAMP=$(jq -r '.timestamp' "$STATE_FILE")

echo "Restoring context state from $(date -r @$TIMESTAMP)"
echo "Last successful step: $LAST_MESSAGE"
echo ""

# Continue the session
opencode continue "$SESSION_ID"
```

---

## Implementation Checklist

For complete Ralph loop telemetry, implement:

### Progress Tracking
- [x] Database queries for session/message/part tables
- [x] Parse message JSON for stage detection
- [ ] Create progress bar (time vs estimated)
- [ ] Track task completion counts
- [ ] Track git commits
- [ ] Track file modifications
- [ ] Show iteration count

### Cost Tracking
- [x] Token-based cost calculation
- [x] Cumulative cost across iterations
- [x] Average cost per iteration
- [ ] Real-time rate monitoring
- [ ] Cost projection based on elapsed time
- [ ] Budget alerts (warn at thresholds)

### State Persistence
- [x] Save interrupt state on Ctrl+C
- [x] Graceful stop at next task
- [ ] Resume interrupted loops
- [ ] Restore context on resume
- [ ] Clean up state on completion

### Hotkeys/Controls
- [x] Ctrl+C: Pause and save
- [ ] Ctrl+D: Stop after current task
- [ ] Ctrl+R: Resume from checkpoint
- [ ] Esc: Emergency stop
- [ ] Implement TUI hotkey integration

### Tieout Features
- [ ] Detect cyclic errors
- [ ] Detect no progress
- [ ] Detect tool timeouts
- [ ] Ask human for intervention
- [ ] Suggest alternative strategies

### Dashboards
- [ ] TUI monitor (real-time progress)
- [ ] Web dashboard (browser-based)
- [ ] Cost breakdown view
- [ ] Session state viewer
- [ ] iteration statistics

---

## Best Practices

### 1. Always Update `time_compacting`

On every message/part processed, update session time:
```sql
UPDATE session 
SET time_updated = ?, time_compacting = time_compacting + ?
WHERE id = ?
```

This ensures accurate time tracking.

### 2. Always Token-Tag Each Message part

Track input/output tokens at every opportunity:
```json
{
  "tokens_in": 2345,
  "tokens_out": 8231,
  "model": "anthropic/claude-sonnet-4-20250514"
}
```

Without this, cost tracking is impossible.

###  progress Bars, Not Just Percentages

Users want to see:
- "Iteration 5 of 20 tasks" (progress count)
- "Building authentication system" (current stage)
- "3 of 10 files created" (file count)
- "$12.45 of $50.00 total cost" (dollars)

Use multi-dimensional progress.

### 4. Save State Before Any Critical Operation

Before:
- Starting new iteration
- Committing code
- Running risky tool

Checkpoints are cheap; losing context is expensive.

### 5. Tieout Before Infinite Loops

If agent executes same step 3+ times:
1. Detect it (message comparison)
2. Check for stuck state
3. Ask human or stop
4. Don't waste tokens on guaranteed failure

### 6. Budget Alerts as You Go

Don't wait until loop ends. Check cost periodically:
```bash
every 30 seconds:
  current_cost = get_total_cost(session_id)
  if current_cost > BUDGET:
    print "⚠️ Budget exceeded!"
    stop_loop()
```

### 7. Let Humans Intervene

Agent inbox pattern ensures humans can:
- See what went wrong
- Add guidance
- Approve or reject risky operations
- Prevent runaway costs

Don't try to automate everything - leave some judgment to the human.

---

## Summary

**Accessing Opencode State**:
- SQLite DB at `~/.local/share/opencode/opencode.db`
- Tables: session, message, part, project, todo
- Query via sqlite3 for logs and metadata

**Progress Elements to Track**:
- Ralph flows (stages, phases)
- Tasks (completed vs total)
- Git activity (commits, files changed)
- Time (elapsed vs estimated total)

**Cost Tracking**:
- Token counts from message parts
- Input/output cost model
- Cumulative cost across loop
- Real-time rate monitoring

**State Persistence**:
- Save on Ctrl+C (interrupt)
- Graceful stop at next boundary
- Resume from checkpoint
- Context restoration

**Tieout Detection**:
- Cyclic errors
- No progress detection
- Tool timeouts
- API rate limits
- Automatic intervention prompts

All this makes Ralph loops user-friendly and safe, not just powerful!
