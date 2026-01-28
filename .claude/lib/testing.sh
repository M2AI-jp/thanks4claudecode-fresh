#!/usr/bin/env bash
#
# testing.sh - Testing utilities for Claude framework scripts
#
# Provides assertion functions for testing and validation.
#
# Usage:
#   source .claude/lib/testing.sh
#
# Functions:
#   - assert_eq         - Assert two values are equal
#   - assert_file_exists - Assert a file exists
#   - assert_command_success - Assert a command succeeds
#

# Prevent multiple sourcing
[[ -n "${_TESTING_SH_LOADED:-}" ]] && return 0
_TESTING_SH_LOADED=1

# Colors for output
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_NC='\033[0m' # No Color

# Assert two values are equal
# Usage: assert_eq "expected" "actual" "message"
assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${_GREEN}[PASS]${_NC} $message"
        return 0
    else
        echo -e "${_RED}[FAIL]${_NC} $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

# Assert a file exists
# Usage: assert_file_exists "/path/to/file" "message"
assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"

    if [[ -f "$file" ]]; then
        echo -e "${_GREEN}[PASS]${_NC} $message"
        return 0
    else
        echo -e "${_RED}[FAIL]${_NC} $message"
        echo "  File not found: $file"
        return 1
    fi
}

# Assert a directory exists
# Usage: assert_dir_exists "/path/to/dir" "message"
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory should exist: $dir}"

    if [[ -d "$dir" ]]; then
        echo -e "${_GREEN}[PASS]${_NC} $message"
        return 0
    else
        echo -e "${_RED}[FAIL]${_NC} $message"
        echo "  Directory not found: $dir"
        return 1
    fi
}

# Assert a command succeeds (exit code 0)
# Usage: assert_command_success "command" "message"
assert_command_success() {
    local cmd="$1"
    local message="${2:-Command should succeed: $cmd}"

    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${_GREEN}[PASS]${_NC} $message"
        return 0
    else
        local exit_code=$?
        echo -e "${_RED}[FAIL]${_NC} $message"
        echo "  Command: $cmd"
        echo "  Exit code: $exit_code"
        return 1
    fi
}

# Assert a command fails (exit code != 0)
# Usage: assert_command_fails "command" "message"
assert_command_fails() {
    local cmd="$1"
    local message="${2:-Command should fail: $cmd}"

    if ! eval "$cmd" >/dev/null 2>&1; then
        echo -e "${_GREEN}[PASS]${_NC} $message"
        return 0
    else
        echo -e "${_RED}[FAIL]${_NC} $message"
        echo "  Command: $cmd"
        echo "  Expected failure but succeeded"
        return 1
    fi
}

# Assert a string contains a substring
# Usage: assert_contains "haystack" "needle" "message"
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${_GREEN}[PASS]${_NC} $message"
        return 0
    else
        echo -e "${_RED}[FAIL]${_NC} $message"
        echo "  Looking for: $needle"
        echo "  In string: $haystack"
        return 1
    fi
}

# Assert exit code matches expected
# Usage: assert_exit_code "command" expected_code "message"
assert_exit_code() {
    local cmd="$1"
    local expected="$2"
    local message="${3:-Exit code should be $expected}"

    eval "$cmd" >/dev/null 2>&1
    local actual=$?

    if [[ "$actual" -eq "$expected" ]]; then
        echo -e "${_GREEN}[PASS]${_NC} $message"
        return 0
    else
        echo -e "${_RED}[FAIL]${_NC} $message"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code: $actual"
        return 1
    fi
}
