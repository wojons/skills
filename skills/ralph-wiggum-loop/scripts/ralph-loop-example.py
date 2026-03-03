#!/usr/bin/env python3
"""
Meta Ralph Loop for Hivemind
Runs builder and verify loops alternately until all tasks complete.

This Python version provides:
- Better error handling and logging
- Extensible workflow engine
- State machine for complex transitions
- Plugin architecture for custom behaviors
- Metrics and monitoring hooks
"""

import argparse
import logging
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Callable, Tuple
import yaml


# Configuration
MAX_AGENT_TIME = 7200  # 2 hours
MAX_FAILED_ATTEMPTS = 3
SLEEP_BETWEEN_ITERATIONS = 2


# Paths
SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent
RALPH_DIR = PROJECT_ROOT / ".ralph"
MEMORY_BANK = PROJECT_ROOT / "memory-bank"
TODO_FILE = PROJECT_ROOT / "TODO.md"
LOOP_STATE = RALPH_DIR / "loop-state.yaml"
LOGS_DIR = RALPH_DIR / "logs"


# Ansi Colors
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'


@dataclass
class LoopState:
    """Current state of the Ralph loop."""
    iteration: int = 0
    phase: str = "idle"
    last_task: Optional[str] = None
    completed_tasks: List[str] = field(default_factory=list)
    failed_attempts: int = 0
    started_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    
    def to_dict(self) -> Dict:
        return {
            "iteration": self.iteration,
            "phase": self.phase,
            "last_task": self.last_task,
            "completed_tasks": self.completed_tasks,
            "failed_attempts": self.failed_attempts,
            "started_at": self.started_at
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> "LoopState":
        return cls(
            iteration=data.get("iteration", 0),
            phase=data.get("phase", "idle"),
            last_task=data.get("last_task"),
            completed_tasks=data.get("completed_tasks", []),
            failed_attempts=data.get("failed_attempts", 0),
            started_at=data.get("started_at", datetime.now(timezone.utc).isoformat())
        )


class RalphLogger:
    """Structured logging for the Ralph loop.
    
    Uses print() for console output with colors, and Python logging
    for structured file logging. Does not duplicate console output.
    """
    
    def __init__(self, name: str = "ralph"):
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.DEBUG)
        # Remove any existing handlers to avoid duplicates
        self.logger.handlers = []
        
        # File handler only - console output is handled by print()
        # File handler is added in the methods that need it
    
    def info(self, msg: str):
        print(f"{Colors.BLUE}[RALPH]{Colors.NC} {msg}")
        self.logger.info(msg)
    
    def success(self, msg: str):
        print(f"{Colors.GREEN}[RALPH]{Colors.NC} {msg}")
        self.logger.info(f"SUCCESS: {msg}")
    
    def warning(self, msg: str):
        print(f"{Colors.YELLOW}[RALPH]{Colors.NC} {msg}")
        self.logger.warning(msg)
    
    def error(self, msg: str):
        print(f"{Colors.RED}[RALPH]{Colors.NC} {msg}")
        self.logger.error(msg)
    
    def phase(self, msg: str):
        print(f"{Colors.CYAN}[RALPH]{Colors.NC} {msg}")
        self.logger.info(f"PHASE: {msg}")


class StateManager:
    """Manages loop state persistence."""
    
    def __init__(self, state_file: Path):
        self.state_file = state_file
        self.state = LoopState()
        self._load()
    
    def _load(self):
        """Load state from file."""
        if self.state_file.exists():
            try:
                with open(self.state_file, 'r') as f:
                    data = yaml.safe_load(f) or {}
                    self.state = LoopState.from_dict(data)
            except Exception as e:
                print(f"Warning: Could not load state: {e}")
                self.state = LoopState()
    
    def save(self):
        """Save state to file."""
        try:
            with open(self.state_file, 'w') as f:
                yaml.dump(self.state.to_dict(), f, default_flow_style=False)
        except Exception as e:
            print(f"Warning: Could not save state: {e}")
    
    def increment_iteration(self) -> int:
        """Increment iteration counter and return new value."""
        self.state.iteration += 1
        self.save()
        return self.state.iteration
    
    def set_phase(self, phase: str):
        """Set current phase."""
        self.state.phase = phase
        self.save()
    
    def record_failure(self) -> int:
        """Record a failure and return new count."""
        self.state.failed_attempts += 1
        self.save()
        return self.state.failed_attempts
    
    def reset_failures(self):
        """Reset failure counter."""
        self.state.failed_attempts = 0
        self.save()
    
    def reset(self):
        """Reset state to defaults."""
        self.state = LoopState()
        self.save()


