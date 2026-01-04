#!/bin/bash
# pre-tool.sh - PreToolUse(*) 導火線
# 適切な Skills を順次呼び出す

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/../skills"
LIB_DIR="$SCRIPT_DIR/../lib"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONTRACT_SCRIPT="$REPO_ROOT/scripts/contract.sh"
MARKER_FILE="$SCRIPT_DIR/../session-state/prompt-analyzer-called"

# 共通ライブラリ読み込み
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
fi

# 入力を読み込み
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# === prompt-analyzer 強制ガード ===
# マーカーがない場合、prompt-analyzer 以外をブロック（読み取り系は例外）
if [[ ! -f "$MARKER_FILE" ]]; then
    if [[ "$TOOL_NAME" == "Task" ]]; then
        SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')
        if [[ "$SUBAGENT_TYPE" == "prompt-analyzer" ]]; then
            # prompt-analyzer → マーカー作成して許可
            touch "$MARKER_FILE"
        else
            echo "BLOCK: prompt-analyzer を先に呼び出してください (tool=Task, subagent=$SUBAGENT_TYPE)" >&2
            exit 2
        fi
    else
        ALLOW_WITHOUT_ANALYZER=false
        case "$TOOL_NAME" in
            Read|Grep|Glob)
                ALLOW_WITHOUT_ANALYZER=true
                ;;
            Bash)
                # 変更系 Bash を防ぐため、契約チェックで read-only を判定
                COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
                if [[ -f "$CONTRACT_SCRIPT" ]]; then
                    # shellcheck source=../../scripts/contract.sh
                    source "$CONTRACT_SCRIPT"
                    if contract_check_bash "$COMMAND"; then
                        ALLOW_WITHOUT_ANALYZER=true
                    else
                        exit 2
                    fi
                fi
                ;;
        esac

        if [[ "$ALLOW_WITHOUT_ANALYZER" != "true" ]]; then
            echo "BLOCK: prompt-analyzer を先に呼び出してください (tool=$TOOL_NAME)" >&2
            exit 2
        fi
    fi
fi

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
