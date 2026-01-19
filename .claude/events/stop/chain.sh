#!/bin/bash
# chain.sh - event unit: stop
# Claude が会話を終了しようとした時に発火

set -euo pipefail

EVENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$EVENT_DIR/../.." && pwd)"
SKILLS_DIR="$CLAUDE_DIR/skills"
SESSION_STATE_DIR="$CLAUDE_DIR/session-state"
PENDING_FILE="$SESSION_STATE_DIR/post-loop-pending"
STATE_FILE="${STATE_FILE:-state.md}"
ROLE_RESOLVER="$SKILLS_DIR/playbook-gate/guards/role-resolver.sh"

INPUT=$(cat)

# ==============================================================================
# pending ファイルチェック（post-loop 強制ガード）
# ==============================================================================
# pending ファイルが存在する場合、post-loop が未実行
# Claude が Stop を実行する前に post-loop 呼び出しを強制する

if [[ -f "$PENDING_FILE" ]]; then
    # main ブランチ例外（pending-guard.sh と同じロジック）
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" ]]; then
        # pending ファイルの内容を読み取り
        if command -v jq &> /dev/null; then
            PENDING_STATUS=$(jq -r '.status // "unknown"' "$PENDING_FILE" 2>/dev/null || echo "unknown")
            PENDING_PLAYBOOK=$(jq -r '.playbook // "unknown"' "$PENDING_FILE" 2>/dev/null || echo "unknown")
        else
            PENDING_STATUS="unknown"
            PENDING_PLAYBOOK="unknown"
        fi
        
        echo "" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "  🛑 Stop ブロック: post-loop 未実行" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "" >&2
        echo "  playbook: $PENDING_PLAYBOOK" >&2
        echo "  status: $PENDING_STATUS" >&2
        echo "" >&2
        echo "  必須アクション:" >&2
        echo "    Skill(skill='post-loop') を今すぐ呼び出してください。" >&2
        echo "" >&2
        echo "  post-loop が実行する処理:" >&2
        echo "    1. pending ファイル削除（ブロック解除）" >&2
        echo "    2. 次タスクの導出（pm SubAgent 経由）" >&2
        echo "" >&2
        echo "  ⚠️ post-loop を実行せずに終了すると作業が消失します。" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        
        # exit 2 = ブロック（Claude Code 公式仕様）
        exit 2
    fi
fi

# ==============================================================================
# p_final + executor: coderabbit 委譲チェック
# ==============================================================================
# レビュータスク（コード編集なし）では executor-guard.sh が発火しないため、
# Stop フックで補完的に p_final を検知し、coderabbit-delegate 委譲を促す

check_pfinal_coderabbit_delegation() {
    # jq が利用不可なら終了
    command -v jq &> /dev/null || return 0
    
    # state.md から playbook.active を取得
    if [[ ! -f "$STATE_FILE" ]]; then
        return 0
    fi
    
    PLAYBOOK_PATH=$(grep -A10 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')
    if [[ -z "$PLAYBOOK_PATH" || "$PLAYBOOK_PATH" == "null" ]]; then
        return 0
    fi
    
    # playbook ディレクトリから progress.json を取得
    PLAYBOOK_DIR=$(dirname "$PLAYBOOK_PATH")
    PROGRESS_FILE="$PLAYBOOK_DIR/progress.json"
    PLAN_FILE="$PLAYBOOK_PATH"
    
    if [[ ! -f "$PROGRESS_FILE" || ! -f "$PLAN_FILE" ]]; then
        return 0
    fi
    
    # progress.json から active.subtask を取得
    ACTIVE_SUBTASK=$(jq -r '.active.subtask // ""' "$PROGRESS_FILE" 2>/dev/null || echo "")
    if [[ -z "$ACTIVE_SUBTASK" ]]; then
        return 0
    fi
    
    # p_final で始まるかチェック
    if [[ ! "$ACTIVE_SUBTASK" =~ ^p_final ]]; then
        return 0
    fi
    
    # plan.json から該当 subtask の executor を取得
    EXECUTOR=$(jq -r --arg subtask "$ACTIVE_SUBTASK" '
        .phases[] | select(.id == "p_final") | .subtasks[] | select(.id == $subtask) | .executor // ""
    ' "$PLAN_FILE" 2>/dev/null || echo "")
    
    if [[ -z "$EXECUTOR" ]]; then
        return 0
    fi
    
    # executor が reviewer または coderabbit かチェック
    if [[ "$EXECUTOR" != "reviewer" && "$EXECUTOR" != "coderabbit" ]]; then
        return 0
    fi
    
    # toolstack 取得（role-resolver.sh と同じロジック）
    TOOLSTACK="A"
    if [[ -f "$STATE_FILE" ]]; then
        TS=$(grep -A10 "^## config" "$STATE_FILE" 2>/dev/null | grep "toolstack:" | head -1 | sed 's/toolstack: *//' | sed 's/ *#.*//' | tr -d ' ')
        if [[ -n "$TS" ]]; then
            TOOLSTACK="$TS"
        fi
    fi
    
    # toolstack C でなければ終了
    if [[ "$TOOLSTACK" != "C" ]]; then
        return 0
    fi
    
    # coderabbit-delegate 委譲推奨メッセージを出力
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "  💡 p_final: coderabbit-delegate 委譲推奨" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "  現在の subtask: $ACTIVE_SUBTASK" >&2
    echo "  executor: $EXECUTOR" >&2
    echo "" >&2
    echo "  レビュータスクで coderabbit-delegate が未呼び出しの場合:" >&2
    echo "" >&2
    echo "    Task(" >&2
    echo "      subagent_type='coderabbit-delegate'," >&2
    echo "      prompt='p_final: 最終レビューを実施'" >&2
    echo "    )" >&2
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    
    # 警告のみ、exit 0 で通過
    return 0
}

# p_final + coderabbit チェック実行
check_pfinal_coderabbit_delegation

# ==============================================================================
# completion-check は exit code を伝播させる（ブロック機能）
# ==============================================================================
COMPLETION_CHECK="$SKILLS_DIR/reward-guard/guards/completion-check.sh"
if [[ -x "$COMPLETION_CHECK" ]]; then
    echo "$INPUT" | bash "$COMPLETION_CHECK"
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        exit $EXIT_CODE
    fi
fi

exit 0
