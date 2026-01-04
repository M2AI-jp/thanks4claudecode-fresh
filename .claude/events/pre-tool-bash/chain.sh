#!/bin/bash
# chain.sh - event unit: pre-tool-bash
# Current: tool-specific guardrail chain. init-guard/main-branch run in dispatcher.

set -euo pipefail

EVENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$EVENT_DIR/../.." && pwd)"
SKILLS_DIR="$CLAUDE_DIR/skills"

INPUT=$(cat)

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

# Bash 契約チェック
invoke_skill "access-control" "guards/bash-check.sh" || exit $?
# 整合性チェック
invoke_skill "reward-guard" "guards/coherence.sh" || exit $?
# Lint チェック
invoke_skill "quality-assurance" "checkers/lint.sh" || exit $?

exit 0
