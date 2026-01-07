#!/bin/bash
# chain.sh - event unit: stop
# Claude が会話を終了しようとした時に発火

set -euo pipefail

EVENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$EVENT_DIR/../.." && pwd)"
SKILLS_DIR="$CLAUDE_DIR/skills"
SESSION_STATE_DIR="$CLAUDE_DIR/session-state"
PENDING_FILE="$SESSION_STATE_DIR/post-loop-pending"

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
