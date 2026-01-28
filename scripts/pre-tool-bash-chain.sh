#!/bin/bash
# pre-tool-bash-chain.sh - event unit: pre-tool-bash
# Symlinked from .claude/events/pre-tool-bash/chain.sh

set -euo pipefail

REAL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
REPO_ROOT="$(cd "$REAL_DIR/.." && pwd)"
EVENT_DIR="$REPO_ROOT/.claude/events/pre-tool-bash"
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

invoke_skill "access-control" "guards/bash-check.sh" || exit $?
invoke_skill "reward-guard" "guards/coherence.sh" || exit $?
invoke_skill "quality-assurance" "checkers/lint.sh" || exit $?

exit 0
