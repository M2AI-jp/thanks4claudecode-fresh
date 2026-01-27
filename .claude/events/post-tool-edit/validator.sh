#!/usr/bin/env bash
#
# validator.sh - Input validation for post-tool-edit event
#
# Purpose: Validate state after edit operation completes
#

set -euo pipefail

UNIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$UNIT_DIR/../../.." && pwd)"

# Validate file was actually modified
validate_file_modified() {
    local file_path="${1:-}"

    if [[ -z "$file_path" ]]; then
        echo "WARN: No file path provided" >&2
        return 0
    fi

    if [[ ! -f "$file_path" ]]; then
        echo "WARN: File does not exist after edit: $file_path" >&2
        return 1
    fi

    return 0
}

# Validate edit result integrity
validate_edit_integrity() {
    local file_path="${1:-}"

    if [[ -z "$file_path" ]]; then
        return 0
    fi

    # Check file is not empty (unless it should be)
    if [[ -f "$file_path" && ! -s "$file_path" ]]; then
        echo "WARN: File is empty after edit: $file_path" >&2
    fi

    # Check file has valid syntax if it's a known format
    local extension="${file_path##*.}"
    case "$extension" in
        json)
            if ! jq empty "$file_path" 2>/dev/null; then
                echo "ERROR: Invalid JSON after edit: $file_path" >&2
                return 1
            fi
            ;;
        sh)
            if ! bash -n "$file_path" 2>/dev/null; then
                echo "ERROR: Invalid bash syntax after edit: $file_path" >&2
                return 1
            fi
            ;;
    esac

    return 0
}

# Validate playbook-related file changes
validate_playbook_edit() {
    local file_path="${1:-}"

    # Check if this is a playbook file
    if [[ "$file_path" == *"/play/"*"/plan.json" ]]; then
        if ! jq -e '.meta.id' "$file_path" > /dev/null 2>&1; then
            echo "ERROR: Playbook missing meta.id: $file_path" >&2
            return 1
        fi
    fi

    return 0
}

# Main validation entry point
validate() {
    local file_path="${1:-}"
    local errors=0

    validate_file_modified "$file_path" || ((errors++))
    validate_edit_integrity "$file_path" || ((errors++))
    validate_playbook_edit "$file_path" || true  # Non-fatal

    return $errors
}

# Run validation if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate "$@"
fi
