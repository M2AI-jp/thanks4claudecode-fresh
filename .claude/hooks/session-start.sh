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

# Main output
main() {
    read -r hook_total hook_ok hook_missing <<< "$(count_hooks)"
    read -r skill_total skill_with_md <<< "$(count_skills)"
    subagent_total=$(count_subagents)
    
    echo "[SessionStart] Component Status"
    echo "  Hooks: $hook_total registered ($hook_ok OK, $hook_missing missing)"
    echo "  Skills: $skill_total found ($skill_with_md have SKILL.md)"
    echo "  SubAgents: $subagent_total found"
}

main