class TaskManager:
    """Manages task tracking from TODO.md."""
    
    def __init__(self, todo_file: Path):
        self.todo_file = todo_file
    
    def has_pending_tasks(self) -> bool:
        """Check if there are incomplete tasks."""
        if not self.todo_file.exists():
            return False
        content = self.todo_file.read_text()
        return bool(re.search(r'^- \[ \]', content, re.MULTILINE))
    
    def count_pending(self) -> int:
        """Count number of pending tasks."""
        if not self.todo_file.exists():
            return 0
        content = self.todo_file.read_text()
        return len(re.findall(r'^- \[ \]', content, re.MULTILINE))
    
    def get_next_task(self) -> Optional[str]:
        """Get the next pending task description."""
        if not self.todo_file.exists():
            return None
        content = self.todo_file.read_text()
        match = re.search(r'^- \[ \] (.+)$', content, re.MULTILINE)
        return match.group(1) if match else None


class LogManager:
    """Manages log file operations."""
    
    def __init__(self, logs_dir: Path):
        self.logs_dir = logs_dir
        self.logs_dir.mkdir(parents=True, exist_ok=True)
    
    def get_log_file(self, phase: str) -> Path:
        """Generate unique log filename."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        return self.logs_dir / f"{phase}_{timestamp}.log"
    
    def list_logs(self, count: int = 10) -> List[Path]:
        """List recent log files."""
        if not self.logs_dir.exists():
            return []
        logs = sorted(
            [f for f in self.logs_dir.glob("*.log")],
            key=lambda x: x.stat().st_mtime,
            reverse=True
        )
        return logs[:count]
    
    def clean_old_logs(self, keep: int = 100):
        """Remove old logs, keeping only the most recent."""
        logs = self.list_logs(10000)  # Get all
        if len(logs) > keep:
            for log in logs[keep:]:
                log.unlink()


class PhaseRunner:
    """Runs individual phases (build, verify, plan)."""
    
    def __init__(
        self,
        logger: RalphLogger,
        log_manager: LogManager,
        max_agent_time: int = MAX_AGENT_TIME
    ):
        self.logger = logger
        self.log_manager = log_manager
        self.max_agent_time = max_agent_time
        self.last_output: str = ""  # Capture last OpenCode output for commit messages
    
    def run_opencode(
        self,
        prompt_file: Path,
        phase_name: str,
        working_dir: Path = PROJECT_ROOT,
        capture_output: bool = True
    ) -> Tuple[bool, str]:
        """Run OpenCode with a prompt file.
        
        Returns:
            Tuple of (success, output) where output is the captured OpenCode output
        """
        log_file = self.log_manager.get_log_file(phase_name)
        output_lines: List[str] = []
        
        self.logger.phase("═" * 60)
        self.logger.phase(f"Starting {phase_name} phase...")
        self.logger.phase(f"Log file: {log_file}")
        self.logger.phase("═" * 60)
        
        try:
            prompt_content = prompt_file.read_text()
            
            # Run with timeout
            with open(log_file, 'w') as log_fh:
                process = subprocess.Popen(
                    ["opencode", "run", prompt_content],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    cwd=working_dir,
                    text=True
                )
                
                # Stream output to both console and log file
                start_time = time.time()
                while True:
                    # Check timeout
                    if time.time() - start_time > self.max_agent_time:
                        process.kill()
                        self.logger.error(f"{phase_name} phase TIMED OUT after {self.max_agent_time // 3600} hours")
                        return False, ""
                    
                    # Read output
                    if process.stdout:
                        line = process.stdout.readline()
                        if not line and process.poll() is not None:
                            break
                        
                        if line:
                            print(line, end='')
                            log_fh.write(line)
                            log_fh.flush()
                            if capture_output:
                                output_lines.append(line.rstrip())
                    else:
                        if process.poll() is not None:
                            break
                        time.sleep(0.1)
                
                exit_code = process.wait()
                
                # Store captured output for commit messages
                self.last_output = "\n".join(output_lines)
                
                if exit_code == 0:
                    self.logger.success(f"{phase_name} phase completed")
                    self.logger.success(f"Log saved to: {log_file}")
                    return True, self.last_output
                else:
                    self.logger.error(f"{phase_name} phase failed with exit code {exit_code}")
                    self.logger.error(f"Log saved to: {log_file}")
                    return False, self.last_output
                    
        except FileNotFoundError:
            self.logger.error("OpenCode not found. Please install opencode.")
            return False, ""
        except Exception as e:
            self.logger.error(f"Error running {phase_name}: {e}")
            return False, ""
    
    def run_agent(
        self,
        agent: str,
        phase_name: str,
        working_dir: Path = PROJECT_ROOT,
        capture_output: bool = True
    ) -> Tuple[bool, str]:
        """Run OpenCode with an agent.
        
        Returns:
            Tuple of (success, output) where output is the captured OpenCode output
        """
        log_file = self.log_manager.get_log_file(phase_name)
        inbox_path = f"memory-bank/inbox/{agent}/"
        output_lines: List[str] = []
        
        self.logger.phase("═" * 60)
        self.logger.phase(f"Starting {phase_name} phase (agent: {agent})...")
        self.logger.phase(f"Log file: {log_file}")
        self.logger.phase("═" * 60)
        
        try:
            prompt = "Follow the instructions in your PROMPT.md. Execute the tasks it tells you to do."
            
            with open(log_file, 'w') as log_fh:
                process = subprocess.Popen(
                    ["opencode", "run", "--agent", agent, prompt],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    cwd=working_dir,
                    text=True
                )
                
                # Stream output
                start_time = time.time()
                while True:
                    if time.time() - start_time > self.max_agent_time:
                        process.kill()
                        self.logger.error(f"{phase_name} phase TIMED OUT")
                        return False, ""
                    
                    if process.stdout:
                        line = process.stdout.readline()
                        if not line and process.poll() is not None:
                            break
                        
                        if line:
                            print(line, end='')
                            log_fh.write(line)
                            log_fh.flush()
                            if capture_output:
                                output_lines.append(line.rstrip())
                    else:
                        if process.poll() is not None:
                            break
                        time.sleep(0.1)
                
                exit_code = process.wait()
                
                # Store captured output for commit messages
                self.last_output = "\n".join(output_lines)
                
                if exit_code == 0:
                    self.logger.success(f"{phase_name} phase completed")
                    self.logger.success(f"Log saved to: {log_file}")
                    return True, self.last_output
                else:
                    self.logger.error(f"{phase_name} phase failed")
                    return False, self.last_output
                    
        except FileNotFoundError:
            self.logger.error("OpenCode not found")
            return False, ""
        except Exception as e:
            self.logger.error(f"Error running {phase_name}: {e}")
            return False, ""
    
    def _extract_commit_message(self, output: str) -> str:
        """Extract last meaningful part of output for commit message.
        
        Look for the last non-empty, non-log line that appears to be
        a summary or conclusion from the agent.
        
        Args:
            output: Full OpenCode output
            
        Returns:
            Extracted commit message (max 500 chars)
        """
        lines = output.strip().split('\n')
        
        # Filter out empty lines and obvious log lines
        meaningful_lines = []
        for line in lines:
            line = line.strip()
            if not line:
                continue
            # Skip lines that look like logs
            if any(prefix in line.lower() for prefix in [
                'info:', 'debug:', 'warning:', 'error:', 'trace:',
                '[', 'running', 'starting', 'completed', 'finished',
                '│', '└', '├', '─', '│'
            ]):
                continue
            # Skip lines with just special characters
            if len(line) < 3:
                continue
            meaningful_lines.append(line)
        
        if not meaningful_lines:
            # Fallback: use last non-empty line
            return lines[-1] if lines else output
        
        # Get last meaningful line(s) - often the summary
        last_line = meaningful_lines[-1]
        
        # If it's very short, include a few lines before it for context
        if len(last_line) < 50 and len(meaningful_lines) > 1:
            context_lines = []
            # Take up to 3 lines before the last one
            for i in range(max(0, len(meaningful_lines) - 4), len(meaningful_lines)):
                context_lines.append(meaningful_lines[i])
            last_line = " | ".join(context_lines)
        
        # Limit to 500 characters max
        if len(last_line) > 500:
            last_line = last_line[:497] + "..."
        
        return last_line
    
    def commit_changes(self, message: str, working_dir: Path = PROJECT_ROOT) -> bool:
        """Commit changes with given message.
        
        Args:
            message: Commit message (will be truncated if too long)
            working_dir: Directory to commit in
            
        Returns:
            True if commit succeeded, False otherwise
        """
        if not message or message.strip() == "":
            self.logger.warning("No commit message provided, skipping commit")
            return False
        
        # Extract last meaningful part of output for commit message
        commit_msg = self._extract_commit_message(message)
        
        if not commit_msg or commit_msg.strip() == "":
            self.logger.warning("Could not extract meaningful commit message, skipping commit")
            return False
        
        try:
            # Stage all changes
            self.logger.info("Staging all changes...")
            result = subprocess.run(
                ["git", "add", "-A"],
                cwd=working_dir,
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                self.logger.warning(f"git add failed: {result.stderr}")
            
            # Check if there are changes to commit
            result = subprocess.run(
                ["git", "status", "--porcelain"],
                cwd=working_dir,
                capture_output=True,
                text=True
            )
            if not result.stdout.strip():
                self.logger.info("No changes to commit")
                return True
            
            # Commit with message
            self.logger.info(f"Committing with message: {commit_msg[:80]}...")
            result = subprocess.run(
                ["git", "commit", "-m", commit_msg],
                cwd=working_dir,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                self.logger.success(f"Committed: {result.stdout.strip()}")
                return True
            else:
                self.logger.error(f"Commit failed: {result.stderr}")
                return False
                
        except Exception as e:
            self.logger.error(f"Error during commit: {e}")
            return False
    
    def get_last_output(self) -> str:
        """Get the last captured OpenCode output."""
        return self.last_output


class WorkflowEngine:
    """
    Extensible workflow engine for complex Ralph loops.
    
    Supports:
    - Custom phase transitions
    - Conditional branching
    - Parallel execution (future)
    - Hooks for metrics/monitoring
    - Plugin architecture
    """
    
    def __init__(
        self,
        logger: RalphLogger,
        state_manager: StateManager,
        task_manager: TaskManager,
        log_manager: LogManager,
        phase_runner: PhaseRunner
    ):
        self.logger = logger
        self.state = state_manager
        self.tasks = task_manager
        self.logs = log_manager
        self.runner = phase_runner
        
        # Hooks for extensibility
        self.pre_phase_hooks: Dict[str, List[Callable]] = {}
        self.post_phase_hooks: Dict[str, List[Callable]] = {}
        self.on_failure_hooks: List[Callable] = []
        self.on_success_hooks: List[Callable] = []
    
    def register_pre_phase_hook(self, phase: str, hook: Callable):
        """Register a hook to run before a phase."""
        if phase not in self.pre_phase_hooks:
            self.pre_phase_hooks[phase] = []
        self.pre_phase_hooks[phase].append(hook)
    
    def register_post_phase_hook(self, phase: str, hook: Callable):
        """Register a hook to run after a phase."""
        if phase not in self.post_phase_hooks:
            self.post_phase_hooks[phase] = []
        self.post_phase_hooks[phase].append(hook)
    
    def register_failure_hook(self, hook: Callable):
        """Register a hook to run on any failure."""
        self.on_failure_hooks.append(hook)
    
    def register_success_hook(self, hook: Callable):
        """Register a hook to run on overall success."""
        self.on_success_hooks.append(hook)
    
    def _run_hooks(self, hooks: List[Callable], context: Dict[str, Any]):
        """Execute a list of hooks."""
        for hook in hooks:
            try:
                hook(context)
            except Exception as e:
                self.logger.warning(f"Hook failed: {e}")
    
    def run_phase(self, phase_name: str, method: str, *args, auto_commit: bool = False) -> bool:
        """
        Run a phase with hooks.
        
        Args:
            phase_name: Name of the phase (build, verify, plan)
            method: 'prompt' or 'agent'
            *args: Arguments for the phase runner
            auto_commit: If True, commit changes after successful run using OpenCode output
        """
        # Pre-phase hooks
        context: Dict[str, Any] = {"phase": phase_name, "method": method}
        if phase_name in self.pre_phase_hooks:
            self._run_hooks(self.pre_phase_hooks[phase_name], context)
        
        # Run phase
        self.state.set_phase(phase_name)
        
        output = ""
        if method == "prompt":
            success, output = self.runner.run_opencode(*args)
        elif method == "agent":
            success, output = self.runner.run_agent(*args)
        else:
            raise ValueError(f"Unknown method: {method}")
        
        # Auto-commit after successful phase if enabled
        if auto_commit and success and output:
            self.logger.info("Auto-committing changes with OpenCode output...")
            self.runner.commit_changes(output)
        
        # Post-phase hooks
        context["success"] = success
        context["output"] = output
        if phase_name in self.post_phase_hooks:
            self._run_hooks(self.post_phase_hooks[phase_name], context)
        
        return success
    
    def run_standard_loop(self, use_agents: bool = False, auto_commit: bool = False):
        """Run the standard build-verify loop.
        
        Args:
            use_agents: If True, use builder/verifier agents instead of prompts
            auto_commit: If True, auto-commit after each successful phase using OpenCode output
        """
        prompt_dir = RALPH_DIR
        
        while self.tasks.has_pending_tasks():
            iteration = self.state.increment_iteration()
            pending = self.tasks.count_pending()
            
            self.logger.info("═" * 60)
            self.logger.info(f"Iteration #{iteration} | Pending tasks: {pending}")
            self.logger.info("═" * 60)
            
            # Build phase
            if use_agents:
                success = self.run_phase("build", "agent", "builder", "build", auto_commit=auto_commit)
            else:
                success = self.run_phase(
                    "build",
                    "prompt",
                    prompt_dir / "PROMPT.md",
                    "build",
                    auto_commit=auto_commit
                )
            
            if not success:
                failures = self.state.record_failure()
                
                if failures >= MAX_FAILED_ATTEMPTS:
                    self.logger.error(f"Too many failures ({failures}). Stopping.")
                    self._run_hooks(self.on_failure_hooks, {"failures": failures})
                    return False
                
                self.logger.warning("Build failed, retrying...")
                continue
            
            # Verify phase
            if use_agents:
                success = self.run_phase("verify", "agent", "verifier", "verify", auto_commit=auto_commit)
            else:
                success = self.run_phase(
                    "verify",
                    "prompt",
                    prompt_dir / "PROMPT-VERIFY.md",
                    "verify",
                    auto_commit=auto_commit
                )
            
            if not success:
                self.logger.warning("Verification failed, fixes needed")
                self.state.reset_failures()
                continue
            
            self.state.reset_failures()
            time.sleep(SLEEP_BETWEEN_ITERATIONS)
        
        self.logger.success("All tasks complete!")
        self._run_hooks(self.on_success_hooks, {"completed_tasks": self.tasks.count_pending()})
        return True


class RalphCLI:
    """Command-line interface for the Ralph loop."""
    
    def __init__(self):
        self.logger = RalphLogger()
        self.state = StateManager(LOOP_STATE)
        self.tasks = TaskManager(TODO_FILE)
        self.logs = LogManager(LOGS_DIR)
        self.runner = PhaseRunner(self.logger, self.logs)
        self.engine = WorkflowEngine(
            self.logger, self.state, self.tasks, self.logs, self.runner
        )
        self.auto_commit = True  # Default to auto-committing after each phase
    
    def cmd_plan(self):
        """Run planning phase using planner agent."""
        self.logger.info("Running planning phase with planner agent...")
        self.engine.run_phase("plan", "agent", "planner", "plan", auto_commit=self.auto_commit)
    
    def cmd_build(self):
        """Run single build phase using builder agent."""
        self.logger.info("Running single build phase with builder agent...")
        self.engine.run_phase("build", "agent", "builder", "build", auto_commit=self.auto_commit)
    
    def cmd_verify(self):
        """Run single verify phase using verifier agent."""
        self.logger.info("Running single verify phase with verifier agent...")
        self.engine.run_phase("verify", "agent", "verifier", "verify", auto_commit=self.auto_commit)
    
    def cmd_loop(self):
        """Run full loop using builder and verifier agents."""
        self.logger.info("Starting agent-based Ralph loop...")
        if self.auto_commit:
            self.logger.info("Auto-commit enabled - will commit after each successful phase")
        self.engine.run_standard_loop(use_agents=True, auto_commit=self.auto_commit)
    
    def cmd_agent_loop(self):
        """Run full agent-based loop (alias for loop)."""
        self.logger.info("Starting agent-based Ralph loop...")
        if self.auto_commit:
            self.logger.info("Auto-commit enabled - will commit after each successful phase")
        self.engine.run_standard_loop(use_agents=True, auto_commit=self.auto_commit)
    
    def cmd_status(self):
        """Show current status."""
        self.logger.info("Loop status:")
        print(f"  Iteration: {self.state.state.iteration}")
        print(f"  Phase: {self.state.state.phase}")
        print(f"  Pending tasks: {self.tasks.count_pending()}")
        print(f"  Failed attempts: {self.state.state.failed_attempts}")
        print(f"  Started at: {self.state.state.started_at}")
        print("")
        self.cmd_logs(5)
    
    def cmd_logs(self, count: int = 20):
        """Show recent logs."""
        self.logger.info(f"Recent log files (last {count}):")
        logs = self.logs.list_logs(count)
        if logs:
            for log in logs:
                mtime = datetime.fromtimestamp(log.stat().st_mtime)
                print(f"  {log.name} ({mtime.strftime('%Y-%m-%d %H:%M:%S')})")
        else:
            print("  No logs found")
    
    def cmd_clean(self):
        """Clean old logs."""
        self.logger.info("Cleaning old logs (keeping last 100)...")
        self.logs.clean_old_logs(100)
        self.logger.success("Log cleanup complete")
    
    def cmd_reset(self):
        """Reset loop state."""
        self.state.reset()
        self.logger.success("Loop state reset")
    
    def cmd_commit(self, message: Optional[str] = None):
        """Commit changes with optional message or use last output."""
        if message:
            self.runner.commit_changes(message)
        elif self.runner.get_last_output():
            self.logger.info("Using last OpenCode output as commit message...")
            self.runner.commit_changes(self.runner.get_last_output())
        else:
            self.logger.error("No commit message or previous output available")
            self.logger.info("Run a build/verify phase first, or provide a message with -m")
            sys.exit(1)
    
    def run(self, args: Optional[List[str]] = None):
        """Main entry point."""
        parser = argparse.ArgumentParser(
            description="Meta Ralph Loop for Hivemind",
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog="""
Examples:
  python ralph_loop.py loop                    # Run full loop
  python ralph_loop.py loop --commit           # Run loop with auto-commit
  python ralph_loop.py build --commit          # Single build with commit
  python ralph_loop.py verify                  # Single verify phase
  python ralph_loop.py status                  # Show status
  python ralph_loop.py logs 10                 # Show last 10 logs
  python ralph_loop.py commit "Your message"   # Manual commit

