#!/usr/bin/env bash
#
# error.sh - Error handling library
#
# Provides standardized error handling functions for Claude framework scripts.
#
# Usage:
#   source .claude/lib/error.sh
#
# Functions:
#   die(message, [exit_code]) - Print error and exit
#   warn(message)             - Print warning (non-fatal)
#   trap_error()              - Set up error trap for debugging
#

# Prevent multiple sourcing
[[ -n "${_ERROR_SH_LOADED:-}" ]] && return 0
_ERROR_SH_LOADED=1

# Colors (only if terminal supports it)
if [[ -t 2 ]]; then
    _ERR_RED='\033[0;31m'
    _ERR_YELLOW='\033[0;33m'
    _ERR_NC='\033[0m'
else
    _ERR_RED=''
    _ERR_YELLOW=''
    _ERR_NC=''
fi

# die - Print error message and exit
#
# Arguments:
#   $1 - Error message
#   $2 - Exit code (default: 1)
#
# Example:
#   die "Configuration file not found" 2
#
die() {
    local message="${1:-Unknown error}"
    local exit_code="${2:-1}"

    echo -e "${_ERR_RED}[ERROR]${_ERR_NC} $message" >&2

    # If we have a log file, append there too
    if [[ -n "${LOG_FILE:-}" && -w "${LOG_FILE:-}" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $message" >> "$LOG_FILE"
    fi

    exit "$exit_code"
}

# warn - Print warning message (non-fatal)
#
# Arguments:
#   $1 - Warning message
#
# Example:
#   warn "File permissions may be incorrect"
#
warn() {
    local message="${1:-Unknown warning}"

    echo -e "${_ERR_YELLOW}[WARN]${_ERR_NC} $message" >&2

    # If we have a log file, append there too
    if [[ -n "${LOG_FILE:-}" && -w "${LOG_FILE:-}" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $message" >> "$LOG_FILE"
    fi
}

# trap_error - Set up error trap for debugging
#
# Call this at the start of a script to enable detailed error reporting.
# Shows the command that failed and the line number.
#
# Example:
#   source .claude/lib/error.sh
#   trap_error
#
trap_error() {
    trap '_trap_error_handler $? "$BASH_COMMAND" ${LINENO}' ERR
}

# Internal error handler (do not call directly)
_trap_error_handler() {
    local exit_code=$1
    local command="$2"
    local line_number=$3

    echo -e "${_ERR_RED}[ERROR]${_ERR_NC} Command failed with exit code $exit_code" >&2
    echo "  Command: $command" >&2
    echo "  Line: $line_number" >&2
    echo "  Script: ${BASH_SOURCE[1]:-unknown}" >&2

    # If we have a log file, append there too
    if [[ -n "${LOG_FILE:-}" && -w "${LOG_FILE:-}" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Command failed: $command (line $line_number, exit $exit_code)" >> "$LOG_FILE"
    fi
}

# assert - Assert a condition is true
#
# Arguments:
#   $1 - Condition (string to be evaluated)
#   $2 - Error message if condition is false
#
# Example:
#   assert '[[ -f "$config_file" ]]' "Config file not found"
#
assert() {
    local condition="$1"
    local message="${2:-Assertion failed}"

    if ! eval "$condition"; then
        die "Assertion failed: $message"
    fi
}

# ensure_command - Ensure a command is available
#
# Arguments:
#   $1 - Command name
#
# Example:
#   ensure_command jq
#   ensure_command git
#
ensure_command() {
    local cmd="$1"

    if ! command -v "$cmd" &> /dev/null; then
        die "Required command not found: $cmd"
    fi
}
