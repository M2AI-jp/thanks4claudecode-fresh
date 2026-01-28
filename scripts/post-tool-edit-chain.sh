#!/bin/bash
# post-tool-edit-chain.sh - event unit: post-tool-edit
# Symlinked from .claude/events/post-tool-edit/chain.sh

set -euo pipefail

REAL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
REPO_ROOT="$(cd "$REAL_DIR/.." && pwd)"
EVENT_DIR="$REPO_ROOT/.claude/events/post-tool-edit"
CLAUDE_DIR="$REPO_ROOT/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"

INPUT=$(cat)

# Telemetry
if [[ -x "$EVENT_DIR/telemetry.sh" ]]; then
    echo "$INPUT" | "$EVENT_DIR/telemetry.sh" 2>/dev/null || true
fi

invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    if [[ -x "$path" ]]; then
        echo "$INPUT" | bash "$path" || true
    fi
}

invoke_skill "reward-guard" "guards/progress-reminder.sh"
invoke_skill "playbook-gate" "workflow/archive-playbook.sh"
invoke_skill "playbook-gate" "workflow/cleanup.sh"
invoke_skill "git-workflow" "handlers/create-pr-hook.sh"

exit 0
