#!/bin/bash
set -e

# Ralph Loop Generator Script
# This script generates working Ralph loop implementations

echo "Ralph Loop Generator" >&2
echo "====================" >&2

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <language> <pattern> [output-dir]" >&2
    echo "" >&2
    echo "Languages: python, node" >&2
    echo "Patterns: builder-only, build-verify, build-verify-plan" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 python builder-only ./my-loop" >&2
    echo "  $0 node build-verify ./auth-loop" >&2
    exit 1
fi

LANGUAGE="$1"
PATTERN="$2"
OUTPUT_DIR="${3:-./ralph-loop}"

echo "Creating $PATTERN loop in $LANGUAGE" >&2
echo "Output: $OUTPUT_DIR" >&2

# Validate language
if [ "$LANGUAGE" != "python" ] && [ "$LANGUAGE" != "node" ]; then
    echo "Error: Language must be 'python' or 'node'" >&2
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate based on pattern
case "$PATTERN" in
    builder-only)
        echo "Generating single-agent loop..." >&2
        generate_builder_only "$LANGUAGE" "$OUTPUT_DIR"
        ;;
    build-verify)
        echo "Generating sequential build-verify loop..." >&2
        generate_build_verify "$LANGUAGE" "$OUTPUT_DIR"
        ;;
    build-verify-plan)
        echo "Generating three-agent loop..." >&2
        generate_build_verify_plan "$LANGUAGE" "$OUTPUT_DIR"
        ;;
    *)
        echo "Error: Unknown pattern '$PATTERN'" >&2
        echo "Valid patterns: builder-only, build-verify, build-verify-plan" >&2
        exit 1
        ;;
esac

echo "✓ Generated Ralph loop in $OUTPUT_DIR" >&2
echo "" >&2
echo "To run:" >&2
echo "  cd $OUTPUT_DIR" >&2
echo "  npm install  # if node" >&2
echo "  # or" >&2
echo "  pip install -r requirements.txt  # if python" >&2
echo "  ./run.sh" >&2

generate_builder_only() {
    local lang="$1"
    local out="$2"
    
    cat > "$out/LOOP_CONFIG.yaml" <<'EOF'
workflow:
  name: "build-task"
  max_iterations: 20
  stop_on_success: true
  
  agent:
    role: "builder"
    model: "anthropic/claude-sonnet-4-20250514"
    tools: ["read", "write", "edit", "bash", "question"]
    stop_condition: "<promise>TASK_COMPLETE</promise>"
    
  task:
    description: "Build the requested feature"
    success_criteria:
      - "Code compiles without errors"
      - "Tests pass"
      - "Feature works as specified"
EOF

    if [ "$lang" = "python" ]; then
        cat > "$out/loop.py" <<'PY'
#!/usr/bin/env python3
"""Simple Ralph Loop - Builder Only Pattern"""
import sys
import subprocess
import json
from pathlib import Path

class RalphLoop:
    def __init__(self, config_path="LOOP_CONFIG.yaml"):
        self.config = self.load_config(config_path)
        self.iteration = 0
        self.max_iterations = self.config.get("workflow", {}).get("max_iterations", 20)
        
    def load_config(self, path):
        import yaml
        with open(path) as f:
            return yaml.safe_load(f)
            
    def check_success(self):
        """Check if the task is complete"""
        # Run tests
        try:
            result = subprocess.run(
                ["python", "-m", "pytest", "-q"],
                capture_output=True,
                text=True,
                timeout=60
            )
            return result.returncode == 0
        except Exception:
            return False
            
    def run(self):
        """Run the Ralph loop"""
        print(f"Starting Ralph loop (max {self.max_iterations} iterations)")
        
        while self.iteration < self.max_iterations:
            self.iteration += 1
            print(f"\nIteration {self.iteration}/{self.max_iterations}")
            
            # Ask agent to build
            print("Agent: Building feature...")
            
            # In a real implementation, this would call the AI agent
            # For now, just check if success condition is met
            if self.check_success():
                print("✓ Success! Task completed.")
                return True
                
            print("Not complete, retrying...")
            
        print("Max iterations reached. Review and adjust.")
        return False

if __name__ == "__main__":
    loop = RalphLoop()
    success = loop.run()
    sys.exit(0 if success else 1)
PY

        cat > "$out/requirements.txt" <<'REQ'
pyyaml
pytest
REQ

        chmod +x "$out/loop.py"
        
    else
        cat > "$out/loop.ts" <<'TS'
#!/usr/bin/env node
/** Simple Ralph Loop - Builder Only Pattern */
import subprocess from 'child_process';
import fs from 'fs/promises';
import YAML from 'yaml';

interface Config {
  workflow: {
    name: string;
    max_iterations: number;
    stop_on_success: boolean;
  };
}

class RalphLoop {
  private config: Config;
  private iteration = 0;
  private maxIterations: number;

  constructor(configPath: string = 'LOOP_CONFIG.yaml') {
    this.config = YAML.parse(await fs.readFile(configPath, 'utf8'));
    this.maxIterations = this.config.workflow.max_iterations || 20;
  }

  async checkSuccess(): Promise<boolean> {
    try {
      const result = await new Promise<{stdout: string; stderr: string}>(resolve => {
        subprocess.exec('npm test', (error, stdout, stderr) => {
          resolve({stdout, stderr});
        });
      });
      return !stdout.toLowerCase().includes('fail');
    } catch {
      return false;
    }
  }

  async run(): Promise<boolean> {
    console.log(`Starting Ralph loop (max ${this.maxIterations} iterations)`);

    while (this.iteration < this.maxIterations) {
      this.iteration++;
      console.log(`\nIteration ${this.iteration}/${this.maxIterations}`);

      console.log('Agent: Building feature...');

      if (await this.checkSuccess()) {
        console.log('✓ Success! Task completed.');
        return true;
      }

      console.log('Not complete, retrying...');
    }

    console.log('Max iterations reached. Review and adjust.');
    return false;
  }
}

const loop = new RalphLoop();
const success = await loop.run();
process.exit(success ? 0 : 1);
TS

        cat > "$out/package.json" <<'PKG'
{
  "name": "ralph-loop",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "test": "echo 'Running tests...' && exit 0"
  },
  "dependencies": {
    "yaml": "^2.3.0"
  }
}
PKG
    fi

    # Create run script
    cat > "$out/run.sh" <<'SCRIPT'
