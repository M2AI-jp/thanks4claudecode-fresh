#!/usr/bin/env bash
#
# validator.sh - Input validation for session-end event
#
# Purpose: Validate session end inputs before processing
#

set -euo pipefail

UNIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$UNIT_DIR/../../.." && pwd)"
SKILLS_DIR="$REPO_ROOT/.claude/skills"

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

# Validate end handler exists
validate_end_handler() {
    local handler="$SKILLS_DIR/session-manager/handlers/end.sh"

    if [[ ! -f "$handler" ]]; then
        echo "WARN: end.sh handler not found" >&2
        return 0  # Non-fatal
    fi

    if [[ ! -x "$handler" ]]; then
        echo "WARN: end.sh handler is not executable" >&2
        return 0  # Non-fatal
    fi

    return 0
}

# Validate session state for cleanup
validate_session_state() {
    local session_dir="$REPO_ROOT/.claude/session-state"

    if [[ ! -d "$session_dir" ]]; then
        # No session state to clean up
        return 0
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

    validate_input_format "$input" || true  # Non-fatal
    validate_end_handler || true  # Non-fatal
    validate_session_state || true  # Non-fatal

    return $errors
}

# Run validation if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate "$@"
fi
