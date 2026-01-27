#!/usr/bin/env bash
#
# validator.sh - Input validation for notification event
#
# Purpose: Validate notification inputs (minimal validation for no-op handler)
#

set -euo pipefail

UNIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$UNIT_DIR/../../.." && pwd)"

# Validate input is valid JSON (if provided)
validate_input_format() {
    local input="$1"

    # Empty input is acceptable for notification
    if [[ -z "$input" ]]; then
        return 0
    fi

    if ! command -v jq &>/dev/null; then
        return 0
    fi

    if ! echo "$input" | jq -e '.' > /dev/null 2>&1; then
        echo "WARN: Notification input is not valid JSON" >&2
        return 0  # Non-fatal for notification
    fi

    return 0
}

# Main validation entry point
validate() {
    local input="${1:-}"
    local errors=0

    if [[ -z "$input" ]]; then
        input=$(cat 2>/dev/null || true)
    fi

    validate_input_format "$input" || true  # Non-fatal

    return $errors
}

# Run validation if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate "$@"
fi
