#!/bin/bash
# formatter.sh - Output formatters for Repository Health Dashboard
# Provides JSON and YAML output formatting functions
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
if [[ -z "${ANALYZER_SOURCED:-}" ]]; then
    source "$SCRIPT_DIR/analyzer.sh"
    export ANALYZER_SOURCED=1
fi

# ANSI color stripping for clean output
strip_colors() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# format_json - Generate JSON format report
# Arguments:
#   $1 - Log directory (optional)
# Output:
#   JSON formatted health report
format_json() {
    local log_dir="${1:-$DEFAULT_LOG_DIR}"
    
    # Get health score data
    local health_data
    health_data=$(calculate_health_score "$log_dir")
    
    local health_score
    health_score=$(echo "$health_data" | jq -r '.health_score')
    
    local unit_coverage
    unit_coverage=$(echo "$health_data" | jq -r '.unit_coverage')
    
    local entries
    entries=$(echo "$health_data" | jq -r '.entries')
    
    # Build event_units array
    local event_units_json="["
    local first=true
    
    for event_type in "${ALL_EVENT_UNITS[@]}"; do
        local status
        status=$(get_unit_status "$event_type" "$log_dir")
        
        local log_file="$log_dir/${event_type}.log"
        local entry_count=0
        local last_timestamp="null"
        
        if [[ -f "$log_file" ]]; then
            entry_count=$(jq -s 'length' "$log_file" 2>/dev/null || echo "0")
            last_timestamp=$(jq -rs 'last | .timestamp // null' "$log_file" 2>/dev/null || echo "null")
            if [[ "$last_timestamp" != "null" ]]; then
                last_timestamp="\"$last_timestamp\""
            fi
        fi
        
        if [[ "$first" == "true" ]]; then
            first=false
        else
            event_units_json+=","
        fi
        
        event_units_json+="{\"name\":\"$event_type\",\"status\":\"$status\",\"entries\":$entry_count,\"last_activity\":$last_timestamp}"
    done
    
    event_units_json+="]"
    
    # Generate timestamp
    local generated_at
    generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Build final JSON
    cat << RESULT | jq .
{
  "health_score": $health_score,
  "generated_at": "$generated_at",
  "log_dir": "$log_dir",
  "unit_coverage": $unit_coverage,
  "entries": $entries,
  "event_units": $event_units_json
}
RESULT
}

# format_yaml - Generate YAML format report
# Arguments:
#   $1 - Log directory (optional)
# Output:
#   YAML formatted health report
format_yaml() {
    local log_dir="${1:-$DEFAULT_LOG_DIR}"
    
    # Get health score data
    local health_data
    health_data=$(calculate_health_score "$log_dir")
    
    local health_score
    health_score=$(echo "$health_data" | jq -r '.health_score')
    
    local active_units
    active_units=$(echo "$health_data" | jq -r '.unit_coverage.active')
    
    local total_units
    total_units=$(echo "$health_data" | jq -r '.unit_coverage.total')
    
    local unit_percentage
    unit_percentage=$(echo "$health_data" | jq -r '.unit_coverage.percentage')
    
    local total_entries
    total_entries=$(echo "$health_data" | jq -r '.entries.total')
    
    local success_entries
    success_entries=$(echo "$health_data" | jq -r '.entries.success')
    
    local warning_entries
    warning_entries=$(echo "$health_data" | jq -r '.entries.warning')
    
    local error_entries
    error_entries=$(echo "$health_data" | jq -r '.entries.error')
    
    local success_rate
    success_rate=$(echo "$health_data" | jq -r '.entries.success_rate')
    
    # Generate timestamp
    local generated_at
    generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Output YAML
    cat << YAML
health_score: $health_score
generated_at: "$generated_at"
log_dir: "$log_dir"

unit_coverage:
  active: $active_units
  total: $total_units
  percentage: $unit_percentage

entries:
  total: $total_entries
  success: $success_entries
  warning: $warning_entries
  error: $error_entries
  success_rate: $success_rate

event_units:
YAML

    # Add event units
    for event_type in "${ALL_EVENT_UNITS[@]}"; do
        local status
        status=$(get_unit_status "$event_type" "$log_dir")
        
        local log_file="$log_dir/${event_type}.log"
        local entry_count=0
        local last_timestamp="null"
        
        if [[ -f "$log_file" ]]; then
            entry_count=$(jq -s 'length' "$log_file" 2>/dev/null || echo "0")
            last_timestamp=$(jq -rs 'last | .timestamp // "null"' "$log_file" 2>/dev/null || echo "null")
        fi
        
        cat << UNIT
  - name: "$event_type"
    status: "$status"
    entries: $entry_count
    last_activity: "$last_timestamp"
UNIT
    done
}

# format_text - Generate text format report (wrapper for generate_summary)
# Arguments:
#   $1 - Log directory (optional)
# Output:
#   Text formatted health report
format_text() {
    local log_dir="${1:-$DEFAULT_LOG_DIR}"
    generate_summary "$log_dir"
}

# Export functions
export -f strip_colors
export -f format_json
export -f format_yaml
export -f format_text

# If script is run directly, show usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Usage: source $0"
    echo ""
    echo "Output formatter functions for Health Dashboard."
    echo ""
    echo "Functions available:"
    echo "  format_json  - Generate JSON format report"
    echo "  format_yaml  - Generate YAML format report"
    echo "  format_text  - Generate text format report"
    exit 0
fi
