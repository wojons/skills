---
name: ralph-wiggum-loop
description: Build working Ralph loops - AI-driven development workflows that iterate until success
license: MIT
compatibility: opencode
metadata:
  audience: developers
  category: workflow
---

# Ralph Wiggum Skill

Generate working Ralph loops - AI-driven development workflows that iterate until tasks succeed.

## Quick Start

```bash
# Generate a working Ralph loop
bash scripts/generate-ralph-loop.sh ./my-loop

cd my-loop
pip install -r requirements.txt
python ralph-loop.py loop --commit
```

## What This Skill Provides

### 1. Working Loop Implementation
**File**: `scripts/ralph-loop-example.py`

A complete, production-ready Ralph loop implementation:

- **Auto-iteration**: Runs build/verify phases until all TODO.md tasks complete
- **Agent-based**: Uses builder/verifier/planner agents with PROMPT.md files
- **State persistence**: Tracks iterations, failures, phase progress
- **Auto-commit**: Commits changes after successful phases using OpenCode output
- **Logging**: Structured logs with timestamps and color-coded output
- **CLI interface**: Commands for loop, build, verify, plan, status, logs, reset, clean
- **Error handling**: Timeout detection, failure counting, graceful shutdown

### 2. Generator Script
**Script**: `scripts/generate-ralph-loop.sh`

Creates a ready-to-run Ralph loop from the example:

```bash
bash scripts/generate-ralph-loop.sh ./my-loop
```

Creates:
- `ralph-loop.py` - Executable loop implementation
- `requirements.txt` - Python dependencies (pyyaml)
- `README.md` - Basic usage docs

## How Ralph Loops Work

```
┌─────────────────────────────────────────┐
│         TODO.md tasks exist?           │
└─────────────────┬───────────────────────┘
                  │ Yes
                  ↓
┌───────────────────────────────────────────┐
│  Build Phase: Builder agent works          │
│  → Read PROMPT.md → Create code           │
│  → Success? → Commit with message         │
└─────────────┬─────────────────────────────┘
              │ No ↓
              ├───────────┐
              │           ↓
              │    ┌─────────────────┐
              │    │ Too many fails? │
              │    └────────┬────────┘
              │      Yes │   │ No
              │         ↓   ↓
              │      Stop  └───────────┐
              │                       ↓
              ↓         Verify Phase: Verifier agent
         ┌─────────┐  → Read PROMPT-VERIFY.md → Run tests
         │  Retry  │  → Success? → Continue
         │  (max   │  └─────────┬──────────────────┐
         │  20x)   │            ↓ Yes  ↓ No        │
         └─────────┘       Complete?    Retry      │
                            ↓          (max 3x)     ↓
                          Done!                 └───┘
```

## Generated Loop Commands

```bash
# Run full loop (build → verify → repeat until tasks complete)
python ralph-loop.py loop

# Auto-commit after each successful phase
python ralph-loop.py loop --commit

# Run single phases
python ralph-loop.py build    # Builder agent
python ralph-loop.py verify   # Verifier agent
python ralph-loop.py plan     # Planner agent

# Check status and logs
python ralph-loop.py status   # Show iteration, phase, pending tasks
python ralph-loop.py logs 10  # Show last 10 logs
python ralph-loop.py clean    # Clean old logs

# Reset loop state
python ralph-loop.py reset

# Manual commit with last output
python ralph-loop.py commit
```

## Required Project Structure

For the generated loop to work, your project needs:

```
project/
├── TODO.md                    # Tasks with - [ ] format
├── PROMPT-BUILDER.md          # Builder agent instructions
├── PROMPT-VERIFIER.md         # Verifier agent instructions
├── PROMPT-PLANNER.md          # Planner agent instructions
├── SPEC.md                    # Project specification
├── AGENTS.md                  # Project conventions & context
└── .ralph/
    ├── loop-state.yaml        # Auto-generated state
    └── logs/                  # Auto-generated logs
```

**PROMPT files at root level** - These are specialized agent instructions that explain the Ralph Loop workflow, system architecture, and how agents should collaborate. They include mermaid charts, decision trees, and detailed workflows.

## Implementation Features

The working loop includes:

### State Management
- Tracks iteration count, current phase, failed attempts
- Persists to YAML across runs
- Resume capability after interruption

### Task Tracking
- Reads TODO.md for `- [ ]` pending tasks
- Counts and displays pending work
- Stops when all tasks complete

### Agent Integration
- Runs `opencode run --agent <agent>` via subprocess
- Captures output for auto-commit messages
- Streams output to console and log files
- Timeout protection (2 hours default)

### Auto-Commit
- Extracts meaningful commit messages from OpenCode output
- Filters out logs and noise
- Commits after each successful phase when `--commit` flag used

### Logging
- Color-coded console output
- Timestamped log files per phase
- Structured Python logging
- Old log cleanup (keeps last 100)

### CLI
- Full argparse interface with help
- Commands for all operations
- Status reporting

## Configuration

Edit top of `ralph-loop.py`:

```python
MAX_AGENT_TIME = 7200      # 2 hours per phase
MAX_FAILED_ATTEMPTS = 3    # Stop after consecutive failures
SLEEP_BETWEEN_ITERATIONS = 2  # Seconds
```

## Specialized Agent Prompts

The skill includes **three specialized PROMPT.md files** at the project root:

### PROMPT-BUILDER.md
**Role:** Implementation agent focused on building code
- **Mermaid charts:** Shows the build workflow and decision trees
- **Lifecycle phases:** Discovery → Planning → Implementation → Completion
- **Standards:** Code quality, testing requirements, TODO update rules
- **Edge cases:** What to do when stuck, when to stop, how to communicate
- **Output format:** Structured completion reports

### PROMPT-VERIFIER.md
**Role:** Quality assurance agent focused on validation
- **Mermaid charts:** Multi-layer verification flow
- **5 verification layers:** Functional tests → Code review → Spec compliance → Edge cases → Integration
- **Failure patterns:** Common issues to catch and how to document them
- **Report formats:** Detailed PASS/FAIL reports with evidence
- **Standards:** What "production ready" means

### PROMPT-PLANNER.md
**Role:** Diagnostic and strategic planning agent
- **Mermaid charts:** When planner is called and solution design flow
- **Root cause analysis:** Framework for understanding why loops fail
- **Solution patterns:** 5 common patterns (clarify, restructure, fix context, strategic)
- **Decision framework:** When to split vs clarify, when to reorder, when to update spec
- **Output format:** Investigation reports with specific TODO updates

**Each prompt is 200+ lines** with:
- Visual workflow diagrams
- Decision trees
- Checklists and templates
- Common scenarios
- Output formats
- Critical rules (DO/DON'T)

## Notes

- The generated loop **actually works** - not just documentation
- Integrates directly with OpenCode CLI for agent execution
- Uses subprocess to run OpenCode with full output capture
- State persists across runs (resume capability)
- Logs everything for debugging and inspection
- Auto-commits using actual OpenCode output for meaningful messages
