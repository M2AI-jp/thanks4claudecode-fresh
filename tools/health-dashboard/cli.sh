#!/bin/bash
# cli.sh - Repository Health Dashboard CLI
# Main entry point for the health dashboard tool
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library files (analyzer.sh sources collector.sh which sources log-parser.sh)
source "$SCRIPT_DIR/lib/analyzer.sh"

# ANSI color codes
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_RED='\033[0;31m'
COLOR_CYAN='\033[0;36m'
COLOR_BOLD='\033[1m'
COLOR_RESET='\033[0m'

# usage - Display help message
usage() {
    cat << 'USAGE'
Usage: cli.sh [OPTIONS]

Repository Health Dashboard - Analyze telemetry logs and generate health reports.

Options:
  --help, -h      Show this help message
  --summary       Show health summary with Health Score
  --check-units   Check status of all 10 Event Units
  --format FMT    Output format: text, json, yaml (default: text)
  --output FILE   Write output to file instead of stdout

Examples:
  cli.sh --help
  cli.sh --summary
  cli.sh --check-units
  cli.sh --format json --output report.json
USAGE
}

# main - Main entry point
main() {
    local action=""
    local format="text"
    local output=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                usage
                exit 0
                ;;
            --summary)
                action="summary"
                shift
                ;;
            --check-units)
                action="check-units"
                shift
                ;;
            --format)
                format="${2:-text}"
                shift 2
                ;;
            --output)
                output="${2:-}"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                exit 1
                ;;
        esac
    done
    
    # Default action: show help
    if [[ -z "$action" ]]; then
        usage
        exit 0
    fi
    
    # Execute action
    local result=""
    case "$action" in
        summary)
            result=$(generate_summary)
            ;;
        check-units)
            result=$(check_all_units)
            ;;
    esac
    
    # Output result
    if [[ -n "$output" ]]; then
        echo "$result" > "$output"
        echo "Output written to: $output"
    else
        echo "$result"
    fi
}

# Run main function
main "$@"
