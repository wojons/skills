#!/bin/bash
set -e

# setup-ralph-project.sh
# Scaffold a new project with the Ralph loop structure:
#   - TODO.md with example baby-step items
#   - SPEC.md placeholder
#   - AGENTS.md placeholder
#   - memory-bank/inbox/{builder,verifier,planner}/PROMPT.md
#   - ralph-loop.py (copied from ralph-wiggum-loop skill if available)
#
# Usage: bash setup-ralph-project.sh <project-dir>

PROJECT_DIR="${1:-}"

if [ -z "$PROJECT_DIR" ]; then
    echo "Usage: $0 <project-directory>" >&2
    exit 1
fi

if [ -d "$PROJECT_DIR" ]; then
    echo "Error: Directory already exists: $PROJECT_DIR" >&2
    echo "Choose a new directory name or remove the existing one." >&2
    exit 1
fi

echo "Setting up Ralph loop project in $PROJECT_DIR/" >&2
mkdir -p "$PROJECT_DIR"
mkdir -p "$PROJECT_DIR/memory-bank/inbox/builder"
mkdir -p "$PROJECT_DIR/memory-bank/inbox/verifier"
mkdir -p "$PROJECT_DIR/memory-bank/inbox/planner"
mkdir -p "$PROJECT_DIR/.ralph/logs"

# --- TODO.md ---
cat > "$PROJECT_DIR/TODO.md" << 'EOF'
# TODO

Tasks for the build agent. Each item must be completable without human input.
Mark complete with [x] when done. The loop stops when all items are checked.

## Pending

- [ ] REPLACE THIS: Implement <specific thing> per SPEC.md section <X>.
  Create <file> with <function>(args) that does <exact behavior>.
  Success: all tests in <test-file> pass. No other files changed.

- [ ] REPLACE THIS: Add <feature> to <component> per SPEC.md section <Y>.
  Input: <type>. Output: <type>. Edge cases: <list>.
  Success: <test> passes and <validation> returns no errors.

## Notes for the build agent

- Read SPEC.md before starting any task.
- Read AGENTS.md for project conventions and file structure.
- Do not mark a task complete unless the success condition is fully met.
- If a task is ambiguous or blocked, update this file with a note and stop.
EOF
echo "  Created TODO.md" >&2

# --- SPEC.md ---
cat > "$PROJECT_DIR/SPEC.md" << 'EOF'
# Project Specification

Replace this file with your exhaustive project specification.

## Project Overview

## Goals and Non-Goals

## Users and Use Cases

## Architecture

## Data Model

## API Design

## Error Handling

## Configuration

## Deployment

## Open Questions
EOF
echo "  Created SPEC.md" >&2

# --- AGENTS.md ---
cat > "$PROJECT_DIR/AGENTS.md" << 'EOF'
# AGENTS.md

Context for AI agents working on this project.

## Project Goal

<Replace with one paragraph summary>

## Tech Stack

- Language:
- Framework:
- Database:
- Testing:

## File Structure

```
project/
├── src/
├── tests/
├── TODO.md
├── SPEC.md
└── AGENTS.md
```

## Conventions

- <coding style>
- <naming conventions>
- <test requirements>

## How to Run

```bash
# Install dependencies
<command>

# Run tests
<command>

# Start server
<command>
```

## How to Verify

A task is complete when:
1. All tests pass
2. <other condition>
3. <other condition>
EOF
echo "  Created AGENTS.md" >&2

# --- Builder PROMPT.md ---
cat > "$PROJECT_DIR/memory-bank/inbox/builder/PROMPT.md" << 'EOF'
# Builder Agent

You are the builder. Your job is to implement tasks from TODO.md.

## Before you start

1. Read SPEC.md completely.
2. Read AGENTS.md for project conventions.
3. Read TODO.md and identify the next unchecked task.

## For each task

1. Read the task carefully. Note the success condition.
2. Implement only what the task describes. Do not add extra features.
3. Write or update tests as specified.
4. Run the tests. Fix failures before marking the task done.
5. Mark the task complete with [x] in TODO.md.
6. Stop after completing one task.

## If you are stuck

- Do not guess. Read the relevant SPEC.md section again.
- If the spec is unclear, add a note to TODO.md describing what is missing.
- Do not mark a task complete if the success condition is not fully met.

## Output

