#!/usr/bin/env bash
#
# testing.sh - Testing library
#
# Provides standardized testing/assertion functions for Claude framework scripts.
#
# Usage:
#   source .claude/lib/testing.sh
#
# Functions:
#   assert_eq(actual, expected, message)     - Assert two values are equal
#   assert_file_exists(path, message)        - Assert file exists
#   assert_command_success(command, message) - Assert command succeeds
#
# Counters:
#   TEST_PASS - Number of passed tests
#   TEST_FAIL - Number of failed tests
#

# Prevent multiple sourcing
[[ -n "${_TESTING_SH_LOADED:-}" ]] && return 0
_TESTING_SH_LOADED=1

# Test counters
TEST_PASS=0
TEST_FAIL=0

# Colors (only if terminal supports it)
if [[ -t 2 ]]; then
    _TEST_RED='\033[0;31m'
    _TEST_GREEN='\033[0;32m'
    _TEST_NC='\033[0m'
else
    _TEST_RED=''
    _TEST_GREEN=''
    _TEST_NC=''
fi

# Internal test result function
_test_pass() {
    local message="$1"
    echo -e "${_TEST_GREEN}[PASS]${_TEST_NC} $message"
    ((TEST_PASS++))
}

_test_fail() {
    local message="$1"
    echo -e "${_TEST_RED}[FAIL]${_TEST_NC} $message"
    ((TEST_FAIL++))
}

# assert_eq - Assert two values are equal
#
# Arguments:
#   $1 - Actual value
#   $2 - Expected value
#   $3 - Test description (optional)
#
# Example:
#   assert_eq "$result" "expected_value" "Function returns correct value"
#
assert_eq() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Values should be equal}"

    if [[ "$actual" == "$expected" ]]; then
        _test_pass "$message"
        return 0
    else
        _test_fail "$message"
        echo "    Expected: $expected" >&2
        echo "    Actual:   $actual" >&2
        return 1
    fi
}

# assert_ne - Assert two values are not equal
#
# Arguments:
#   $1 - Actual value
#   $2 - Value that should not match
#   $3 - Test description (optional)
#
# Example:
#   assert_ne "$status" "error" "Status should not be error"
#
assert_ne() {
    local actual="$1"
    local unexpected="$2"
    local message="${3:-Values should not be equal}"

    if [[ "$actual" != "$unexpected" ]]; then
        _test_pass "$message"
        return 0
    else
        _test_fail "$message"
        echo "    Should not equal: $unexpected" >&2
        return 1
    fi
}

# assert_file_exists - Assert file exists
#
# Arguments:
#   $1 - File path
#   $2 - Test description (optional)
#
# Example:
#   assert_file_exists "config.json" "Config file should exist"
#
assert_file_exists() {
    local path="$1"
    local message="${2:-File should exist: $path}"

    if [[ -f "$path" ]]; then
        _test_pass "$message"
        return 0
    else
        _test_fail "$message"
        echo "    File not found: $path" >&2
        return 1
    fi
}

# assert_dir_exists - Assert directory exists
#
# Arguments:
#   $1 - Directory path
#   $2 - Test description (optional)
#
# Example:
#   assert_dir_exists ".claude/lib" "Lib directory should exist"
#
assert_dir_exists() {
    local path="$1"
    local message="${2:-Directory should exist: $path}"

    if [[ -d "$path" ]]; then
        _test_pass "$message"
        return 0
    else
        _test_fail "$message"
        echo "    Directory not found: $path" >&2
        return 1
    fi
}

# assert_command_success - Assert command succeeds
#
# Arguments:
#   $1 - Command to run
#   $2 - Test description (optional)
#
# Example:
#   assert_command_success "jq . config.json" "Config should be valid JSON"
#
assert_command_success() {
    local command="$1"
    local message="${2:-Command should succeed: $command}"

    if eval "$command" > /dev/null 2>&1; then
        _test_pass "$message"
        return 0
    else
        local exit_code=$?
        _test_fail "$message"
        echo "    Command: $command" >&2
        echo "    Exit code: $exit_code" >&2
        return 1
    fi
}

# assert_command_fails - Assert command fails
#
# Arguments:
#   $1 - Command to run
#   $2 - Test description (optional)
#
# Example:
#   assert_command_fails "jq . invalid.json" "Invalid JSON should fail"
#
assert_command_fails() {
    local command="$1"
    local message="${2:-Command should fail: $command}"

    if ! eval "$command" > /dev/null 2>&1; then
        _test_pass "$message"
        return 0
    else
        _test_fail "$message"
        echo "    Command unexpectedly succeeded: $command" >&2
        return 1
    fi
}

# assert_contains - Assert string contains substring
#
# Arguments:
#   $1 - String to search in
#   $2 - Substring to find
#   $3 - Test description (optional)
#
# Example:
#   assert_contains "$output" "success" "Output should contain success"
#
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain: $needle}"

    if [[ "$haystack" == *"$needle"* ]]; then
        _test_pass "$message"
        return 0
    else
        _test_fail "$message"
        echo "    Looking for: $needle" >&2
        echo "    In string: ${haystack:0:100}..." >&2
        return 1
    fi
}

# test_summary - Print test summary
#
# Call this at the end of a test suite to print the summary.
#
# Example:
#   run_all_tests
#   test_summary
#
test_summary() {
    local total=$((TEST_PASS + TEST_FAIL))

    echo ""
    echo "=== Test Summary ==="
    echo -e "  ${_TEST_GREEN}Passed: $TEST_PASS${_TEST_NC}"
    echo -e "  ${_TEST_RED}Failed: $TEST_FAIL${_TEST_NC}"
    echo "  Total:  $total"

    if [[ $TEST_FAIL -eq 0 ]]; then
        echo -e "${_TEST_GREEN}All tests passed!${_TEST_NC}"
        return 0
    else
        echo -e "${_TEST_RED}Some tests failed.${_TEST_NC}"
        return 1
    fi
}

# reset_test_counters - Reset test counters
#
# Call this to reset counters between test suites.
#
reset_test_counters() {
    TEST_PASS=0
    TEST_FAIL=0
}
