#!/bin/bash
# log-parser.sh - Telemetry log parser for Health Dashboard
# Parses JSON/JSONL format logs from telemetry log directory
set -euo pipefail

# Supported Event Unit types
readonly EVENT_TYPES=(
    "session-start"
    "user-prompt-submit"
    "pre-tool-edit"
    "pre-tool-bash"
    "post-tool-edit"
    "subagent-stop"
    "pre-compact"
    "notification"
    "stop"
    "session-end"
)

# parse_telemetry_log - Parse a telemetry log file
# Arguments:
#   $1 - Path to log file (JSON or JSONL format)
# Output:
#   Tab-separated: timestamp, session_id, event, status
parse_telemetry_log() {
    local log_file="${1:-}"
    
    if [[ -z "$log_file" ]]; then
        echo "Error: No log file specified" >&2
        return 1
    fi
    
    if [[ ! -f "$log_file" ]]; then
        echo "Error: Log file not found: $log_file" >&2
        return 1
    fi
    
    # Use jq slurp-input mode to handle both JSONL and pretty-printed JSON
    # The -s flag reads entire file as array, then we iterate
    jq -r '
        if type == "array" then .[] else . end |
        [.timestamp // "unknown", .session_id // "unknown", .event // "unknown", .status // "unknown"] |
        @tsv
    ' "$log_file" 2>/dev/null || {
        # Fallback: try line-by-line parsing for JSONL
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" ]] && continue
            echo "$line" | jq -r '[.timestamp // "unknown", .session_id // "unknown", .event // "unknown", .status // "unknown"] | @tsv' 2>/dev/null || true
        done < "$log_file"
    }
}

# parse_log_entry - Parse a single JSON log entry
# Arguments:
#   $1 - JSON string
# Output:
#   Tab-separated: timestamp, session_id, event, status
parse_log_entry() {
    local json_line="${1:-}"
    
    if [[ -z "$json_line" ]]; then
        return 1
    fi
    
    echo "$json_line" | jq -r '[.timestamp // "unknown", .session_id // "unknown", .event // "unknown", .status // "unknown"] | @tsv' 2>/dev/null
}

# get_event_types - Return all supported event types
get_event_types() {
    printf "%s
" "${EVENT_TYPES[@]}"
}

# is_valid_event_type - Check if event type is valid
# Arguments:
#   $1 - Event type to check
# Returns:
#   0 if valid, 1 if invalid
is_valid_event_type() {
    local event_type="${1:-}"
    local type
    for type in "${EVENT_TYPES[@]}"; do
        if [[ "$type" == "$event_type" ]]; then
            return 0
        fi
    done
    return 1
}

# count_events_by_type - Count events of a specific type in a log file
# Arguments:
#   $1 - Log file path
#   $2 - Event type (optional, counts all if not specified)
# Output:
#   Number of matching events
count_events_by_type() {
    local log_file="${1:-}"
    local event_type="${2:-}"
    
    if [[ ! -f "$log_file" ]]; then
        echo "0"
        return
    fi
    
    if [[ -z "$event_type" ]]; then
        # Count all events
        jq -s 'if type == "array" then length else 1 end' "$log_file" 2>/dev/null || echo "0"
    else
        # Count specific event type
        jq -s "[if type == "array" then .[] else . end | select(.event == "$event_type")] | length" "$log_file" 2>/dev/null || echo "0"
    fi
}

# get_log_stats - Get statistics for a log file
# Arguments:
#   $1 - Log file path
# Output:
#   JSON with stats: total_entries, unique_sessions, event_counts
get_log_stats() {
    local log_file="${1:-}"
    
    if [[ ! -f "$log_file" ]]; then
        echo '{"error":"file_not_found"}'
        return 1
    fi
    
    jq -s '
        (if type == "array" then . else [.] end) as $entries |
        {
            total_entries: ($entries | length),
            unique_sessions: ([$entries[].session_id] | unique | length),
            first_timestamp: ($entries | first | .timestamp // "unknown"),
            last_timestamp: ($entries | last | .timestamp // "unknown")
        }
    ' "$log_file" 2>/dev/null || echo '{"error":"parse_error"}'
}

# Export functions for use in other scripts
export -f parse_telemetry_log
export -f parse_log_entry
export -f get_event_types
export -f is_valid_event_type
export -f count_events_by_type
export -f get_log_stats

# If script is run directly, show usage or run test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <log_file>"
        echo ""
        echo "Parses JSON/JSONL telemetry log files and outputs tab-separated values:"
        echo "  timestamp  session_id  event  status"
        echo ""
        echo "Supported event types:"
        get_event_types | sed 's/^/  - /'
        exit 0
    fi
    
    parse_telemetry_log "$1"
fi
