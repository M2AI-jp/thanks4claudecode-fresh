#\!/bin/bash
# integration-test.sh - Integration tests for Health Dashboard CLI
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$REPO_ROOT/.claude/lib/testing.sh"
source "$SCRIPT_DIR/../lib/formatter.sh"
LOG_DIR="$REPO_ROOT/.claude/logs"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    echo ""
    echo "Running: $test_name"
    echo "----------------------------------------"
    if "$test_name"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${_GREEN}[PASS]${_NC} $test_name"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${_RED}[FAIL]${_NC} $test_name"
    fi
}

test_session_start() {
    local log_file="$LOG_DIR/session-start.log"
    local result=0
    assert_file_exists "$log_file" "session-start.log exists" || result=1
    local parsed
    parsed=$(parse_telemetry_log "$log_file" 2>/dev/null | head -1) || true
    if [[ -n "$parsed" ]]; then
        assert_contains "$parsed" "session-start" "Contains event type" || result=1
    else
        echo -e "${_RED}[FAIL]${_NC} Failed to parse"
        result=1
    fi
    local entry_count
    entry_count=$(jq -s 'length' "$log_file" 2>/dev/null || echo "0")
    if [[ "$entry_count" -gt 0 ]]; then
        echo -e "${_GREEN}[PASS]${_NC} Found $entry_count entries"
    else
        result=1
    fi
    return $result
}

test_pre_tool_edit() {
    local log_file="$LOG_DIR/pre-tool-edit.log"
    local result=0
    assert_file_exists "$log_file" "pre-tool-edit.log exists" || result=1
    local parsed
    parsed=$(parse_telemetry_log "$log_file" 2>/dev/null | head -1) || true
    if [[ -n "$parsed" ]]; then
        assert_contains "$parsed" "pre-tool-edit" "Contains event type" || result=1
    else
        result=1
    fi
    local entry_count
    entry_count=$(jq -s 'length' "$log_file" 2>/dev/null || echo "0")
    if [[ "$entry_count" -gt 0 ]]; then
        echo -e "${_GREEN}[PASS]${_NC} Found $entry_count entries"
    else
        result=1
    fi
    return $result
}

test_pre_tool_bash() {
    local log_file="$LOG_DIR/pre-tool-bash.log"
    local result=0
    assert_file_exists "$log_file" "pre-tool-bash.log exists" || result=1
    # Handle pretty-printed JSON by counting top-level objects
    local entry_count
    entry_count=$(grep -c '"event": "pre-tool-bash"' "$log_file" 2>/dev/null || echo "0")
    if [[ "$entry_count" -gt 0 ]]; then
        echo -e "${_GREEN}[PASS]${_NC} Found $entry_count entries"
    else
        result=1
    fi
    # Check first entry has event field
    local first_event
    first_event=$(head -50 "$log_file" | grep '"event":' | head -1 || echo "")
    if [[ -n "$first_event" ]]; then
        echo -e "${_GREEN}[PASS]${_NC} pre-tool-bash.log has event field"
    else
        result=1
    fi
    return $result
}

test_log_parser() {
    local result=0
    local event_types
    event_types=$(get_event_types)
    assert_contains "$event_types" "session-start" "Event types include session-start" || result=1
    if is_valid_event_type "session-start"; then
        echo -e "${_GREEN}[PASS]${_NC} is_valid_event_type accepts session-start"
    else
        result=1
    fi
    return $result
}

test_analyzer() {
    local result=0
    local health_data
    health_data=$(calculate_health_score "$LOG_DIR" 2>/dev/null) || true
    if [[ -n "$health_data" ]]; then
        if echo "$health_data" | jq . > /dev/null 2>&1; then
            echo -e "${_GREEN}[PASS]${_NC} calculate_health_score returns valid JSON"
        else
            result=1
        fi
    else
        result=1
    fi
    return $result
}

test_cli_help() {
    local result=0
    local cli="$SCRIPT_DIR/../cli.sh"
    local help_output
    help_output=$("$cli" --help 2>&1) || true
    assert_contains "$help_output" "Usage" "Help contains Usage" || result=1
    return $result
}

print_summary() {
    echo ""
    echo "========================================"
    echo "Test Summary"
    echo "========================================"
    echo "Tests Run:    $TESTS_RUN"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo ""
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${_GREEN}All tests PASSED\!${_NC}"
        return 0
    else
        echo -e "${_RED}Some tests FAILED.${_NC}"
        return 1
    fi
}

main() {
    echo "========================================"
    echo "Health Dashboard Integration Tests"
    echo "========================================"
    echo "Repository: $REPO_ROOT"
    echo "Log Directory: $LOG_DIR"
    if [[ $# -gt 0 ]]; then
        local test_func="$1"
        if declare -f "$test_func" > /dev/null; then
            run_test "$test_func"
            print_summary
            exit $?
        else
            echo "Error: Unknown test function: $test_func" >&2
            exit 1
        fi
    fi
    run_test test_session_start
    run_test test_pre_tool_edit
    run_test test_pre_tool_bash
    run_test test_log_parser
    run_test test_analyzer
    run_test test_cli_help
    print_summary
}

main "$@"
