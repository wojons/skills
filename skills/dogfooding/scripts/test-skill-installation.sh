#!/bin/bash
set -e

echo "Dogfooding: Skill Installation Testing" >&2
echo "=======================================" >&2

usage() {
    echo "Usage: $0 [OPTIONS]" >&2
    echo "Options:" >&2
    echo "  --skill NAME          Specific skill to test (required)" >&2
    echo "  --dry-run             Test installation without actually installing" >&2
    echo "  --verbose             Enable verbose output" >&2
    echo "  --help                Show this help message" >&2
    exit 1
}

SKILL=""
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skill)
            SKILL="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Error: Unknown option $1" >&2
            usage
            ;;
    esac
done

if [ -z "$SKILL" ]; then
    echo "Error: --skill option is required" >&2
    usage
fi

echo "Testing skill installation: $SKILL" >&2
echo "Mode: $([ "$DRY_RUN" = true ] && echo "dry-run" || echo "actual installation")" >&2
echo "" >&2

# Check if skill directory exists
SKILL_DIR="skills/$SKILL"
if [ ! -d "$SKILL_DIR" ]; then
    echo "❌ Error: Skill directory '$SKILL_DIR' does not exist" >&2
    exit 1
fi

# Check if SKILL.md exists
if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
    echo "❌ Error: SKILL.md not found in skill directory" >&2
    exit 1
fi

# Validate skill structure using existing validation script
if [ -f "scripts/validate-skill.sh" ]; then
    echo "Validating skill structure using scripts/validate-skill.sh..." >&2
    if bash scripts/validate-skill.sh "$SKILL_DIR" 2>/dev/null; then
        echo "✅ Skill structure validation passed" >&2
        STRUCTURE_VALID=true
    else
        echo "❌ Skill structure validation failed" >&2
        STRUCTURE_VALID=false
    fi
else
    echo "⚠️  scripts/validate-skill.sh not found, skipping structure validation" >&2
    STRUCTURE_VALID=true
fi

# Check if skills CLI is available
echo "Checking skills CLI availability..." >&2
if command -v npx > /dev/null 2>&1; then
    echo "✅ npx is available" >&2
    
    # Test with --list flag first (safe, doesn't install)
    echo "Testing skill listing with skills CLI..." >&2
    if npx skills add . --skill "$SKILL" --list 2>&1 | grep -q "$SKILL"; then
        echo "✅ Skill '$SKILL' appears in skills CLI listing" >&2
        LIST_VALID=true
    else
        echo "❌ Skill '$SKILL' not found in skills CLI listing" >&2
        LIST_VALID=false
        
        # Show CLI output for debugging
        if [ "$VERBOSE" = true ]; then
            echo "Skills CLI output:" >&2
            npx skills add . --skill "$SKILL" --list 2>&1 | head -20 >&2
        fi
    fi
    
    # If not dry-run, attempt actual installation
    if [ "$DRY_RUN" = false ]; then
        echo "Attempting actual installation..." >&2
        INSTALL_OUTPUT=$(npx skills add . --skill "$SKILL" --yes 2>&1)
        INSTALL_EXIT_CODE=$?
        
        if [ $INSTALL_EXIT_CODE -eq 0 ]; then
            echo "✅ Skill installation successful" >&2
            INSTALL_VALID=true
        else
            echo "❌ Skill installation failed with exit code $INSTALL_EXIT_CODE" >&2
            echo "Installation output:" >&2
            echo "$INSTALL_OUTPUT" | head -30 >&2
            INSTALL_VALID=false
        fi
    else
        echo "Skipping actual installation (dry-run mode)" >&2
        INSTALL_VALID=true
    fi
else
    echo "❌ npx not available, cannot test skills CLI" >&2
    LIST_VALID=false
    INSTALL_VALID=false
fi

# Test script execution if scripts exist
SCRIPT_EXECUTION_VALID=true
if [ -d "$SKILL_DIR/scripts" ]; then
    echo "Checking skill scripts..." >&2
    SCRIPT_COUNT=0
    EXECUTABLE_COUNT=0
    
    for script in "$SKILL_DIR/scripts"/*.sh; do
        if [ -f "$script" ]; then
            ((SCRIPT_COUNT++))
            if [ -x "$script" ]; then
                ((EXECUTABLE_COUNT++))
                
                # Test script with --help or dry-run if available
                if [ "$VERBOSE" = true ]; then
                    echo "  Testing script: $(basename "$script")" >&2
                    if head -5 "$script" | grep -q "set -e"; then
                        echo "    Has 'set -e' for error handling ✓" >&2
                    fi
                fi
            else
                echo "  ⚠️  Script not executable: $(basename "$script")" >&2
                SCRIPT_EXECUTION_VALID=false
            fi
            fi
    done
    
    echo "Found $SCRIPT_COUNT scripts, $EXECUTABLE_COUNT executable" >&2
    if [ $SCRIPT_COUNT -eq 0 ]; then
        echo "⚠️  No scripts found in skill (some skills may not need scripts)" >&2
    fi
fi

# Generate validation summary
echo "" >&2
echo "Skill Installation Test Summary" >&2
echo "───────────────────────────────" >&2
echo "Skill: $SKILL" >&2
echo "Structure Validation: $([ "$STRUCTURE_VALID" = true ] && echo "✅ PASS" || echo "❌ FAIL")" >&2
echo "CLI Listing: $([ "$LIST_VALID" = true ] && echo "✅ PASS" || echo "❌ FAIL")" >&2
echo "Installation: $([ "$INSTALL_VALID" = true ] && echo "✅ PASS" || echo "❌ FAIL")" >&2
echo "Script Execution: $([ "$SCRIPT_EXECUTION_VALID" = true ] && echo "✅ PASS" || echo "❌ FAIL")" >&2

# Calculate overall status
FAIL_COUNT=0
[ "$STRUCTURE_VALID" = false ] && ((FAIL_COUNT++))
[ "$LIST_VALID" = false ] && ((FAIL_COUNT++))
[ "$INSTALL_VALID" = false ] && ((FAIL_COUNT++))
[ "$SCRIPT_EXECUTION_VALID" = false ] && ((FAIL_COUNT++))

if [ $FAIL_COUNT -eq 0 ]; then
    echo "Overall Status: ✅ ALL TESTS PASSED" >&2
    exit 0
else
    echo "Overall Status: ❌ $FAIL_COUNT test(s) failed" >&2
    exit 1
fi