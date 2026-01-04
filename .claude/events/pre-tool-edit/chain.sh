#!/bin/bash
# chain.sh - event unit: pre-tool-edit
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

# post-loop pending チェック（playbook 完了後の強制）
invoke_skill "post-loop" "guards/pending-guard.sh" || exit $?
# 保護ファイルチェック
invoke_skill "access-control" "guards/protected-edit.sh" || exit $?
# playbook 必須チェック
invoke_skill "playbook-gate" "guards/playbook-guard.sh" || exit $?
# Phase 依存チェック
invoke_skill "playbook-gate" "guards/depends-check.sh" || exit $?
# executor チェック
invoke_skill "playbook-gate" "guards/executor-guard.sh" || exit $?
# done 変更前チェック
invoke_skill "reward-guard" "guards/critic-guard.sh" || exit $?
# subtask 完了チェック
invoke_skill "reward-guard" "guards/subtask-guard.sh" || exit $?
# Phase status 変更チェック
invoke_skill "reward-guard" "guards/phase-status-guard.sh" || exit $?
# スコープ変更検出
invoke_skill "reward-guard" "guards/scope-guard.sh" || exit $?

exit 0
