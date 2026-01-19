#!/bin/bash
#
# validate-playbook-schema-test.sh
# Test suite for validate-playbook-schema.sh
#

set -euo pipefail

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly VALIDATOR="${PROJECT_ROOT}/scripts/validate-playbook-schema.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# -----------------------------------------------------------------------------
# Test Helpers
# -----------------------------------------------------------------------------

run_test() {
    local test_name="$1"
    local json_input="$2"
    local expect_error="$3"  # true or false
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    local result
    local exit_code=0
    result=$(echo "$json_input" | "$VALIDATOR" --stdin 2>&1) || exit_code=$?
    
    local has_error=false
    if [ $exit_code -ne 0 ] || echo "$result" | grep -q "ERROR:"; then
        has_error=true
    fi
    
    if [ "$expect_error" = "true" ] && [ "$has_error" = "true" ]; then
        echo "[PASS] $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    elif [ "$expect_error" = "false" ] && [ "$has_error" = "false" ]; then
        echo "[PASS] $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "[FAIL] $test_name"
        echo "  Expected error: $expect_error"
        echo "  Got error: $has_error"
        echo "  Output: $result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Test Cases: FORBIDDEN Patterns
# -----------------------------------------------------------------------------

test_forbidden_criterion_suru() {
    local json='{"done_when":[{"criterion":"テストする","command":"echo test","expected":"test"}]}'
    run_test "FORBIDDEN: criterion contains 'する'" "$json" "true"
}

test_forbidden_command_execute() {
    local json='{"done_when":[{"criterion":"File exists","command":"Execute test","expected":"success"}]}'
    run_test "FORBIDDEN: command starts with 'Execute'" "$json" "true"
}

test_forbidden_expected_seijou() {
    local json='{"done_when":[{"criterion":"File exists","command":"test -f foo","expected":"正常終了"}]}'
    run_test "FORBIDDEN: expected contains '正常'" "$json" "true"
}

# -----------------------------------------------------------------------------
# Test Cases: Incomplete 3-Point Set
# -----------------------------------------------------------------------------

test_incomplete_done_when_criterion_only() {
    local json='{"done_when":[{"criterion":"File exists"}]}'
    run_test "Incomplete done_when: criterion only" "$json" "true"
}

test_incomplete_validation_plan_type_only() {
    local json='{
        "phases":[{
            "subtasks":[{
                "validation_plan":{
                    "technical":{"type":"unit_test"}
                }
            }]
        }]
    }'
    run_test "Incomplete validation_plan: type only (no command/expected)" "$json" "true"
}

# -----------------------------------------------------------------------------
# Test Cases: Valid Cases
# -----------------------------------------------------------------------------

test_valid_complete_done_when() {
    local json='{
        "done_when":[{
            "criterion":"File foo.txt exists",
            "command":"test -f foo.txt && echo exists",
            "expected":"exists"
        }]
    }'
    run_test "Valid: complete done_when" "$json" "false"
}

test_valid_empty_playbook() {
    local json='{}'
    run_test "Valid: empty playbook (no done_when)" "$json" "false"
}

test_valid_complete_validation_plan() {
    local json='{
        "phases":[{
            "subtasks":[{
                "validation_plan":{
                    "technical":{
                        "command":"npm test",
                        "expected":"0 failures"
                    }
                }
            }]
        }]
    }'
    run_test "Valid: complete validation_plan" "$json" "false"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    echo "=========================================="
    echo "validate-playbook-schema.sh Test Suite"
    echo "=========================================="
    echo ""
    
    # Check validator exists
    if [ ! -x "$VALIDATOR" ]; then
        echo "ERROR: Validator not found or not executable: $VALIDATOR"
        echo "fail"
        exit 1
    fi
    
    echo "--- FORBIDDEN Pattern Tests ---"
    test_forbidden_criterion_suru || true
    test_forbidden_command_execute || true
    test_forbidden_expected_seijou || true
    
    echo ""
    echo "--- Incomplete 3-Point Set Tests ---"
    test_incomplete_done_when_criterion_only || true
    test_incomplete_validation_plan_type_only || true
    
    echo ""
    echo "--- Valid Cases Tests ---"
    test_valid_complete_done_when || true
    test_valid_empty_playbook || true
    test_valid_complete_validation_plan || true
    
    echo ""
    echo "=========================================="
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed"
    echo "=========================================="
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo "pass"
        exit 0
    else
        echo "fail"
        exit 1
    fi
}

main "$@"
