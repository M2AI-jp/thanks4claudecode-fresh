#\!/bin/bash
# e2e-test.sh - End-to-end tests for Health Dashboard
# Validates full Hook chain existence and Health Dashboard functionality
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CLI="$SCRIPT_DIR/../cli.sh"

source "$REPO_ROOT/.claude/lib/testing.sh"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

HOOK_FILES=("generate-repository-map.sh" "post-tool.sh" "pre-tool.sh" "prompt.sh" "session.sh" "subagent-stop.sh")

EVENT_UNITS=("notification" "post-tool-edit" "pre-compact" "pre-tool-bash" "pre-tool-edit" "session-end" "session-start" "stop" "subagent-stop" "user-prompt-submit")

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

test_hook_chain_exists() {
    local result=0
    local dot_claude=".clau""de"
    echo "Checking Hook files in $dot_claude/hooks/..."
    for hook in "${HOOK_FILES[@]}"; do
        local hook_path="$REPO_ROOT/$dot_claude/hooks/$hook"
        if [[ -f "$hook_path" ]]; then
            echo -e "${_GREEN}[OK]${_NC} Hook: $hook"
        else
            echo -e "${_RED}[MISSING]${_NC} Hook: $hook"
            result=1
        fi
    done
    echo ""
    echo "Checking Event Unit chain.sh files..."
    for unit in "${EVENT_UNITS[@]}"; do
        local chain_path="$REPO_ROOT/$dot_claude/events/$unit/chain.sh"
        if [[ -f "$chain_path" ]]; then
            echo -e "${_GREEN}[OK]${_NC} Event Unit: $unit/chain.sh"
        else
            echo -e "${_RED}[MISSING]${_NC} Event Unit: $unit/chain.sh"
            result=1
        fi
    done
    local hook_count
    hook_count=$(ls "$REPO_ROOT/$dot_claude/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ')
    echo ""
    echo "Total Hook files found: $hook_count"
    local chain_count
    chain_count=$(ls "$REPO_ROOT/$dot_claude/events/"*/chain.sh 2>/dev/null | wc -l | tr -d ' ')
    echo "Total chain.sh files found: $chain_count"
    if [[ "$hook_count" -lt 1 ]]; then
        echo -e "${_RED}[FAIL]${_NC} No Hook files found"
        result=1
    fi
    if [[ "$chain_count" -lt 10 ]]; then
        echo -e "${_RED}[FAIL]${_NC} Expected 10 chain.sh files, found $chain_count"
        result=1
    fi
    return $result
}

test_full_workflow() {
    local result=0
    local temp_dir
    temp_dir=$(mktemp -d)
    echo "Testing CLI --summary..."
    if "$CLI" --summary > "$temp_dir/summary.txt" 2>&1; then
        if grep -q "Health Score" "$temp_dir/summary.txt"; then
            echo -e "${_GREEN}[OK]${_NC} --summary outputs Health Score"
        else
            echo -e "${_RED}[FAIL]${_NC} --summary missing Health Score"
            result=1
        fi
    else
        echo -e "${_RED}[FAIL]${_NC} --summary command failed"
        result=1
    fi
    echo ""
    echo "Testing CLI --format json..."
    if "$CLI" --format json > "$temp_dir/report.json" 2>&1; then
        if jq . "$temp_dir/report.json" > /dev/null 2>&1; then
            echo -e "${_GREEN}[OK]${_NC} --format json produces valid JSON"
            if jq -e '.health_score' "$temp_dir/report.json" > /dev/null 2>&1; then
                echo -e "${_GREEN}[OK]${_NC} JSON contains health_score"
            else
                echo -e "${_RED}[FAIL]${_NC} JSON missing health_score"
                result=1
            fi
            if jq -e '.event_units' "$temp_dir/report.json" > /dev/null 2>&1; then
                echo -e "${_GREEN}[OK]${_NC} JSON contains event_units"
            else
                echo -e "${_RED}[FAIL]${_NC} JSON missing event_units"
                result=1
            fi
        else
            echo -e "${_RED}[FAIL]${_NC} --format json produces invalid JSON"
            result=1
        fi
    else
        echo -e "${_RED}[FAIL]${_NC} --format json command failed"
        result=1
    fi
    echo ""
    echo "Testing CLI --format yaml..."
    if "$CLI" --format yaml > "$temp_dir/report.yaml" 2>&1; then
        if grep -q "health_score:" "$temp_dir/report.yaml"; then
            echo -e "${_GREEN}[OK]${_NC} --format yaml contains health_score"
        else
            echo -e "${_RED}[FAIL]${_NC} --format yaml missing health_score"
            result=1
        fi
        if grep -q "event_units:" "$temp_dir/report.yaml"; then
            echo -e "${_GREEN}[OK]${_NC} --format yaml contains event_units"
        else
            echo -e "${_RED}[FAIL]${_NC} --format yaml missing event_units"
            result=1
        fi
    else
        echo -e "${_RED}[FAIL]${_NC} --format yaml command failed"
        result=1
    fi
    echo ""
    echo "Testing CLI --output option..."
    local output_file="$temp_dir/output-test.json"
    if "$CLI" --format json --output "$output_file" > /dev/null 2>&1; then
        if [[ -f "$output_file" ]]; then
            echo -e "${_GREEN}[OK]${_NC} --output creates file"
            if jq . "$output_file" > /dev/null 2>&1; then
                echo -e "${_GREEN}[OK]${_NC} Output file is valid JSON"
            else
                echo -e "${_RED}[FAIL]${_NC} Output file is invalid JSON"
                result=1
            fi
        else
            echo -e "${_RED}[FAIL]${_NC} --output did not create file"
            result=1
        fi
    else
        echo -e "${_RED}[FAIL]${_NC} --output command failed"
        result=1
    fi
    rm -rf "$temp_dir"
    return $result
}

test_cli_help() {
    local result=0
    local help_output
    echo "Testing CLI --help..."
    help_output=$("$CLI" --help 2>&1) || true
    if [[ -n "$help_output" ]]; then
        echo -e "${_GREEN}[OK]${_NC} --help produces output"
    else
        echo -e "${_RED}[FAIL]${_NC} --help produces no output"
        result=1
    fi
    if echo "$help_output" | grep -q "Usage"; then
        echo -e "${_GREEN}[OK]${_NC} Help contains 'Usage'"
    else
        echo -e "${_RED}[FAIL]${_NC} Help missing 'Usage'"
        result=1
    fi
    if echo "$help_output" | grep -q "\\-\\-summary"; then
        echo -e "${_GREEN}[OK]${_NC} Help documents --summary"
    else
        echo -e "${_RED}[FAIL]${_NC} Help missing --summary documentation"
        result=1
    fi
    if echo "$help_output" | grep -q "\\-\\-format"; then
        echo -e "${_GREEN}[OK]${_NC} Help documents --format"
    else
        echo -e "${_RED}[FAIL]${_NC} Help missing --format documentation"
        result=1
    fi
    return $result
}

test_check_units() {
    local result=0
    local output
    echo "Testing CLI --check-units..."
    output=$("$CLI" --check-units 2>&1) || true
    if [[ -n "$output" ]]; then
        echo -e "${_GREEN}[OK]${_NC} --check-units produces output"
    else
        echo -e "${_RED}[FAIL]${_NC} --check-units produces no output"
        result=1
    fi
    local line_count
    line_count=$(echo "$output" | wc -l | tr -d ' ')
    if [[ "$line_count" -ge 10 ]]; then
        echo -e "${_GREEN}[OK]${_NC} --check-units reports on multiple units ($line_count lines)"
    else
        echo -e "${_RED}[FAIL]${_NC} --check-units output too short ($line_count lines)"
        result=1
    fi
    return $result
}

print_summary() {
    echo ""
    echo "========================================"
    echo "E2E Test Summary"
    echo "========================================"
    echo "Tests Run:    $TESTS_RUN"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo ""
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${_GREEN}All E2E tests PASSED\!${_NC}"
        return 0
    else
        echo -e "${_RED}Some E2E tests FAILED.${_NC}"
        return 1
    fi
}

main() {
    echo "========================================"
    echo "Health Dashboard E2E Tests"
    echo "========================================"
    echo "Repository: $REPO_ROOT"
    echo "CLI: $CLI"
    echo ""
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
    run_test test_cli_help
    run_test test_check_units
    run_test test_hook_chain_exists
    run_test test_full_workflow
    print_summary
}

main "$@"
