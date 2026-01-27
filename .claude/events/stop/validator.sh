#!/usr/bin/env bash
#
# validator.sh - Input validation for stop event
#
# Purpose: Validate state before session stops
#

set -euo pipefail

UNIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$UNIT_DIR/../../.." && pwd)"

# Validate no pending work
validate_pending_work() {
    local pending_file="$REPO_ROOT/.claude/session-state/post-loop-pending"

    if [[ -f "$pending_file" ]]; then
        echo "WARN: post-loop pending file exists" >&2
        echo "HINT: Run Skill(skill='post-loop') before stopping" >&2
        return 1
    fi

    return 0
}

# Validate uncommitted changes
validate_git_state() {
    if ! git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
        return 0  # Not a git repo, skip
    fi

    local status
    status="$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)"

    if [[ -n "$status" ]]; then
        local change_count
        change_count="$(echo "$status" | wc -l | tr -d ' ')"
        echo "WARN: $change_count uncommitted change(s)" >&2
    fi

    return 0
}

# Validate session state
validate_session_state() {
    local state_file="$REPO_ROOT/state.md"

    if [[ ! -f "$state_file" ]]; then
        return 0
    fi

    # Check for active playbook
    if grep -q 'active:.*play/' "$state_file" 2>/dev/null; then
        echo "WARN: Active playbook exists" >&2
    fi

    return 0
}

# Validate stop is safe
validate_stop_safety() {
    # Check for any running background tasks
    local session_state_dir="$REPO_ROOT/.claude/session-state"

    if [[ -d "$session_state_dir" ]]; then
        local lock_files
        lock_files="$(find "$session_state_dir" -name "*.lock" 2>/dev/null | wc -l | tr -d ' ')"
        if [[ "$lock_files" -gt 0 ]]; then
            echo "WARN: $lock_files lock file(s) found" >&2
        fi
    fi

    return 0
}

# Main validation entry point
validate() {
    local errors=0

    validate_pending_work || ((errors++))
    validate_git_state || true  # Non-fatal
    validate_session_state || true  # Non-fatal
    validate_stop_safety || true  # Non-fatal

    return $errors
}

# Run validation if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate "$@"
fi
