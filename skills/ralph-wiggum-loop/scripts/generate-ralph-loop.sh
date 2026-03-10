#!/bin/bash
set -e

# Ralph Loop Generator
# Creates a working Ralph loop from the example template

echo "Ralph Loop Generator" >&2
echo "====================" >&2

OUTPUT_DIR="${1:-./ralph-loop}"

if [ -d "$OUTPUT_DIR" ] && [ "$#" -eq 0 ]; then
    echo "Error: Directory '$OUTPUT_DIR' already exists" >&2
    echo "Usage: $0 [output-directory]" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Copy the working example
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/ralph-loop-example.py" "$OUTPUT_DIR/ralph-loop.py"

# Copy specialized agent prompts
cp "$SCRIPT_DIR/../PROMPT-BUILDER.md" "$OUTPUT_DIR/PROMPT-BUILDER.md" 2>/dev/null || echo "Warning: PROMPT-BUILDER.md not found in skill directory"
cp "$SCRIPT_DIR/../PROMPT-VERIFIER.md" "$OUTPUT_DIR/PROMPT-VERIFIER.md" 2>/dev/null || echo "Warning: PROMPT-VERIFIER.md not found in skill directory"
cp "$SCRIPT_DIR/../PROMPT-PLANNER.md" "$OUTPUT_DIR/PROMPT-PLANNER.md" 2>/dev/null || echo "Warning: PROMPT-PLANNER.md not found in skill directory"

# Create requirements.txt
cat > "$OUTPUT_DIR/requirements.txt" <<'REQ'
pyyaml
REQ

# Create basic docs
cat > "$OUTPUT_DIR/README.md" <<'README'
# Ralph Loop

Iterative build-verify workflow using OpenCode agents.

## Usage

```bash
# Install dependencies
pip install -r requirements.txt

# Run full loop (build → verify until all tasks complete)
python ralph-loop.py loop

# Run single phases
python ralph-loop.py build    # Build phase
python ralph-loop.py verify   # Verify phase
python ralph-loop.py plan     # Planning phase

# Auto-commit after successful phases
python ralph-loop.py loop --commit

# Check status
python ralph-loop.py status

# View logs
python ralph-loop.py logs

# Reset state
python ralph-loop.py reset

# Clean old logs
python ralph-loop.py clean
```

## How It Works

The loop alternates between build and verify phases:

1. **Build phase**: Builder agent creates/implements features
2. **Verify phase**: Verifier agent tests and validates
3. **Repeat** until all TODO.md tasks are complete
4. **Auto-commits** each successful phase using OpenCode output

## Configuration

Edit at top of `ralph-loop.py`:
```python
MAX_AGENT_TIME = 7200  # 2 hours per phase
MAX_FAILED_ATTEMPTS = 3  # Stop after consecutive failures
```

## Required Files

- `TODO.md` - Tasks to complete (uses `- [ ]` format)
- `PROMPT-BUILDER.md` - Specialized builder agent instructions (copied from skill)
- `PROMPT-VERIFIER.md` - Specialized verifier agent instructions (copied from skill)
- `PROMPT-PLANNER.md` - Specialized planner agent instructions (copied from skill)
- `SPEC.md` - Project specification (create this)
- `AGENTS.md` - Project conventions and context (create this)
- `.ralph/` - Loop state and logs (auto-created)

## Agent Specialization

Each PROMPT-*.md file contains:
- **Mermaid charts** - Visual workflow diagrams
- **Decision trees** - When and how to make decisions
- **Detailed workflows** - Step-by-step processes with phases
- **Common scenarios** - What to do in specific situations
- **Output formats** - How to report completion/failure
- **Critical rules** - DO and DON'T lists

These are **specialized agents**, not generic assistants. Builder focuses on implementation. Verifier focuses on quality. Planner focuses on strategy.
README

chmod +x "$OUTPUT_DIR/ralph-loop.py"

echo "✓ Ralph loop created in $OUTPUT_DIR" >&2
echo "" >&2
echo "Quick start:" >&2
echo "  cd $OUTPUT_DIR" >&2
echo "  pip install -r requirements.txt" >&2
echo "  python ralph-loop.py loop" >&2
