#!/usr/bin/env bash
# ==============================================================================
# tests/guards/test-critic-guard.sh - critic-guard.sh のテスト
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
GUARD_SCRIPT="$ROOT_DIR/.claude/skills/reward-guard/guards/critic-guard.sh"

TOTAL=0
PASSED=0

assert_exit_code() {
    local name="$1"
    local expected="$2"
    local actual="$3"

    TOTAL=$((TOTAL + 1))
    if [[ "$actual" -eq "$expected" ]]; then
        echo "  ok - $name (exit $actual)"
        PASSED=$((PASSED + 1))
    else
        echo "  fail - $name (expected exit $expected, got exit $actual)"
        return 1
    fi
}

build_input() {
    local file_path="$1"
    local new_string="$2"
    local old_string="${3:-old}"

    jq -nc \
        --arg file_path "$file_path" \
        --arg old_string "$old_string" \
        --arg new_string "$new_string" \
        '{tool_name:"Edit", tool_input:{file_path:$file_path, old_string:$old_string, new_string:$new_string}}'
}

run_guard() {
    local input="$1"
    set +e
    echo "$input" | bash "$GUARD_SCRIPT" > /dev/null 2>&1
    local exit_code=$?
    set -e
    echo "$exit_code"
}

make_playbook_snippet() {
    cat << 'PLAYBOOK_SNIP'
- [x] **p3.3**: critic-guard evidence
  - validations:
    - technical: "__TECHNICAL__"
    - consistency: "__CONSISTENCY__"
    - completeness: "__COMPLETENESS__"
PLAYBOOK_SNIP
}

render_playbook_snippet() {
    local technical="$1"
    local consistency="$2"
    local completeness="$3"
    local content

    content=$(make_playbook_snippet)
    content=${content//__TECHNICAL__/$technical}
    content=${content//__CONSISTENCY__/$consistency}
    content=${content//__COMPLETENESS__/$completeness}
    echo "$content"
}

echo "Testing critic-guard.sh"
echo "------------------------"

# Good evidence patterns

test_good_specific_details() {
    local content
    content=$(render_playbook_snippet \
        "PASS - specific details about what was verified" \
        "PASS - command output shows X" \
        "PASS - file contains Y")
    local input
    input=$(build_input "plan/playbook-test.md" "$content")
    local exit_code
    exit_code=$(run_guard "$input")
    assert_exit_code "good evidence: specific details" 0 "$exit_code"
}

test_good_command_output() {
    local content
    content=$(render_playbook_snippet \
        "PASS - command output shows X" \
        "PASS - command output shows X" \
        "PASS - file contains Y")
    local input
    input=$(build_input "plan/playbook-test.md" "$content")
    local exit_code
    exit_code=$(run_guard "$input")
    assert_exit_code "good evidence: command output" 0 "$exit_code"
}

test_good_file_contains() {
    local content
    content=$(render_playbook_snippet \
        "PASS - file contains Y" \
        "PASS - command output shows X" \
        "PASS - file contains Y")
    local input
    input=$(build_input "plan/playbook-test.md" "$content")
    local exit_code
    exit_code=$(run_guard "$input")
    assert_exit_code "good evidence: file contains" 0 "$exit_code"
}

# Bad evidence patterns

test_bad_pass_only() {
    local content
    content=$(render_playbook_snippet \
        "PASS" \
        "PASS - command output shows X" \
        "PASS - file contains Y")
    local input
    input=$(build_input "plan/playbook-test.md" "$content")
    local exit_code
    exit_code=$(run_guard "$input")
    assert_exit_code "bad evidence: PASS only" 2 "$exit_code"
}

test_bad_done_only() {
    local content
    content=$(render_playbook_snippet \
        "done" \
        "PASS - command output shows X" \
        "PASS - file contains Y")
    local input
    input=$(build_input "plan/playbook-test.md" "$content")
    local exit_code
    exit_code=$(run_guard "$input")
    assert_exit_code "bad evidence: done only" 2 "$exit_code"
}

test_bad_completed_only() {
    local content
    content=$(render_playbook_snippet \
        "completed" \
        "PASS - command output shows X" \
        "PASS - file contains Y")
    local input
    input=$(build_input "plan/playbook-test.md" "$content")
    local exit_code
    exit_code=$(run_guard "$input")
    assert_exit_code "bad evidence: completed only" 2 "$exit_code"
}

test_bad_pass_dash_empty() {
    local content
    content=$(render_playbook_snippet \
        "PASS - " \
        "PASS - command output shows X" \
        "PASS - file contains Y")
    local input
    input=$(build_input "plan/playbook-test.md" "$content")
    local exit_code
    exit_code=$(run_guard "$input")
    assert_exit_code "bad evidence: PASS - empty" 2 "$exit_code"
}

test_bad_empty_validation() {
    local content
    content=$(render_playbook_snippet \
        "" \
        "PASS - command output shows X" \
        "PASS - file contains Y")
    local input
    input=$(build_input "plan/playbook-test.md" "$content")
    local exit_code
    exit_code=$(run_guard "$input")
    assert_exit_code "bad evidence: empty validation" 2 "$exit_code"
}

test_bad_missing_prefix() {
    local content
    content=$(render_playbook_snippet \
        "file contains Y" \
        "PASS - command output shows X" \
        "PASS - file contains Y")
    local input
    input=$(build_input "plan/playbook-test.md" "$content")
    local exit_code
    exit_code=$(run_guard "$input")
    assert_exit_code "bad evidence: missing PASS - prefix" 2 "$exit_code"
}

test_bad_pass_done() {
    local content
    content=$(render_playbook_snippet \
        "PASS - done" \
        "PASS - command output shows X" \
        "PASS - file contains Y")
    local input
    input=$(build_input "plan/playbook-test.md" "$content")
    local exit_code
    exit_code=$(run_guard "$input")
    assert_exit_code "bad evidence: PASS - done" 2 "$exit_code"
}

test_bad_pass_completed() {
    local content
    content=$(render_playbook_snippet \
        "PASS - completed" \
        "PASS - command output shows X" \
        "PASS - file contains Y")
    local input
    input=$(build_input "plan/playbook-test.md" "$content")
    local exit_code
    exit_code=$(run_guard "$input")
    assert_exit_code "bad evidence: PASS - completed" 2 "$exit_code"
}

# テスト実行
test_good_specific_details
test_good_command_output
test_good_file_contains
test_bad_pass_only
test_bad_done_only
test_bad_completed_only
test_bad_pass_dash_empty
test_bad_empty_validation
test_bad_missing_prefix
test_bad_pass_done
test_bad_pass_completed

echo ""
echo "Results: $PASSED/$TOTAL passed"

if [[ $PASSED -eq $TOTAL ]]; then
    exit 0
else
    exit 1
fi