When done, report:
- Which task you completed
- What files you changed
- Test results
EOF
echo "  Created memory-bank/inbox/builder/PROMPT.md" >&2

# --- Verifier PROMPT.md ---
cat > "$PROJECT_DIR/memory-bank/inbox/verifier/PROMPT.md" << 'EOF'
# Verifier Agent

You are the verifier. Your job is to confirm that completed work meets requirements.

## Before you start

1. Read SPEC.md to understand requirements.
2. Read AGENTS.md for how to run tests and what done looks like.
3. Read TODO.md to see what was just completed.

## For each verification

1. Run all tests. Report pass/fail counts.
2. Check that the completed task's success condition is fully met.
3. Check for regressions: does anything that was passing now fail?
4. Review the changed files for obvious issues (hardcoded values, missing error handling, etc.).

## If verification fails

- Add a note to TODO.md describing what failed and why.
- Do not mark any task complete.
- The builder will pick up on the next iteration.

## Output

Report:
- Test results (pass/fail/error counts)
- Whether the success condition was met
- Any regressions found
- Verdict: PASS or FAIL
EOF
echo "  Created memory-bank/inbox/verifier/PROMPT.md" >&2

# --- Planner PROMPT.md ---
cat > "$PROJECT_DIR/memory-bank/inbox/planner/PROMPT.md" << 'EOF'
# Planner Agent

You are the planner. You are called when the builder is stuck or the loop is stalled.

## Before you start

1. Read SPEC.md and AGENTS.md.
2. Read TODO.md carefully, including any notes left by the builder or verifier.
3. Check .ralph/loop-state.yaml for iteration count and failure history.

## Your job

1. Identify why the loop stalled (ambiguous task, missing context, wrong order).
2. Rewrite the blocked TODO item to be clearer and more specific.
3. If a task depends on something not yet done, reorder the list.
4. If the spec is missing information the builder needs, add a SPEC NOTE to the TODO item.

## What you must not do

- Do not implement code.
- Do not mark tasks complete.
- Do not remove tasks — only clarify or reorder them.

## Output

Report:
- What you identified as the cause of the stall
- What you changed in TODO.md
- What the builder should do next
EOF
echo "  Created memory-bank/inbox/planner/PROMPT.md" >&2

# --- Try to copy ralph-loop.py from skill if available ---
SKILL_LOOP=""
# Check common skill locations
for candidate in \
    "$(dirname "$0")/../../ralph-wiggum-loop/scripts/ralph-loop-example.py" \
    "$HOME/.agents/skills/ralph-wiggum-loop/scripts/ralph-loop-example.py" \
    "$HOME/.opencode/skills/ralph-wiggum-loop/scripts/ralph-loop-example.py"; do
    if [ -f "$candidate" ]; then
        SKILL_LOOP="$candidate"
        break
    fi
done

if [ -n "$SKILL_LOOP" ]; then
    cp "$SKILL_LOOP" "$PROJECT_DIR/ralph-loop.py"
    chmod +x "$PROJECT_DIR/ralph-loop.py"
    echo "  Copied ralph-loop.py from $SKILL_LOOP" >&2
else
    cat > "$PROJECT_DIR/ralph-loop.py" << 'EOF'
#!/usr/bin/env python3
"""
Ralph loop placeholder.
Install the ralph-wiggum-loop skill to get the full implementation:
  npx skills add <owner>/skills --skill ralph-wiggum-loop

Then copy the example:
  cp ~/.agents/skills/ralph-wiggum-loop/scripts/ralph-loop-example.py ralph-loop.py
"""
print("Ralph loop not installed. See ralph-wiggum-loop skill.")
EOF
    echo "  Created ralph-loop.py placeholder (install ralph-wiggum-loop for full version)" >&2
fi

echo "" >&2
echo "Project scaffold created in $PROJECT_DIR/" >&2
echo "" >&2
echo "Next steps:" >&2
echo "  1. Fill in SPEC.md with your exhaustive project specification" >&2
echo "  2. Update AGENTS.md with your tech stack and conventions" >&2
echo "  3. Write baby-step TODO items with clear success conditions" >&2
echo "  4. Review all PROMPT.md files for your specific project" >&2
echo "  5. Run: python ralph-loop.py loop --commit" >&2

echo "{\"status\": \"success\", \"project\": \"$PROJECT_DIR\"}"
