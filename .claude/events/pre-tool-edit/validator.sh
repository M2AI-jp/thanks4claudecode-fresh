#!/usr/bin/env bash
#
# validator.sh - Input validation for pre-tool-edit event
#
# Purpose: Validate edit/write operations before execution
#

set -euo pipefail

UNIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$UNIT_DIR/../../.." && pwd)"

# Validate file path is within allowed directories
validate_file_path() {
    local file_path="${1:-}"

    if [[ -z "$file_path" ]]; then
        echo "ERROR: File path is required" >&2
        return 1
    fi

    # Normalize path
    local normalized
    normalized="$(realpath -m "$file_path" 2>/dev/null || echo "$file_path")"

    # Check if path is within repository
    if [[ ! "$normalized" == "$REPO_ROOT"* ]]; then
        echo "WARN: File path outside repository: $normalized" >&2
    fi

    return 0
}

# Validate protected files are not being edited
validate_protected_files() {
    local file_path="${1:-}"
    local protected_file="$REPO_ROOT/.claude/protected-files.txt"

    if [[ ! -f "$protected_file" ]]; then
        return 0
    fi

    local filename
    filename="$(basename "$file_path")"

    if grep -qx "$filename" "$protected_file" 2>/dev/null; then
        echo "BLOCK: Protected file: $filename" >&2
        return 1
    fi

    return 0
}

# Validate edit operation context
validate_edit_context() {
    local state_file="$REPO_ROOT/state.md"

    # Check if playbook is active (basic check)
    if [[ -f "$state_file" ]]; then
        if grep -q 'active: null' "$state_file" 2>/dev/null; then
            echo "WARN: No active playbook" >&2
        fi
    fi

    return 0
}

# Main validation entry point
validate() {
    local file_path="${1:-}"
    local errors=0

    validate_file_path "$file_path" || ((errors++))
    validate_protected_files "$file_path" || ((errors++))
    validate_edit_context || true  # Non-fatal

    return $errors
}

# Run validation if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate "$@"
fi
