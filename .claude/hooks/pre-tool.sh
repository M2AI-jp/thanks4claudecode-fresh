#!/bin/bash
# pre-tool.sh - PreToolUse(*) 導火線
# 適切な Skills を順次呼び出す

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/../skills"
LIB_DIR="$SCRIPT_DIR/../lib"

# 共通ライブラリ読み込み
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
fi

# 入力を読み込み
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Skill を呼び出す関数
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

# 1. session-manager: init-guard（全ツール共通）
invoke_skill "session-manager" "handlers/init-guard.sh" || exit $?

# 2. access-control: ブランチチェック
invoke_skill "access-control" "guards/main-branch.sh" || exit $?

case "$TOOL_NAME" in
    Edit|Write)
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
        # スコープ変更検出
        invoke_skill "reward-guard" "guards/scope-guard.sh" || exit $?
        ;;
    Bash)
        # Bash 契約チェック
        invoke_skill "access-control" "guards/bash-check.sh" || exit $?
        # 整合性チェック
        invoke_skill "reward-guard" "guards/coherence.sh" || exit $?
        # Lint チェック（git commit 前など）
        invoke_skill "quality-assurance" "checkers/lint.sh" || exit $?
        ;;
esac

exit 0
