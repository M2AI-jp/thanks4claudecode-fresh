#!/usr/bin/env bash
#
# validate-playbook.sh
#
# Playbook JSON validation script
# Validates plan.json and progress.json files against their schemas
#
# Usage:
#   validate-playbook.sh <path-to-plan.json>
#   validate-playbook.sh --all
#
# Requirements:
#   - jq (for JSON parsing)
#   - ajv-cli (optional, for full JSON Schema validation)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCHEMA_DIR="$REPO_ROOT/.claude/schema"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_info() { echo "       $1"; }

# Check if jq is available
if ! command -v jq &> /dev/null; then
    log_fail "jq is required but not installed"
    exit 1
fi

# Validate a single plan.json file
validate_plan() {
    local plan_file="$1"
    local errors=0

    echo "Validating: $plan_file"

    # Check file exists
    if [[ ! -f "$plan_file" ]]; then
        log_fail "File not found: $plan_file"
        return 1
    fi

    # Check valid JSON
    if ! jq empty "$plan_file" 2>/dev/null; then
        log_fail "Invalid JSON syntax"
        return 1
    fi

    # Check required fields
    local required_fields=("format_version" "meta" "goal" "phases")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$plan_file" > /dev/null 2>&1; then
            log_fail "Missing required field: $field"
            ((errors++))
        fi
    done

    # Check meta.id
    if ! jq -e '.meta.id' "$plan_file" > /dev/null 2>&1; then
        log_fail "Missing meta.id"
        ((errors++))
    fi

    # Check meta.status is valid
    local status=$(jq -r '.meta.status // "null"' "$plan_file")
    if [[ ! "$status" =~ ^(draft|active|completed|archived)$ ]]; then
        log_fail "Invalid meta.status: $status (must be draft|active|completed|archived)"
        ((errors++))
    fi

    # Check phases array is not empty
    local phase_count=$(jq '.phases | length' "$plan_file")
    if [[ "$phase_count" -eq 0 ]]; then
        log_fail "phases array is empty"
        ((errors++))
    else
        log_pass "phases array has $phase_count phase(s)"
    fi

    # Check each phase has required fields
    local phase_ids=$(jq -r '.phases[].id' "$plan_file")
    for phase_id in $phase_ids; do
        local subtask_count=$(jq ".phases[] | select(.id == \"$phase_id\") | .subtasks | length" "$plan_file")
        if [[ "$subtask_count" -eq 0 ]]; then
            log_warn "Phase $phase_id has no subtasks"
        fi
    done

    # Check goal.done_when
    local done_when_count=$(jq '.goal.done_when | length' "$plan_file" 2>/dev/null || echo "0")
    if [[ "$done_when_count" -eq 0 ]]; then
        log_warn "goal.done_when is empty"
    else
        log_pass "goal.done_when has $done_when_count criterion(s)"
    fi

    if [[ $errors -eq 0 ]]; then
        log_pass "Validation passed"
        return 0
    else
        log_fail "Validation failed with $errors error(s)"
        return 1
    fi
}

# Validate a single progress.json file
validate_progress() {
    local progress_file="$1"
    local errors=0

    echo "Validating: $progress_file"

    # Check file exists
    if [[ ! -f "$progress_file" ]]; then
        log_fail "File not found: $progress_file"
        return 1
    fi

    # Check valid JSON
    if ! jq empty "$progress_file" 2>/dev/null; then
        log_fail "Invalid JSON syntax"
        return 1
    fi

    # Check required fields
    local required_fields=("format_version" "playbook" "active" "phases" "subtasks")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$progress_file" > /dev/null 2>&1; then
            log_fail "Missing required field: $field"
            ((errors++))
        fi
    done

    # Check playbook.status is valid
    local status=$(jq -r '.playbook.status // "null"' "$progress_file")
    if [[ ! "$status" =~ ^(draft|active|completed|archived)$ ]]; then
        log_fail "Invalid playbook.status: $status"
        ((errors++))
    fi

    # Check phase statuses
    local invalid_statuses=$(jq -r '.phases | to_entries[] | select(.value.status | test("^(pending|in_progress|done|blocked)$") | not) | .key' "$progress_file" 2>/dev/null)
    if [[ -n "$invalid_statuses" ]]; then
        log_fail "Invalid phase status in: $invalid_statuses"
        ((errors++))
    fi

    # Check subtask statuses
    local invalid_subtask_statuses=$(jq -r '.subtasks | to_entries[] | select(.value.status | test("^(pending|in_progress|done|blocked)$") | not) | .key' "$progress_file" 2>/dev/null)
    if [[ -n "$invalid_subtask_statuses" ]]; then
        log_fail "Invalid subtask status in: $invalid_subtask_statuses"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log_pass "Validation passed"
        return 0
    else
        log_fail "Validation failed with $errors error(s)"
        return 1
    fi
}

# Validate all playbooks in the repository
validate_all() {
    local total_errors=0

    echo "=== Validating all playbooks ==="
    echo ""

    # Find all plan.json files
    while IFS= read -r -d '' plan_file; do
        validate_plan "$plan_file" || ((total_errors++))
        echo ""
    done < <(find "$REPO_ROOT/play" -name 'plan.json' -print0 2>/dev/null)

    # Find all progress.json files
    while IFS= read -r -d '' progress_file; do
        validate_progress "$progress_file" || ((total_errors++))
        echo ""
    done < <(find "$REPO_ROOT/play" -name 'progress.json' -print0 2>/dev/null)

    echo "=== Summary ==="
    if [[ $total_errors -eq 0 ]]; then
        log_pass "All validations passed"
        return 0
    else
        log_fail "$total_errors file(s) failed validation"
        return 1
    fi
}

# Main entry point
main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <path-to-plan.json> | --all"
        exit 1
    fi

    if [[ "$1" == "--all" ]]; then
        validate_all
    elif [[ "$1" == *"plan.json" ]]; then
        validate_plan "$1"
    elif [[ "$1" == *"progress.json" ]]; then
        validate_progress "$1"
    else
        # Try to guess based on filename
        if [[ -f "$1" ]]; then
            if jq -e '.phases[0].subtasks' "$1" > /dev/null 2>&1; then
                validate_plan "$1"
            elif jq -e '.subtasks' "$1" > /dev/null 2>&1; then
                validate_progress "$1"
            else
                log_fail "Unknown file type"
                exit 1
            fi
        else
            log_fail "File not found: $1"
            exit 1
        fi
    fi
}

main "$@"
