#!/bin/bash
set -e

# Stepwise Testing Template Generator
# Creates templates for debugging and testing code step-by-step

echo "Stepwise Testing Template Generator" >&2
echo "=====================================" >&2

if [ $# -lt 2 ]; then
    echo "Usage: $0 <template-type> [language] [args...]" >&2
    echo "" >&2
    echo "Template types:" >&2
    echo "  debug-snippet  - Generate debug instrumentation snippet" >&2
    echo "  test-template  - Generate stepwise test file" >&2
    echo "  verify-scaffold - Generate verification scaffolding" >&2
    echo "  checklist     - Generate verification checklist" >&2
    echo "" >&2
    echo "Languages (for test-template): python, javascript" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 debug-snippet python" >&2
    echo "  $0 test-template python mymodule.py" >&2
    echo "  $0 checklist my-feature" >&2
    exit 1
fi

TEMPLATE_TYPE="$1"
LANGUAGE="${2:-python}"

case "$TEMPLATE_TYPE" in
    debug-snippet)
        generate_debug_snippet "$LANGUAGE"
        ;;
    test-template)
        if [ $# -lt 3 ]; then
            echo "Error: test-template requires input-file argument" >&2
            exit 1
        fi
        generate_test_template "$LANGUAGE" "$3"
        ;;
    verify-scaffold)
        generate_verify_scaffold "$LANGUAGE"
        ;;
    checklist)
        if [ $# -lt 3 ]; then
            echo "Error: checklist requires feature-name argument" >&2
            exit 1
        fi
        generate_checklist "$3"
        ;;
    *)
        echo "Error: Unknown template type: $TEMPLATE_TYPE" >&2
        exit 1
        ;;
esac

generate_debug_snippet() {
    local lang="$1"
    
    echo "# ===== Debug Instrumentation Template ($lang) =====" >&2
    echo "" >&2
    
    case "$lang" in
        python)
            cat <<'EOD'
# Stepwise debugging instrumentation
# Wrap this around any function you want to debug step-by-step

def stepwise_debug(func):
    """Decorator that adds entry/exit logging to a function"""
    def wrapper(*args, **kwargs):
        func_name = func.__name__
        print(f"[ENTER] {func_name}: args={args}, kwargs={kwargs}")
        try:
            result = func(*args, **kwargs)
            print(f"[EXIT] {func_name} -> {result}")
            return result
        except Exception as e:
            print(f"[ERROR] {func_name}: {e}")
            raise
    return wrapper

# Usage:
# @stepwise_debug
# def my_function(arg1, arg2):
#     print("[STEP] Processing arg1...")
#     # ... your code ...
#     print("[STEP] Processing arg2...")
#     # ... more code ...
#     return result

# For inline debugging:
print(f"[STATE] variable = {variable}")
print(f"[BRANCH] condition = {condition}, taking path {'if' if condition else 'else'}")
print(f"[LOOP] Iteration {i}/{total}: item={item}")
print(f"[STEP] About to call external_api()")
result = external_api()
print(f"[RESULT] external_api returned: {result}")
EOD
            ;;
        javascript)
            cat <<'EOD'
// Stepwise debugging instrumentation for JavaScript

function stepwiseDebug(func, funcName) {
    return function(...args) {
        console.log(`[ENTER] ${funcName}: args=${JSON.stringify(args)}`);
        try {
            const result = func.apply(this, args);
            console.log(`[EXIT] ${funcName} -> ${JSON.stringify(result)}`);
            return result;
        } catch (e) {
            console.log(`[ERROR] ${funcName}: ${e.message}`);
            throw e;
        }
    };
}

// Usage:
// function myFunction(arg1, arg2) {
//     console.log(`[STEP] Processing arg1...`);
//     // ... your code ...
//     console.log(`[STEP] Processing arg2...`);
//     // ... more code ...
//     return result;
// }
// myFunction = stepwiseDebug(myFunction, 'myFunction');

// For inline debugging:
console.log(`[STATE] variable = ${variable}`);
console.log(`[BRANCH] condition = ${condition}, taking path ${condition ? 'if' : 'else'}`);
console.log(`[LOOP] Iteration ${i}/${total}: item = ${JSON.stringify(item)}`);
EOD
            ;;
        *)
            echo "Error: Unsupported language: $lang" >&2
            exit 1
            ;;
    esac
}

generate_test_template() {
    local lang="$1"
    local input_file="$2"
    local module_name=$(basename "$input_file" | sed 's/\.[^.]*$//')
    
    echo "# Stepwise Test Template for $input_file" >&2
    echo "" >&2
    
    case "$lang" in
        python)
            cat <<EOD
