#!/bin/bash
#
# validate-playbook-schema.sh
# Validate playbook JSON against schema rules
#
# Usage:
#   ./validate-playbook-schema.sh <file>      # Validate a file
#   ./validate-playbook-schema.sh --stdin     # Read JSON from stdin
#   ./validate-playbook-schema.sh --help      # Show usage
#

set -euo pipefail

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.2.0"

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

show_usage() {
    cat << 'USAGE_EOF'
Usage: validate-playbook-schema.sh [OPTIONS] [FILE]

Validate playbook JSON against schema rules.

Options:
  --stdin       Read JSON from standard input
  --help        Show this help message and exit
  --version     Show version information

Arguments:
  FILE          Path to the playbook JSON file to validate

Examples:
  validate-playbook-schema.sh plan/playbook-001.json
  cat playbook.json | validate-playbook-schema.sh --stdin
  echo '{"id":"pb-001"}' | validate-playbook-schema.sh --stdin

Exit codes:
  0  Validation passed
  1  Validation failed
  2  Invalid arguments or file not found
USAGE_EOF
}

show_version() {
    echo "${SCRIPT_NAME} version ${VERSION}"
}

error() {
    local error_type="$1"
    shift
    echo "ERROR: [${error_type}] $*" >&2
}

warn() {
    echo "WARN: $*" >&2
}

info() {
    echo "INFO: $*" >&2
}

# Check if jq is available
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        error "DEPENDENCY" "jq is required but not installed"
        exit 2
    fi
}

# Validate JSON syntax
validate_json_syntax() {
    local json_content="$1"
    
    if ! echo "$json_content" | jq . > /dev/null 2>&1; then
        error "SYNTAX" "Invalid JSON syntax"
        return 1
    fi
    return 0
}

# Check FORBIDDEN patterns in criterion field
check_criterion_forbidden() {
    local value="$1"
    local errors=0

    # FORBIDDEN patterns for criterion
    # Note: "存在する" is allowed (state verb) but action verbs are forbidden
    # Action verbs to forbid: テストする, 実装する, 作成する, 修正する, 追加する, 削除する, 更新する, 変更する
    local pattern
    for pattern in 'テストする' '実装する' '作成する' '修正する' '追加する' '削除する' '更新する' '変更する' '確認する' '検証する' 'テストした' '実装した' '作成した' '修正した' '追加した' '削除した' '更新した' '変更した' '確認した' '検証した' '適切' '正しく' '良い'; do
        if echo "$value" | grep -qE "$pattern"; then
            local matched
            matched=$(echo "$value" | grep -oE "$pattern" | head -1)
            error "FORBIDDEN" "パターン '${matched}' が criterion で検出されました: ${value}"
            errors=1
        fi
    done

    echo "$errors"
}

# Check FORBIDDEN patterns in command field
check_command_forbidden() {
    local value="$1"
    local errors=0
    
    # FORBIDDEN patterns for command
    local pattern
    for pattern in '^Execute' '^Compare' '^Review' '^Check'; do
        if echo "$value" | grep -qE "$pattern"; then
            local matched
            matched=$(echo "$value" | grep -oE "$pattern" | head -1)
            error "FORBIDDEN" "パターン '${matched}' が command で検出されました: ${value}"
            errors=1
        fi
    done
    
    echo "$errors"
}

# Check FORBIDDEN patterns in expected field
check_expected_forbidden() {
    local value="$1"
    local errors=0
    
    # FORBIDDEN patterns for expected
    local pattern
    for pattern in '適切' '正常' '正しく' '^All$' '100%'; do
        if echo "$value" | grep -qE "$pattern"; then
            local matched
            matched=$(echo "$value" | grep -oE "$pattern" | head -1)
            error "FORBIDDEN" "パターン '${matched}' が expected で検出されました: ${value}"
            errors=1
        fi
    done
    
    echo "$errors"
}

# Validate FORBIDDEN patterns in done_when
validate_forbidden_patterns() {
    local json_content="$1"
    local errors=0
    
    # Check if done_when exists
    local done_when_count
    done_when_count=$(echo "$json_content" | jq '.done_when // [] | length')
    
    if [ "$done_when_count" -eq 0 ]; then
        echo "0"
        return 0
    fi
    
    # Iterate through each done_when entry
    for i in $(seq 0 $((done_when_count - 1))); do
        local criterion command expected
        criterion=$(echo "$json_content" | jq -r ".done_when[$i].criterion // empty")
        command=$(echo "$json_content" | jq -r ".done_when[$i].command // empty")
        expected=$(echo "$json_content" | jq -r ".done_when[$i].expected // empty")
        
        # Check criterion FORBIDDEN patterns
        if [ -n "$criterion" ]; then
            local criterion_errors
            criterion_errors=$(check_criterion_forbidden "$criterion")
            errors=$((errors + criterion_errors))
        fi
        
        # Check command FORBIDDEN patterns
        if [ -n "$command" ]; then
            local command_errors
            command_errors=$(check_command_forbidden "$command")
            errors=$((errors + command_errors))
        fi
        
        # Check expected FORBIDDEN patterns
        if [ -n "$expected" ]; then
            local expected_errors
            expected_errors=$(check_expected_forbidden "$expected")
            errors=$((errors + expected_errors))
        fi
    done
    
    echo "$errors"
}

