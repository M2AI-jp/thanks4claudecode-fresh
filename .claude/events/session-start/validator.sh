#!/usr/bin/env bash
#
# validator.sh - Input validation for session-start event
#
# Purpose: Validate session state and environment at startup
#

set -euo pipefail

UNIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$UNIT_DIR/../../.." && pwd)"

# Validate session state
validate_session_state() {
    local state_file="$REPO_ROOT/state.md"

    # Check state.md exists
    if [[ ! -f "$state_file" ]]; then
        echo "WARN: state.md not found" >&2
        return 1
    fi

    # Check state.md is readable
    if [[ ! -r "$state_file" ]]; then
        echo "ERROR: state.md is not readable" >&2
        return 1
    fi

    return 0
}

# Validate required files exist
validate_required_files() {
    local required_files=(
        "$REPO_ROOT/CLAUDE.md"
        "$REPO_ROOT/state.md"
    )

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo "WARN: Required file missing: $file" >&2
        fi
    done

    return 0
}

# Validate git repository state
validate_git_state() {
    if ! git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
        echo "WARN: Not a git repository" >&2
        return 1
    fi

    return 0
}

# Main validation entry point
validate() {
    local errors=0

    validate_session_state || ((errors++))
    validate_required_files || true  # Non-fatal
    validate_git_state || true  # Non-fatal

    return $errors
}

# Run validation if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate "$@"
fi
