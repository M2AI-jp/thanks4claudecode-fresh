#!/bin/bash
# pre-tool.sh - PreToolUse(*) 導火線
# 適切な Skills を順次呼び出す

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/../skills"
LIB_DIR="$SCRIPT_DIR/../lib"
LOG_DIR="$SCRIPT_DIR/../logs"

# ログディレクトリ作成
mkdir -p "$LOG_DIR"

# 実行時間ログ用
START_TIME=$(date +%s%3N 2>/dev/null || date +%s)
LOG_FILE="$LOG_DIR/hook-timing.log"

# 共通ライブラリ読み込み
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
fi

# 入力を読み込み
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Skill を呼び出す関数（BLOCK 理由ログ付き）
invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    if [[ -x "$path" ]]; then
        local output
        local exit_code
        output=$(echo "$INPUT" | bash "$path" 2>&1) || exit_code=$?
        exit_code=${exit_code:-0}

        if [[ $exit_code -ne 0 ]]; then
            # BLOCK 理由をログに記録
            local block_log="$LOG_DIR/block-reasons.log"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLOCK by $skill/$script (exit: $exit_code) tool=$TOOL_NAME" >> "$block_log"
            echo "$output" | head -20 >> "$block_log"
            echo "---" >> "$block_log"
            # エラー出力を stderr に転送
            echo "$output" >&2
        fi
        return $exit_code
    fi
    return 0
}

# 1. session-manager: init-guard（全ツール共通）
invoke_skill "session-manager" "handlers/init-guard.sh" || exit $?

# 2. access-control: ブランチチェック
invoke_skill "access-control" "guards/main-branch.sh" || exit $?

case "$TOOL_NAME" in
    Edit|Write)
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

# 実行時間をログに記録
END_TIME=$(date +%s%3N 2>/dev/null || date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "[$(date '+%Y-%m-%d %H:%M:%S')] pre-tool.sh tool=$TOOL_NAME elapsed=${ELAPSED}ms" >> "$LOG_FILE"

exit 0