#!/usr/bin/env python3
"""Stepwise tests for functions in $input_file

Test each function individually before testing the full workflow.
"""

import pytest
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

# import ${module_name}  # Add your import here


def test_function_1_valid_input():
    """Test: Function 1 with valid input
    
    Steps:
    1. Provide valid, complete input
    2. Verify function accepts it
    3. Check output structure
    """
    print("[TEST 1/3] Function 1 - Valid input")
    
    valid_input = {
        "key": "value",
        "number": 123
    }
    
    result = module_name.function_1(valid_input)
    
    assert result is not None, "Function should return something"
    assert "expected_key" in result, "Result should contain expected_key"
    
    print("    ✅ Valid input accepted")
    print("    ✅ Output structure correct")
    
    print("[PASS 1/3] Function 1 - Valid input")


def test_function_1_invalid_input():
    """Test: Function 1 with invalid input
    
    Steps:
    1. Provide missing required field
    2. Verify function rejects it or handles gracefully
    """
    print("[TEST 2/3] Function 1 - Invalid input")
    
    invalid_input = {
        # Missing required fields
    }
    
    try:
        result = module_name.function_1(invalid_input)
        # If no exception, check result indicates error
        assert result is None or "error" in str(result), "Should indicate invalid input"
        print("    ✅ Invalid input handled gracefully")
    except Exception as e:
        print(f"    ✅ Exception raised as expected: {type(e).__name__}")
    
    print("[PASS 2/3] Function 1 - Invalid input")


def test_function_2_transformation():
    """Test: Function 2 data transformation
    
    Steps:
    1. Provide known input
    2. Verify transformation rules applied
    3. Check output matches expected
    """
    print("[TEST 3/3] Function 2 - Transformation")
    
    known_input = {"value": "test"}
    result = module_name.function_2(known_input)
    
    assert result["transformed"] == "TEST TEST", "Should be upper case and repeated"
    assert "timestamp" in result, "Should add timestamp"
    
    print("    ✅ Transformation rules applied")
    print("    ✅ Additional fields added")
    
    print("[PASS 3/3] Function 2 - Transformation")
EOD
            ;;
        javascript)
            cat <<EOD
// Stepwise tests for $input_file

const assert = require('assert');
const $module_name = require('./$module_name');

describe('Stepwise Tests', () => {
    it('function 1 - Valid input', () => {
        console.log('[TEST 1/3] Function 1 - Valid input');
        
        const validInput = {
            key: 'value',
            number: 123
        };
        
        const result = module_name.function1(validInput);
        
        assert(result !== null, 'Function should return something');
        assert(result.hasOwnProperty('expectedKey'), 'Result should contain expectedKey');
        
        console.log('    ✅ Valid input accepted');
        console.log('    ✅ Output structure correct');
        
        console.log('[PASS 1/3] Function 1 - Valid input');
    });
    
    it('function 1 - Invalid input', () => {
        console.log('[TEST 2/3] Function 1 - Invalid input');
        
        const invalidInput = {
            // Missing required fields
        };
        
        try {
            const result = moduleName.function1(invalidInput);
            // If no exception, check result indicates error
            assert(result === null || result.hasOwnProperty('error'), 
                   'Should indicate invalid input');
            console.log('    ✅ Invalid input handled gracefully');
        } catch (e) {
            console.log('    ✅ Exception raised as expected: ' + e.name);
        }
        
        console.log('[PASS 2/3] Function 1 - Invalid input');
    });
    
    it('function 2 - Transformation', () => {
        console.log('[TEST 3/3] Function 2 - Transformation');
        
        const knownInput = { value: 'test' };
        const result = module_name.function2(knownInput);
        
        assert.strictEqual(result.transformed, 'TEST TEST', 
                          'Should be upper case and repeated');
        assert(result.hasOwnProperty('timestamp'), 
               'Should add timestamp');
        
        console.log('    ✅ Transformation rules applied');
        console.log('    ✅ Additional fields added');
        
        console.log('[PASS 3/3] Function 2 - Transformation');
    });
});
EOD
            ;;
        *)
            echo "Error: Unsupported language: $lang" >&2
            exit 1
            ;;
    esac
}