Configuration:
  Max agent time: 2 hours
  Max failed attempts: 3
  Logs directory: .ralph/logs/
            """
        )
        
        parser.add_argument(
            "command",
            choices=["plan", "build", "verify", "loop", "agent-loop", 
                     "status", "logs", "clean", "reset", "commit"],
            nargs="?",
            default="loop",
            help="Command to run (default: loop)"
        )
        parser.add_argument(
            "count",
            type=int,
            nargs="?",
            default=20,
            help="Number of logs to show (for 'logs' command)"
        )
        parser.add_argument(
            "-c", "--commit",
            action="store_true",
            help="Auto-commit changes after successful OpenCode run using output as commit message"
        )
        parser.add_argument(
            "-m", "--message",
            type=str,
            help="Commit message (for 'commit' command)"
        )
        
        parsed = parser.parse_args(args)
        
        # Handle auto-commit flag
        self.auto_commit = parsed.commit
        
        # Ensure directories exist
        RALPH_DIR.mkdir(parents=True, exist_ok=True)
        LOGS_DIR.mkdir(parents=True, exist_ok=True)
        
        # Dispatch command
        commands = {
            "plan": self.cmd_plan,
            "build": self.cmd_build,
            "verify": self.cmd_verify,
            "loop": self.cmd_loop,
            "agent-loop": self.cmd_agent_loop,
            "status": self.cmd_status,
            "logs": lambda: self.cmd_logs(parsed.count),
            "clean": self.cmd_clean,
            "reset": self.cmd_reset,
            "commit": lambda: self.cmd_commit(parsed.message),
        }
        
        command_func = commands.get(parsed.command)
        if command_func:
            try:
                command_func()
            except KeyboardInterrupt:
                print("\n")
                self.logger.warning("Interrupted by user")
                sys.exit(130)
            except Exception as e:
                self.logger.error(f"Command failed: {e}")
                sys.exit(1)
        else:
            parser.print_help()
            sys.exit(1)


def main():
    """Entry point."""
    cli = RalphCLI()
    cli.run()


if __name__ == "__main__":
    main()