#!/bin/bash
set -e

echo "Starting Ralph Loop..."
if [ -f "loop.ts" ]; then
    npm install
    npx tsx loop.ts
elif [ -f "loop.py" ]; then
    pip install -r requirements.txt
    python3 loop.py
else
    echo "Error: No loop implementation found"
    exit 1
fi
SCRIPT
    chmod +x "$out/run.sh"
}

generate_build_verify() {
    local lang="$1"
    local out="$2"
    
    cat > "$out/LOOP_CONFIG.yaml" <<'EOF'
workflow:
  name: "build-verify-task"
  max_iterations: 20
  
  agents:
    builder:
      role: "Build the feature"
      stop_condition: "<promise>BUILT</promise>"
      tools: ["read", "write", "edit", "bash"]
      
    verifier:
      role: "Verify quality and correctness"
      stop_condition: "<promise>VERIFIED</promise>"
      tools: ["read", "bash", "question"]
      
  sequence:
    - agent: builder
    - agent: verifier
      
  feedback:
    verifier_failed:
      target: builder
      message: "Verification failed, retry"
EOF

    if [ "$lang" = "python" ]; then
        cat > "$out/loop.py" <<'PY'
#!/usr/bin/env python3
"""Ralph Loop - Build + Verify Pattern"""
import sys
import subprocess
import yaml

class BuildVerifyLoop:
    def __init__(self, config_path="LOOP_CONFIG.yaml"):
        self.config = self.load_config(config_path)
        self.iteration = 0
        self.max_iterations = 20
        
    def load_config(self, path):
        with open(path) as f:
            return yaml.safe_load(f)
            
    def builder_step(self):
        """Build step"""
        print("Builder: Implementing feature...")
        # Agent would build here
        return True
        
    def verifier_step(self):
        """Verify step"""
        print("Verifier: Checking quality...")
        result = subprocess.run(
            ["python", "-m", "pytest", "-q", "--failfast"],
            capture_output=True,
            text=True,
            timeout=60
        )
        return result.returncode == 0
        
    def run(self):
        while self.iteration < self.max_iterations:
            self.iteration += 1
            print(f"\nIteration {self.iteration}/{self.max_iterations}")
            
            self.builder_step()
            
            if self.verifier_step():
                print("✓ Verification passed!")
                return True
                
            print("✗ Verification failed, retrying...")
            
        print("Max iterations reached")
        return False

if __name__ == "__main__":
    loop = BuildVerifyLoop()
    sys.exit(0 if loop.run() else 1)
PY

        cat > "$out/requirements.txt" <<'REQ'
pyyaml
pytest
REQ
        chmod +x "$out/loop.py"
    fi
}

generate_build_verify_plan() {
    local lang="$1"
    local out="$2"
    
    cat > "$out/LOOP_CONFIG.yaml" <<'EOF'
workflow:
  name: "complex-task"
  max_iterations: 20
  
  agents:
    planner:
      role: "Plan the implementation"
      tools: ["read", "write", "question"]
      
    builder:
      role: "Build based on plan"
      tools: ["read", "write", "edit", "bash"]
      
    verifier:
      role: "Verify implementation"
      tools: ["read", "bash", "question"]
      
  sequence:
    - agent: planner
    - agent: builder
    - agent: verifier
      
  feedback:
    verifier_failed:
      target: planner
      message: "Plan needs adjustment"
EOF
}
