#!/bin/bash
set -euo pipefail

# Session Start Hook - Component Status Summary
# Displays lightweight summary of Hooks, Skills, and SubAgents

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SETTINGS_FILE="$REPO_ROOT/.claude/settings.json"
SKILLS_DIR="$REPO_ROOT/.claude/skills"

# Count registered hooks from settings.json
count_hooks() {
    local hook_count=0
    local missing_count=0
    
    if [[ -f "$SETTINGS_FILE" ]]; then
        # Extract hook commands and count unique script files
        local hook_scripts
        hook_scripts=$(grep -o '"command": *"bash [^"]*"' "$SETTINGS_FILE" 2>/dev/null | \
                       sed 's/"command": *"bash \(.*\)"/\1/' | sort -u)
        
        while IFS= read -r script; do
            [[ -z "$script" ]] && continue
            ((hook_count++))
            if [[ ! -f "$REPO_ROOT/$script" ]]; then
                ((missing_count++))
            fi
        done <<< "$hook_scripts"
    fi
    
    local ok_count=$((hook_count - missing_count))
    echo "$hook_count $ok_count $missing_count"
}

# Count skills (directories with SKILL.md)
count_skills() {
    local skill_count=0
    local with_skillmd=0
    
    if [[ -d "$SKILLS_DIR" ]]; then
        for dir in "$SKILLS_DIR"/*/; do
            [[ -d "$dir" ]] || continue
            ((skill_count++))
            if [[ -f "${dir}SKILL.md" ]]; then
                ((with_skillmd++))
            fi
        done
    fi
    
    echo "$skill_count $with_skillmd"
}

# Count SubAgents (agents/*.md files)
count_subagents() {
    local agent_count=0
    
    if [[ -d "$SKILLS_DIR" ]]; then
        agent_count=$(find "$SKILLS_DIR" -path "*/agents/*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    echo "$agent_count"
}

# Run coherence checker and display results
run_coherence_check() {
    local check_script="$REPO_ROOT/.claude/skills/coherence-checker/scripts/check.sh"

    if [[ ! -f "$check_script" ]]; then
        echo "  [Coherence] check.sh not found, skipping"
        return 0
    fi

    # Run check.sh and capture output
    local output
    if ! output=$(bash "$check_script" 2>/dev/null); then
        echo "  [Coherence] check.sh failed to execute"
        return 0
    fi

    # Parse summary counts from YAML output
    local verified inconsistent missing
    verified=$(echo "$output" | grep -E '^\s+verified:' | head -1 | sed 's/.*: *//')
    inconsistent=$(echo "$output" | grep -E '^\s+inconsistent:' | head -1 | sed 's/.*: *//')
    missing=$(echo "$output" | grep -E '^\s+missing:' | head -1 | sed 's/.*: *//')

    # Default to 0 if not found
    verified=${verified:-0}
    inconsistent=${inconsistent:-0}
    missing=${missing:-0}

    # Display summary
    echo "[SessionStart] Coherence Check"
    echo "  verified: $verified, inconsistent: $inconsistent, missing: $missing"

    # If there are problems, show details
    if [[ "$inconsistent" -gt 0 ]] || [[ "$missing" -gt 0 ]]; then
        echo ""
        echo "  [WARNING] Documentation/Implementation mismatch detected:"

        # Show inconsistent items (documented but not implemented)
        if [[ "$inconsistent" -gt 0 ]]; then
            echo "    Inconsistent (documented but not implemented):"
            echo "$output" | grep -B1 'status: inconsistent' | grep -E 'file:|dir:' | while read -r line; do
                local item
                item=$(echo "$line" | sed 's/.*: *"\([^"]*\)".*/\1/')
                echo "      - $item"
            done
        fi

        # Show missing items (implemented but not documented)
        if [[ "$missing" -gt 0 ]]; then
            echo "    Missing (implemented but not documented):"
            echo "$output" | grep -B1 'status: missing' | grep -E 'file:|dir:' | while read -r line; do
                local item
                item=$(echo "$line" | sed 's/.*: *"\([^"]*\)".*/\1/')
                echo "      - $item"
            done
        fi

        echo ""
        echo "  Run 'bash .claude/skills/coherence-checker/scripts/check.sh' for full report"
        echo "  Run 'bash .claude/skills/coherence-checker/scripts/apply-fixes.sh' to fix missing docs"
    fi
}

# Cleanup stale pending file from previous session (prevents deadlock)
# See: fix/post-loop-pending-deadlock
# Reason: pending's lifetime is session-scoped, not cross-session
cleanup_stale_pending() {
    local pending_file="$REPO_ROOT/.claude/session-state/post-loop-pending"

    if [[ -f "$pending_file" ]]; then
        echo "[SessionStart] Cleaning up stale post-loop-pending file"
        echo "  (Previous session did not complete post-loop)"
        rm -f "$pending_file"
        echo "  Removed: $pending_file"
        echo ""
    fi
}

# Main output
main() {
    # First: cleanup stale pending to prevent deadlock
    cleanup_stale_pending

    read -r hook_total hook_ok hook_missing <<< "$(count_hooks)"
    read -r skill_total skill_with_md <<< "$(count_skills)"
    subagent_total=$(count_subagents)

    echo "[SessionStart] Component Status"
    echo "  Hooks: $hook_total registered ($hook_ok OK, $hook_missing missing)"
    echo "  Skills: $skill_total found ($skill_with_md have SKILL.md)"
    echo "  SubAgents: $subagent_total found"
    echo ""

    # Run coherence check
    run_coherence_check
}

main
