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
- `memory-bank/` - Agent instructions
- `.ralph/` - Loop state and logs (auto-created)
README

chmod +x "$OUTPUT_DIR/ralph-loop.py"

echo "✓ Ralph loop created in $OUTPUT_DIR" >&2
echo "" >&2
echo "Quick start:" >&2
echo "  cd $OUTPUT_DIR" >&2
echo "  pip install -r requirements.txt" >&2
echo "  python ralph-loop.py loop" >&2
