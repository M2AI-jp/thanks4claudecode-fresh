#!/usr/bin/env bash
#
# validator.sh - Input validation for user-prompt-submit event
#
# Purpose: Validate user prompt input before processing
#

set -euo pipefail

UNIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$UNIT_DIR/../../.." && pwd)"

# Validate input is valid JSON (if jq available)
validate_input_format() {
    local input="$1"

    # Check if jq is available
    if ! command -v jq &>/dev/null; then
        # Without jq, skip JSON validation
        return 0
    fi

    # Validate JSON structure
    if ! echo "$input" | jq -e '.' > /dev/null 2>&1; then
        echo "WARN: Input is not valid JSON" >&2
        return 1
    fi

    return 0
}

# Validate prompt field exists
validate_prompt_field() {
    local input="$1"

    if ! command -v jq &>/dev/null; then
        return 0
    fi

    local prompt
    prompt=$(echo "$input" | jq -r '.prompt // empty' 2>/dev/null)

    if [[ -z "$prompt" ]]; then
        echo "WARN: No prompt field in input" >&2
        return 1
    fi

    return 0
}

# Validate state.md is readable for state injection
validate_state_accessible() {
    local state_file="$REPO_ROOT/state.md"

    if [[ ! -f "$state_file" ]]; then
        echo "WARN: state.md not found - state injection will be limited" >&2
        return 0  # Non-fatal
    fi

    if [[ ! -r "$state_file" ]]; then
        echo "ERROR: state.md is not readable" >&2
        return 1
    fi

    return 0
}

# Main validation entry point
validate() {
    local input="${1:-}"
    local errors=0

    # Read from stdin if no argument
    if [[ -z "$input" ]]; then
        input=$(cat)
    fi

    validate_input_format "$input" || ((errors++))
    validate_prompt_field "$input" || true  # Non-fatal
    validate_state_accessible || true  # Non-fatal

    return $errors
}

# Run validation if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate "$@"
fi