generate_verify_scaffold() {
    cat <<'EOD'
#!/usr/bin/env python3
"""Verification scaffolding for stepwise testing

Run this before and after each significant operation.
"""

from datetime import datetime

def verify_step(step_name, input_value, output_value=None, expected=None):
    """Verify a single step of processing
    
    Args:
        step_name: Name of the step being verified
        input_value: Value before operation
        output_value: Value after operation (optional)
        expected: Expected output (optional)
    """
    timestamp = datetime.now().isoformat()
    print(f"[VERIFY] {step_name} @ {timestamp}")
    print(f"    Input: {input_value}")
    
    if output_value is not None:
        print(f"    Output: {output_value}")
    
    if expected is not None:
        if output_value == expected:
            print(f"    ✅ Matches expected: {expected}")
        else:
            print(f"    ❌ Expected {expected}, got {output_value}")
            raise AssertionError(f"Verification failed: {step_name}")
    
    print(f"    ✅ {step_name} verified\n")
    return True


def verify_state(state_name, current_state, expected_state=None):
    """Verify system state
    
    Args:
        state_name: Name of state being verified
        current_state: Current state dictionary
        expected_state: Expected state dictionary (optional)
    """
    print(f"[STATE] {state_name}")
    print("    Current state:")
    for key, value in current_state.items():
        print(f"        {key}: {value}")
    
    if expected_state is not None:
        matches = True
        for key, expected_value in expected_state.items():
            if key not in current_state:
                print(f"    ❌ Missing key: {key}")
                matches = False
            elif current_state[key] != expected_value:
                print(f"    ❌ {key}: expected {expected_value}, got {current_state[key]}")
                matches = False
        
        if matches:
            print(f"    ✅ State matches expected")
        else:
            raise AssertionError(f"State verification failed: {state_name}")
    
    print()


def verify_function_call(func_name, args, kwargs, result=None):
    """Verify a function call
    
    Args:
        func_name: Name of function called
        args: Positional arguments
        kwargs: Keyword arguments
        result: Result from function (optional)
    """
    print(f"[CALL] {func_name}")
    print(f"    Args: {args}")
    print(f"    Kwargs: {kwargs}")
    
    if result is not None:
        print(f"    Result: {result}")
    
    print()


# Usage examples:

# verify_step(
#     step_name="validation",
#     input_value=user_input,
#     output_value=validated_result,
#     expected={"valid": True, "user_id": 123}
# )

# verify_state(
#     state_name="after_login",
#     current_state={"logged_in": True, "session": session_id},
#     expected_state={"logged_in": True, "permissions": ["read", "write"]}
# )

# verify_function_call(
#     func_name="process_payment",
#     args=[amount],
#     kwargs={"user_id": 123},
#     result=payment_status
# )
EOD
}

generate_checklist() {
    local feature_name="$1"
    
    cat <<EOD
# Stepwise Verification Checklist: $feature_name

## Function-Level Tests
- [ ] Test function 1 with valid input
  - [ ] All required fields present
  - [ ] Expected output structure returned
  - [ ] No exceptions raised
- [ ] Test function 1 with invalid input
  - [ ] Missing required field
  - [ ] Invalid data types
  - [ ] Boundary values
- [ ] Test function 1 error paths
  - [ ] External dependency failures
  - [ ] Resource exhaustion
  - [ ] Timeout scenarios

## State Transitions
- [ ] Verify state before operation X: ___
- [ ] Verify state after operation X: ___
- [ ] Verify state changed as expected: ___
- [ ] Verify side effects (files, DB, network): ___

## Data Flow
- [ ] Trace input through transformation pipeline
- [ ] Verify each transformation step
- [ ] Check intermediate values
- [ ] Confirm final output matches expectation

## Boundary Conditions
- [ ] Empty input
- [ ] Single item input
- [ ] Maximum size input
- [ ] Minimum values (-inf, 0, 1, etc.)
- [ ] Maximum values (MAX_INT, etc.)
- [ ] Null/None/undefined values

## Error Handling
- [ ] Invalid arguments rejected gracefully
- [ ] Resource errors caught and handled
- [ ] Timeout scenarios handled
- [ ] Retry logic implemented correctly
- [ ] Fallback behavior defined

## Third-Party Dependencies
- [ ] Library behavior verified (not assumed)
- [ ] API contracts validated
- [ ] Network calls tested for failures
- [ ] File I/O error scenarios tested

## Performance
- [ ] Verify response time < threshold: ___ ms
- [ ] Verify memory usage < threshold: ___ MB
- [ ] Verify no resource leaks
- [ ] Verify concurrent access handled

## Security (if applicable)
- [ ] Input validation
- [ ] Output sanitization
- [ ] Authentication/authorization verified
- [ ] Sensitive data protected

## Log output:
- [ ] Entry/exit logging in place
- [ ] State changes logged
- [ ] Error messages descriptive
- [ ] Debug output can be enabled/disabled

Last verified: ___
Verified by: ___
EOD
}