# Validate done_when entries have criterion, command, expected
validate_done_when() {
    local json_content="$1"
    local errors=0
    
    # Check if done_when exists
    local done_when_count
    done_when_count=$(echo "$json_content" | jq '.done_when // [] | length')
    
    if [ "$done_when_count" -eq 0 ]; then
        echo "0"
        return 0
    fi
    
    # Iterate through each done_when entry
    for i in $(seq 0 $((done_when_count - 1))); do
        local entry
        entry=$(echo "$json_content" | jq ".done_when[$i]")
        
        # Check for criterion
        if ! echo "$entry" | jq -e '.criterion' > /dev/null 2>&1; then
            error "missing" "フィールド 'criterion' が done_when[$i] に存在しません"
            errors=$((errors + 1))
        fi
        
        # Check for command
        if ! echo "$entry" | jq -e '.command' > /dev/null 2>&1; then
            error "missing" "フィールド 'command' が done_when[$i] に存在しません"
            errors=$((errors + 1))
        fi
        
        # Check for expected
        if ! echo "$entry" | jq -e '.expected' > /dev/null 2>&1; then
            error "missing" "フィールド 'expected' が done_when[$i] に存在しません"
            errors=$((errors + 1))
        fi
    done
    
    echo "$errors"
    return 0
}

# Validate validation_plan entries have command, expected for each type
validate_validation_plan() {
    local json_content="$1"
    local errors=0
    
    # Get phases count
    local phases_count
    phases_count=$(echo "$json_content" | jq '.phases // [] | length')
    
    if [ "$phases_count" -eq 0 ]; then
        echo "0"
        return 0
    fi
    
    # Iterate through phases
    for p in $(seq 0 $((phases_count - 1))); do
        local subtasks_count
        subtasks_count=$(echo "$json_content" | jq ".phases[$p].subtasks // [] | length")
        
        if [ "$subtasks_count" -eq 0 ]; then
            continue
        fi
        
        # Iterate through subtasks
        for s in $(seq 0 $((subtasks_count - 1))); do
            local validation_plan
            validation_plan=$(echo "$json_content" | jq ".phases[$p].subtasks[$s].validation_plan // null")
            
            if [ "$validation_plan" = "null" ]; then
                continue
            fi
            
            local location="phases[$p].subtasks[$s]"
            
            # Check each type in validation_plan (technical, consistency, completeness)
            for type in "technical" "consistency" "completeness"; do
                local type_entry
                type_entry=$(echo "$validation_plan" | jq ".$type // null")
                
                if [ "$type_entry" != "null" ]; then
                    # Check for command
                    if ! echo "$type_entry" | jq -e '.command' > /dev/null 2>&1; then
                        error "missing" "フィールド 'command' が ${location}.validation_plan.$type に存在しません"
                        errors=$((errors + 1))
                    fi
                    
                    # Check for expected
                    if ! echo "$type_entry" | jq -e '.expected' > /dev/null 2>&1; then
                        error "missing" "フィールド 'expected' が ${location}.validation_plan.$type に存在しません"
                        errors=$((errors + 1))
                    fi
                fi
            done
        done
    done
    
    echo "$errors"
    return 0
}

# Main validation function
validate_playbook() {
    local json_content="$1"
    local validation_errors=0
    
    # Step 1: Validate JSON syntax
    if ! validate_json_syntax "$json_content"; then
        return 1
    fi
    
    # Step 2: Validate done_when 3-point set (criterion, command, expected)
    local done_when_errors
    done_when_errors=$(validate_done_when "$json_content")
    validation_errors=$((validation_errors + done_when_errors))
    
    # Step 3: Validate validation_plan entries (command, expected)
    local validation_plan_errors
    validation_plan_errors=$(validate_validation_plan "$json_content")
    validation_errors=$((validation_errors + validation_plan_errors))
    
    # Step 4: Validate FORBIDDEN patterns in done_when
    local forbidden_errors
    forbidden_errors=$(validate_forbidden_patterns "$json_content")
    validation_errors=$((validation_errors + forbidden_errors))
    
    if [ "$validation_errors" -eq 0 ]; then
        info "Validation passed"
        return 0
    else
        return 1
    fi
}

# Read JSON from file
read_from_file() {
    local file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        error "FILE_NOT_FOUND" "File does not exist: $file_path"
        exit 2
    fi
    
    if [ ! -r "$file_path" ]; then
        error "FILE_ACCESS" "Cannot read file: $file_path"
        exit 2
    fi
    
    cat "$file_path"
}

# Read JSON from stdin
read_from_stdin() {
    local content=""
    
    if [ -t 0 ]; then
        error "INPUT" "No input provided on stdin"
        exit 2
    fi
    
    content="$(cat)"
    
    if [ -z "$content" ]; then
        error "INPUT" "Empty input received"
        exit 2
    fi
    
    echo "$content"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    local use_stdin=false
    local file_path=""
    local json_content=""
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --stdin)
                use_stdin=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            -*)
                error "ARGUMENT" "Unknown option: $1"
                echo "Use --help for usage information" >&2
                exit 2
                ;;
            *)
                if [ -n "$file_path" ]; then
                    error "ARGUMENT" "Multiple files specified"
                    exit 2
                fi
                file_path="$1"
                shift
                ;;
        esac
    done
    
    # Check dependencies
    check_dependencies
    
    # Determine input source
    if [ "$use_stdin" = true ] && [ -n "$file_path" ]; then
        error "ARGUMENT" "Cannot use both --stdin and file argument"
        exit 2
    fi
    
    if [ "$use_stdin" = false ] && [ -z "$file_path" ]; then
        error "ARGUMENT" "No input specified. Use --stdin or provide a file path"
        echo "Use --help for usage information" >&2
        exit 2
    fi
    
    # Read JSON content
    if [ "$use_stdin" = true ]; then
        json_content="$(read_from_stdin)"
    else
        json_content="$(read_from_file "$file_path")"
    fi
    
    # Run validation
    if validate_playbook "$json_content"; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
