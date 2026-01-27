#!/usr/bin/env bash
#
# validator.sh - Input validation for subagent-stop event
#
# Purpose: Validate subagent stop inputs before processing
#

set -euo pipefail

UNIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$UNIT_DIR/../../.." && pwd)"

# Validate jq is available (required for this event)
validate_jq_available() {
    if ! command -v jq &>/dev/null; then
        echo "ERROR: jq not found - required for subagent-stop" >&2
        return 1
    fi

    return 0
}

# Validate input is valid JSON
validate_input_format() {
    local input="$1"

    if ! echo "$input" | jq -e '.' > /dev/null 2>&1; then
        echo "ERROR: Input is not valid JSON" >&2
        return 1
    fi

    return 0
}

# Validate agent_id field
validate_agent_id() {
    local input="$1"

    local agent_id
    agent_id=$(echo "$input" | jq -r '.agent_id // empty' 2>/dev/null)

    if [[ -z "$agent_id" ]] || [[ "$agent_id" == "null" ]]; then
        echo "WARN: No agent_id in subagent stop input" >&2
        return 0  # Non-fatal, will use "unknown"
    fi

    return 0
}

# Validate log directory is writable
validate_log_writable() {
    local log_dir="$REPO_ROOT/.claude/logs"

    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null || {
            echo "WARN: Cannot create log directory" >&2
            return 0  # Non-fatal
        }
    fi

    if [[ ! -w "$log_dir" ]]; then
        echo "WARN: Log directory is not writable" >&2
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

    validate_jq_available || ((errors++))

    if [[ $errors -eq 0 ]]; then
        validate_input_format "$input" || ((errors++))
        validate_agent_id "$input" || true  # Non-fatal
    fi

    validate_log_writable || true  # Non-fatal

    return $errors
}

# Run validation if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate "$@"
fi
