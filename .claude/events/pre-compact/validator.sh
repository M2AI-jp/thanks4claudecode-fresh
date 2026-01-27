#!/usr/bin/env bash
#
# validator.sh - Input validation for pre-compact event
#
# Purpose: Validate compact event inputs before processing
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

# Validate compact handler exists
validate_compact_handler() {
    local handler="$SKILLS_DIR/session-manager/handlers/compact.sh"

    if [[ ! -f "$handler" ]]; then
        echo "WARN: compact.sh handler not found" >&2
        return 0  # Non-fatal, chain.sh handles this
    fi

    if [[ ! -x "$handler" ]]; then
        echo "WARN: compact.sh handler is not executable" >&2
        return 0  # Non-fatal
    fi

    return 0
}

# Validate state.md for context preservation
validate_state_file() {
    local state_file="$REPO_ROOT/state.md"

    if [[ ! -f "$state_file" ]]; then
        echo "WARN: state.md not found - compact may lose state context" >&2
        return 0  # Non-fatal
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
    validate_compact_handler || true  # Non-fatal
    validate_state_file || true  # Non-fatal

    return $errors
}

# Run validation if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate "$@"
fi
