#!/usr/bin/env bash
#
# telemetry.sh - Event telemetry library
#
# Provides event logging and metric recording for Event Units.
#
# Usage:
#   source .claude/events/lib/telemetry.sh
#
# Functions:
#   log_event(unit, event, [details])  - Log an event occurrence
#   record_metric(name, value, [tags]) - Record a metric value
#   start_timer(name)                  - Start timing an operation
#   stop_timer(name)                   - Stop timer and record duration
#

# Prevent multiple sourcing
[[ -n "${_TELEMETRY_SH_LOADED:-}" ]] && return 0
_TELEMETRY_SH_LOADED=1

# Configuration
TELEMETRY_DIR="${TELEMETRY_DIR:-${REPO_ROOT:-.}/.claude/logs/telemetry}"
TELEMETRY_LOG="${TELEMETRY_LOG:-$TELEMETRY_DIR/events.jsonl}"
TELEMETRY_ENABLED="${TELEMETRY_ENABLED:-true}"

# Ensure telemetry directory exists
_ensure_telemetry_dir() {
    if [[ ! -d "$TELEMETRY_DIR" ]]; then
        mkdir -p "$TELEMETRY_DIR" 2>/dev/null || true
    fi
}

# Internal timestamp function
_timestamp() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

# log_event - Log an event occurrence
#
# Arguments:
#   $1 - Unit name (e.g., "session-start", "pre-tool-edit")
#   $2 - Event type (e.g., "initialized", "blocked", "completed")
#   $3 - Additional details (optional, JSON object)
#
# Example:
#   log_event "session-start" "initialized"
#   log_event "pre-tool-edit" "blocked" '{"file": "CLAUDE.md", "reason": "protected"}'
#
log_event() {
    [[ "$TELEMETRY_ENABLED" != "true" ]] && return 0

    local unit="${1:-unknown}"
    local event="${2:-unknown}"
    local details="${3:-{}}"

    _ensure_telemetry_dir

    local timestamp
    timestamp="$(_timestamp)"

    # Create JSON log entry
    local entry
    entry=$(cat <<EOF
{"timestamp":"$timestamp","unit":"$unit","event":"$event","details":$details}
EOF
)

    # Append to log file
    echo "$entry" >> "$TELEMETRY_LOG" 2>/dev/null || true

    # Also output to stderr if debug mode
    if [[ "${TELEMETRY_DEBUG:-}" == "true" ]]; then
        echo "[TELEMETRY] $unit: $event" >&2
    fi
}

# record_metric - Record a metric value
#
# Arguments:
#   $1 - Metric name (e.g., "execution_time", "file_count")
#   $2 - Metric value (number)
#   $3 - Tags (optional, JSON object)
#
# Example:
#   record_metric "execution_time" "1.5" '{"unit": "seconds"}'
#   record_metric "files_processed" "10"
#
record_metric() {
    [[ "$TELEMETRY_ENABLED" != "true" ]] && return 0

    local name="${1:-unknown}"
    local value="${2:-0}"
    local tags="${3:-{}}"

    _ensure_telemetry_dir

    local timestamp
    timestamp="$(_timestamp)"

    local entry
    entry=$(cat <<EOF
{"timestamp":"$timestamp","type":"metric","name":"$name","value":$value,"tags":$tags}
EOF
)

    echo "$entry" >> "$TELEMETRY_LOG" 2>/dev/null || true
}

# Associative array for timer storage
declare -gA _TIMERS 2>/dev/null || true

# start_timer - Start timing an operation
#
# Arguments:
#   $1 - Timer name
#
# Example:
#   start_timer "validation"
#   # ... do validation ...
#   stop_timer "validation"
#
start_timer() {
    local name="${1:-default}"

    if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_VERSION%%.*}" -ge 4 ]]; then
        _TIMERS["$name"]="$(date +%s%3N 2>/dev/null || date +%s)000"
    else
        # Fallback for bash < 4
        export "_TIMER_$name=$(date +%s)"
    fi
}

# stop_timer - Stop timer and record duration
#
# Arguments:
#   $1 - Timer name
#
# Returns:
#   Echoes duration in milliseconds
#
# Example:
#   duration=$(stop_timer "validation")
#   echo "Validation took ${duration}ms"
#
stop_timer() {
    local name="${1:-default}"
    local start_time
    local end_time
    local duration

    end_time="$(date +%s%3N 2>/dev/null || echo "$(date +%s)000")"

    if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_VERSION%%.*}" -ge 4 ]]; then
        start_time="${_TIMERS[$name]:-$end_time}"
        unset "_TIMERS[$name]"
    else
        local var_name="_TIMER_$name"
        start_time="${!var_name:-${end_time%???}}"
        start_time="${start_time}000"
        unset "$var_name"
    fi

    duration=$((end_time - start_time))

    # Record as metric
    record_metric "${name}_duration_ms" "$duration"

    echo "$duration"
}

# get_event_count - Get count of events for a unit
#
# Arguments:
#   $1 - Unit name
#   $2 - Time period (optional, e.g., "1h", "1d")
#
# Example:
#   count=$(get_event_count "session-start")
#
get_event_count() {
    local unit="${1:-}"
    local period="${2:-}"

    if [[ ! -f "$TELEMETRY_LOG" ]]; then
        echo "0"
        return
    fi

    local count
    count=$(grep -c "\"unit\":\"$unit\"" "$TELEMETRY_LOG" 2>/dev/null || echo "0")
    echo "$count"
}

# cleanup_telemetry - Archive old telemetry logs
#
# Arguments:
#   $1 - Days to keep (default: 7)
#
cleanup_telemetry() {
    local days_to_keep="${1:-7}"

    if [[ ! -d "$TELEMETRY_DIR" ]]; then
        return 0
    fi

    # Archive old logs
    find "$TELEMETRY_DIR" -name "*.jsonl" -mtime "+$days_to_keep" \
        -exec gzip {} \; 2>/dev/null || true
}
