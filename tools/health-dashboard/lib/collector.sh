#!/bin/bash
# collector.sh - Telemetry log collector for Health Dashboard
# Collects all telemetry logs from the logs directory
# Compatible with bash 3.2+
set -euo pipefail

# Get repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Default log directory (relative to repo root)
LOGS_SUBDIR=".claude/logs"
DEFAULT_LOG_DIR="$REPO_ROOT/$LOGS_SUBDIR"

# Source log-parser for event types
if [[ -f "$SCRIPT_DIR/log-parser.sh" ]]; then
    source "$SCRIPT_DIR/log-parser.sh"
fi

# Event types and their corresponding log files (bash 3.2 compatible)
readonly ALL_EVENT_TYPES="session-start user-prompt-submit pre-tool-edit pre-tool-bash post-tool-edit subagent-stop pre-compact notification stop session-end"

# get_log_filename - Get log filename for an event type
# Arguments:
#   $1 - Event type
# Output:
#   Log filename
get_log_filename() {
    local event_type="$1"
    echo "${event_type}.log"
}

# collect_all_logs - Collect all telemetry logs from the log directory
# Arguments:
#   $1 - Log directory path (optional, defaults to .claude/logs)
# Output:
#   JSON array with log file info and statistics
collect_all_logs() {
    local log_dir="${1:-$DEFAULT_LOG_DIR}"
    
    if [[ ! -d "$log_dir" ]]; then
        echo '{"error":"log_directory_not_found","path":"'"$log_dir"'"}'
        return 1
    fi
    
    local result='{"logs":['
    local first=true
    
    for event_type in $ALL_EVENT_TYPES; do
        local log_filename
        log_filename=$(get_log_filename "$event_type")
        local log_file="$log_dir/$log_filename"
        local exists=false
        local entry_count=0
        local file_size=0
        local last_modified=0
        
        if [[ -f "$log_file" ]]; then
            exists=true
            # Count JSON objects (handle both pretty-printed and JSONL)
            entry_count=$(jq -s 'if type == "array" then length else 1 end' "$log_file" 2>/dev/null || echo "0")
            file_size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo "0")
            last_modified=$(stat -f%m "$log_file" 2>/dev/null || stat -c%Y "$log_file" 2>/dev/null || echo "0")
        fi
        
        if [[ "$first" == "true" ]]; then
            first=false
        else
            result+=","
        fi
        
        result+='{"event_type":"'"$event_type"'"'
        result+=',"file":"'"$log_filename"'"'
        result+=',"exists":'"$exists"
        result+=',"entry_count":'"$entry_count"
        result+=',"file_size":'"$file_size"
        result+=',"last_modified":'"$last_modified"
        result+='}'
    done
    
    result+='],"log_dir":"'"$log_dir"'"}'
    echo "$result"
}

# get_log_file_path - Get the log file path for an event type
# Arguments:
#   $1 - Event type
#   $2 - Log directory (optional)
# Output:
#   Full path to the log file
get_log_file_path() {
    local event_type="${1:-}"
    local log_dir="${2:-$DEFAULT_LOG_DIR}"
    
    if [[ -z "$event_type" ]]; then
        echo "Error: No event type specified" >&2
        return 1
    fi
    
    # Validate event type
    local valid=false
    for et in $ALL_EVENT_TYPES; do
        if [[ "$et" == "$event_type" ]]; then
            valid=true
            break
        fi
    done
    
    if [[ "$valid" != "true" ]]; then
        echo "Error: Unknown event type: $event_type" >&2
        return 1
    fi
    
    echo "$log_dir/$(get_log_filename "$event_type")"
}

# check_log_exists - Check if a log file exists for an event type
# Arguments:
#   $1 - Event type
#   $2 - Log directory (optional)
# Returns:
#   0 if exists, 1 if not
check_log_exists() {
    local event_type="${1:-}"
    local log_dir="${2:-$DEFAULT_LOG_DIR}"
    
    local log_path
    log_path=$(get_log_file_path "$event_type" "$log_dir") || return 1
    
    [[ -f "$log_path" ]]
}

# get_all_event_types - Return all event types with log file mappings
# Output:
#   Tab-separated: event_type, log_file
get_all_event_types() {
    for event_type in $ALL_EVENT_TYPES; do
        printf "%s\t%s\n" "$event_type" "$(get_log_filename "$event_type")"
    done
}

# collect_logs_by_session - Collect all log entries for a specific session
# Arguments:
#   $1 - Session ID
#   $2 - Log directory (optional)
# Output:
#   All log entries for the session (JSONL format)
collect_logs_by_session() {
    local session_id="${1:-}"
    local log_dir="${2:-$DEFAULT_LOG_DIR}"
    
    if [[ -z "$session_id" ]]; then
        echo "Error: No session ID specified" >&2
        return 1
    fi
    
    for event_type in $ALL_EVENT_TYPES; do
        local log_file="$log_dir/$(get_log_filename "$event_type")"
        if [[ -f "$log_file" ]]; then
            jq -sc "[if type == \"array\" then .[] else . end | select(.session_id == \"$session_id\")][]" "$log_file" 2>/dev/null || true
        fi
    done
}

# get_summary_stats - Get summary statistics across all logs
# Arguments:
#   $1 - Log directory (optional)
# Output:
#   JSON with summary stats
get_summary_stats() {
    local log_dir="${1:-$DEFAULT_LOG_DIR}"
    
    local total_entries=0
    local total_files=0
    local existing_files=0
    local total_size=0
    
    for event_type in $ALL_EVENT_TYPES; do
        local log_file="$log_dir/$(get_log_filename "$event_type")"
        total_files=$((total_files + 1))
        
        if [[ -f "$log_file" ]]; then
            existing_files=$((existing_files + 1))
            local entries
            entries=$(jq -s 'if type == "array" then length else 1 end' "$log_file" 2>/dev/null || echo "0")
            total_entries=$((total_entries + entries))
            
            local size
            size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo "0")
            total_size=$((total_size + size))
        fi
    done
    
    cat <<STATS
{
  "total_event_types": $total_files,
  "existing_log_files": $existing_files,
  "total_entries": $total_entries,
  "total_size_bytes": $total_size,
  "log_dir": "$log_dir"
}
STATS
}

# Export functions
export -f get_log_filename
export -f collect_all_logs
export -f get_log_file_path
export -f check_log_exists
export -f get_all_event_types
export -f collect_logs_by_session
export -f get_summary_stats

# If script is run directly, show collected logs
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 [log_directory]"
        echo ""
        echo "Collects all telemetry logs and outputs JSON summary."
        echo ""
        echo "Event types and log files:"
        get_all_event_types | sed 's/^/  /'
        exit 0
    fi
    
    collect_all_logs "${1:-}"
fi
