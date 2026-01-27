#!/usr/bin/env bash
#
# validator.sh - Input validation for pre-tool-bash event
#
# Purpose: Validate bash command inputs before execution
#

set -euo pipefail

UNIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$UNIT_DIR/../../.." && pwd)"

# Validate input is valid JSON
validate_input_format() {
    local input="$1"

    if ! command -v jq &>/dev/null; then
        return 0
    fi

    if ! echo "$input" | jq -e '.' > /dev/null 2>&1; then
        echo "WARN: Input is not valid JSON" >&2
        return 1
    fi

    return 0
}

# Validate command field exists
validate_command_field() {
    local input="$1"

    if ! command -v jq &>/dev/null; then
        return 0
    fi

    local command
    command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

    if [[ -z "$command" ]]; then
        echo "WARN: No command field in tool_input" >&2
        return 1
    fi

    return 0
}

# Validate bash is available
validate_bash_available() {
    if ! command -v bash &>/dev/null; then
        echo "ERROR: bash not found" >&2
        return 1
    fi

    return 0
}

# Validate guardrail scripts exist
validate_guardrails_exist() {
    local skills_dir="$REPO_ROOT/.claude/skills"
    local errors=0

    # Check access-control guard
    if [[ ! -f "$skills_dir/access-control/guards/bash-check.sh" ]]; then
        echo "WARN: bash-check.sh guard not found" >&2
    fi

    return 0
}

# Main validation entry point
validate() {
    local input="${1:-}"
    local errors=0

    if [[ -z "$input" ]]; then
        input=$(cat)
    fi

    validate_input_format "$input" || ((errors++))
    validate_command_field "$input" || true  # Non-fatal
    validate_bash_available || ((errors++))
    validate_guardrails_exist || true  # Non-fatal

    return $errors
}

# Run validation if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate "$@"
fi
