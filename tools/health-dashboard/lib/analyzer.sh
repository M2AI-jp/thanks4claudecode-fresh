#!/bin/bash
# analyzer.sh - Health score analyzer for Repository Health Dashboard
# Analyzes telemetry logs and calculates health scores
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Default log directory
DEFAULT_LOG_DIR="$REPO_ROOT/.claude/logs"

# Source dependencies (collector.sh already sources log-parser.sh)
if [[ -z "${COLLECTOR_SOURCED:-}" ]]; then
    source "$SCRIPT_DIR/collector.sh"
    export COLLECTOR_SOURCED=1
fi

# ANSI color codes
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_RED='\033[0;31m'
COLOR_CYAN='\033[0;36m'
COLOR_BOLD='\033[1m'
COLOR_RESET='\033[0m'

# Event Unit definitions (all 10 units)
declare -a ALL_EVENT_UNITS
ALL_EVENT_UNITS=(
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

# calculate_health_score - Calculate overall health score based on telemetry logs
# Arguments:
#   $1 - Log directory (optional, defaults to DEFAULT_LOG_DIR)
# Output:
#   JSON with health score and breakdown
calculate_health_score() {
    local log_dir="${1:-$DEFAULT_LOG_DIR}"
    
    local total_units=${#ALL_EVENT_UNITS[@]}
    local active_units=0
    local total_entries=0
    local success_entries=0
    local warning_entries=0
    local error_entries=0
    
    for event_type in "${ALL_EVENT_UNITS[@]}"; do
        local log_file="$log_dir/${event_type}.log"
        
        if [[ -f "$log_file" ]]; then
            active_units=$((active_units + 1))
            
            # Count entries by status (handle both JSONL and pretty-printed JSON)
            local entries
            entries=$(jq -s 'length' "$log_file" 2>/dev/null)
            if [[ -z "$entries" ]] || [[ "$entries" == "0" ]]; then
                # Fallback: count by grep for pretty-printed multi-object JSON
                entries=$(grep -c "\"event\": \"$event_type\"" "$log_file" 2>/dev/null || echo "0")
            fi
            total_entries=$((total_entries + entries))
            
            # Count success/warning/error (simple grep to handle both JSONL and pretty-printed)
            local success=0 warning=0 error=0
            local s1 s2 s3 s4 s5
            s1=$(grep -c '"status": "success"' "$log_file" 2>/dev/null) || s1=0
            s2=$(grep -c '"status": "ok"' "$log_file" 2>/dev/null) || s2=0
            s3=$(grep -c '"status": "allowed"' "$log_file" 2>/dev/null) || s3=0
            s4=$(grep -c '"status": "ALLOWED"' "$log_file" 2>/dev/null) || s4=0
            s5=$(grep -c '"status": "recorded"' "$log_file" 2>/dev/null) || s5=0
            success=$((s1 + s2 + s3 + s4 + s5))
            success_entries=$((success_entries + success))

            local w1 w2
            w1=$(grep -c '"status": "warning"' "$log_file" 2>/dev/null) || w1=0
            w2=$(grep -c '"status": "warn"' "$log_file" 2>/dev/null) || w2=0
            warning=$((w1 + w2))
            warning_entries=$((warning_entries + warning))

            local e1 e2 e3
            e1=$(grep -c '"status": "error"' "$log_file" 2>/dev/null) || e1=0
            e2=$(grep -c '"status": "blocked"' "$log_file" 2>/dev/null) || e2=0
            e3=$(grep -c '"status": "BLOCKED"' "$log_file" 2>/dev/null) || e3=0
            error=$((e1 + e2 + e3))
            error_entries=$((error_entries + error))
        fi
    done
    
    # Calculate score components
    local unit_coverage_score=0
    if [[ $total_units -gt 0 ]]; then
        unit_coverage_score=$((active_units * 100 / total_units))
    fi
    
    local success_rate=0
    if [[ $total_entries -gt 0 ]]; then
        success_rate=$((success_entries * 100 / total_entries))
    fi
    
    # Overall health score (weighted average)
    # 40% unit coverage + 60% success rate
    local health_score=$(( (unit_coverage_score * 40 + success_rate * 60) / 100 ))
    
    # Output JSON
    cat <<RESULT
{
  "health_score": $health_score,
  "unit_coverage": {
    "active": $active_units,
    "total": $total_units,
    "percentage": $unit_coverage_score
  },
  "entries": {
    "total": $total_entries,
    "success": $success_entries,
    "warning": $warning_entries,
    "error": $error_entries,
    "success_rate": $success_rate
  },
  "log_dir": "$log_dir"
}
RESULT
}

# get_unit_status - Get status for a specific Event Unit
# Arguments:
#   $1 - Event type
#   $2 - Log directory (optional)
# Output:
#   Status string: OK, WARN, ERROR, or MISSING
get_unit_status() {
    local event_type="${1:-}"
    local log_dir="${2:-$DEFAULT_LOG_DIR}"
    
    local log_file="$log_dir/${event_type}.log"
    
    if [[ ! -f "$log_file" ]]; then
        echo "MISSING"
        return
    fi
    
    # Check for errors (simple grep)
    local e1 e2 e3 error_count
    e1=$(grep -c '"status": "error"' "$log_file" 2>/dev/null) || e1=0
    e2=$(grep -c '"status": "blocked"' "$log_file" 2>/dev/null) || e2=0
    e3=$(grep -c '"status": "BLOCKED"' "$log_file" 2>/dev/null) || e3=0
    error_count=$((e1 + e2 + e3))

    if [[ "$error_count" -gt 0 ]]; then
        echo "ERROR"
        return
    fi

    # Check for warnings
    local w1 w2 warning_count
    w1=$(grep -c '"status": "warning"' "$log_file" 2>/dev/null) || w1=0
    w2=$(grep -c '"status": "warn"' "$log_file" 2>/dev/null) || w2=0
    warning_count=$((w1 + w2))

    if [[ "$warning_count" -gt 0 ]]; then
        echo "WARN"
        return
    fi

    echo "OK"
}

# check_all_units - Check status of all Event Units
# Arguments:
#   $1 - Log directory (optional)
# Output:
#   Formatted status for each unit
check_all_units() {
    local log_dir="${1:-$DEFAULT_LOG_DIR}"
    
    echo -e "${COLOR_BOLD}Event Unit Status Check${COLOR_RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-25s %-10s %-15s %s\n" "Unit" "Status" "Entries" "Last Activity"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for event_type in "${ALL_EVENT_UNITS[@]}"; do
        local log_file="$log_dir/${event_type}.log"
        local status
        status=$(get_unit_status "$event_type" "$log_dir")
        
        local entry_count=0
        local last_activity="N/A"
        
        if [[ -f "$log_file" ]]; then
            # Handle both JSONL and pretty-printed JSON
            entry_count=$(jq -s 'length' "$log_file" 2>/dev/null)
            if [[ -z "$entry_count" ]] || [[ "$entry_count" == "0" ]]; then
                entry_count=$(grep -c "\"event\": \"$event_type\"" "$log_file" 2>/dev/null || echo "0")
            fi
            last_activity=$(jq -rs 'last | .timestamp // "unknown"' "$log_file" 2>/dev/null | cut -c1-19 || echo "unknown")
            if [[ "$last_activity" == "unknown" ]] || [[ -z "$last_activity" ]]; then
                last_activity=$(grep '"timestamp":' "$log_file" 2>/dev/null | tail -1 | sed 's/.*"timestamp": *"\([^"]*\)".*/\1/' | cut -c1-19 || echo "unknown")
            fi
        fi
        
        # Color code the status
        local status_colored
        case "$status" in
            OK)
                status_colored="${COLOR_GREEN}[OK]${COLOR_RESET}"
                ;;
            WARN)
                status_colored="${COLOR_YELLOW}[WARN]${COLOR_RESET}"
                ;;
            ERROR)
                status_colored="${COLOR_RED}[ERROR]${COLOR_RESET}"
                ;;
            MISSING)
                status_colored="${COLOR_YELLOW}[MISSING]${COLOR_RESET}"
                ;;
        esac
        
        printf "%-25s %-20b %-15s %s\n" "$event_type" "$status_colored" "$entry_count" "$last_activity"
    done
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# generate_summary - Generate a summary report
# Arguments:
#   $1 - Log directory (optional)
# Output:
#   Formatted summary with health score
generate_summary() {
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
    
    local success_rate
    success_rate=$(echo "$health_data" | jq -r '.entries.success_rate')
    
    # Determine health status color
    local health_color
    if [[ $health_score -ge 80 ]]; then
        health_color="$COLOR_GREEN"
    elif [[ $health_score -ge 50 ]]; then
        health_color="$COLOR_YELLOW"
    else
        health_color="$COLOR_RED"
    fi
    
    echo ""
    echo -e "${COLOR_BOLD}╔═══════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_BOLD}║         Repository Health Dashboard Summary           ║${COLOR_RESET}"
    echo -e "${COLOR_BOLD}╚═══════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo ""
    echo -e "  ${COLOR_BOLD}Health Score:${COLOR_RESET} ${health_color}${health_score}%${COLOR_RESET}"
    echo ""
    echo -e "  ${COLOR_CYAN}Event Units:${COLOR_RESET}"
    echo -e "    Active: ${active_units}/${total_units} (${unit_percentage}%)"
    echo ""
    echo -e "  ${COLOR_CYAN}Telemetry Entries:${COLOR_RESET}"
    echo -e "    Total:   ${total_entries}"
    echo -e "    Success: ${success_entries} (${success_rate}%)"
    echo ""
    echo -e "  ${COLOR_CYAN}Log Directory:${COLOR_RESET}"
    echo -e "    ${log_dir}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Export functions
export -f calculate_health_score
export -f get_unit_status
export -f check_all_units
export -f generate_summary

# If script is run directly, show health score
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 [log_directory]"
        echo ""
        echo "Analyzes telemetry logs and calculates health score."
        echo ""
        echo "Functions available:"
        echo "  calculate_health_score  - Get JSON health score data"
        echo "  get_unit_status         - Get status for specific unit"
        echo "  check_all_units         - Check all Event Units"
        echo "  generate_summary        - Generate formatted summary"
        exit 0
    fi
    
    calculate_health_score "$1"
fi
