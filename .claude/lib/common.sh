#!/usr/bin/env bash
#
# common.sh - Common library entry point
#
# Sources all shared libraries for Claude framework scripts.
# This is the recommended way to include all standard utilities.
#
# Usage:
#   source .claude/lib/common.sh
#
# Included Libraries:
#   - error.sh   - Error handling (die, warn, trap_error)
#   - logging.sh - Logging (log_info, log_warn, log_error, log_debug)
#   - testing.sh - Testing (assert_eq, assert_file_exists, assert_command_success)
#

# Prevent multiple sourcing
[[ -n "${_COMMON_SH_LOADED:-}" ]] && return 0
_COMMON_SH_LOADED=1

# Determine library directory
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries
source "$LIB_DIR/error.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/testing.sh"

# Export common variables
export REPO_ROOT="${REPO_ROOT:-$(cd "$LIB_DIR/../.." && pwd)}"
export LIB_DIR

# Utility: Get script directory
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
}

# Utility: Check if running in CI environment
is_ci() {
    [[ -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" || -n "${GITLAB_CI:-}" ]]
}
