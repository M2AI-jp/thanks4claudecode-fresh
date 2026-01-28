#!/bin/bash
# pre-tool-edit-chain.sh - event unit: pre-tool-edit
# Symlinked from .claude/events/pre-tool-edit/chain.sh

set -euo pipefail

REAL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
REPO_ROOT="$(cd "$REAL_DIR/.." && pwd)"
EVENT_DIR="$REPO_ROOT/.claude/events/pre-tool-edit"
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
        echo "$INPUT" | bash "$path"
        return $?
    fi
    return 0
}

invoke_skill "post-loop" "guards/pending-guard.sh" || exit $?
invoke_skill "access-control" "guards/protected-edit.sh" || exit $?
invoke_skill "playbook-gate" "guards/playbook-guard.sh" || exit $?
invoke_skill "playbook-gate" "guards/depends-check.sh" || exit $?
invoke_skill "playbook-gate" "guards/executor-guard.sh" || exit $?
invoke_skill "reward-guard" "guards/critic-guard.sh" || exit $?
invoke_skill "reward-guard" "guards/subtask-guard.sh" || exit $?
invoke_skill "reward-guard" "guards/phase-status-guard.sh" || exit $?
invoke_skill "reward-guard" "guards/scope-guard.sh" || exit $?

exit 0
