#!/usr/bin/env bash
#
# logging.sh - Logging library
#
# Provides standardized logging functions for Claude framework scripts.
#
# Usage:
#   source .claude/lib/logging.sh
#
# Functions:
#   log_info(message)  - Log informational message
#   log_warn(message)  - Log warning message
#   log_error(message) - Log error message
#   log_debug(message) - Log debug message (only if LOG_LEVEL=debug)
#
# Environment Variables:
#   LOG_LEVEL - Set to "debug" to enable debug messages (default: info)
#   LOG_FILE  - Path to log file (optional, logs to stderr by default)
#

# Prevent multiple sourcing
[[ -n "${_LOGGING_SH_LOADED:-}" ]] && return 0
_LOGGING_SH_LOADED=1

# Default log level
LOG_LEVEL="${LOG_LEVEL:-info}"

# Colors (only if terminal supports it)
if [[ -t 2 ]]; then
    _LOG_RED='\033[0;31m'
    _LOG_GREEN='\033[0;32m'
    _LOG_YELLOW='\033[0;33m'
    _LOG_BLUE='\033[0;34m'
    _LOG_GRAY='\033[0;90m'
    _LOG_NC='\033[0m'
else
    _LOG_RED=''
    _LOG_GREEN=''
    _LOG_YELLOW=''
    _LOG_BLUE=''
    _LOG_GRAY=''
    _LOG_NC=''
fi

# Internal logging function
_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    # Output to stderr
    echo -e "${color}[$level]${_LOG_NC} $message" >&2

    # Also output to log file if specified
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[$timestamp] $level: $message" >> "$LOG_FILE"
    fi
}

# log_info - Log informational message
#
# Arguments:
#   $1 - Message to log
#
# Example:
#   log_info "Starting validation..."
#
log_info() {
    _log "INFO" "$_LOG_GREEN" "$1"
}

# log_warn - Log warning message
#
# Arguments:
#   $1 - Message to log
#
# Example:
#   log_warn "Configuration may be incomplete"
#
log_warn() {
    _log "WARN" "$_LOG_YELLOW" "$1"
}

# log_error - Log error message
#
# Arguments:
#   $1 - Message to log
#
# Example:
#   log_error "Failed to connect to database"
#
log_error() {
    _log "ERROR" "$_LOG_RED" "$1"
}

# log_debug - Log debug message (only if LOG_LEVEL=debug)
#
# Arguments:
#   $1 - Message to log
#
# Example:
#   log_debug "Variable value: $var"
#
log_debug() {
    if [[ "${LOG_LEVEL:-info}" == "debug" ]]; then
        _log "DEBUG" "$_LOG_GRAY" "$1"
    fi
}

# log_section - Log a section header
#
# Arguments:
#   $1 - Section title
#
# Example:
#   log_section "Phase 1: Initialization"
#
log_section() {
    local title="$1"
    echo "" >&2
    echo -e "${_LOG_BLUE}=== $title ===${_LOG_NC}" >&2

    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "" >> "$LOG_FILE"
        echo "=== $title ===" >> "$LOG_FILE"
    fi
}

# log_result - Log a result with PASS/FAIL indicator
#
# Arguments:
#   $1 - Result status (pass/fail)
#   $2 - Message
#
# Example:
#   log_result "pass" "All tests completed"
#   log_result "fail" "3 tests failed"
#
log_result() {
    local status="$1"
    local message="$2"

    if [[ "$status" == "pass" ]]; then
        echo -e "${_LOG_GREEN}[PASS]${_LOG_NC} $message" >&2
    else
        echo -e "${_LOG_RED}[FAIL]${_LOG_NC} $message" >&2
    fi

    if [[ -n "${LOG_FILE:-}" ]]; then
        local timestamp
        timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
        echo "[$timestamp] RESULT: $(echo "$status" | tr '[:lower:]' '[:upper:]') - $message" >> "$LOG_FILE"
    fi
}
