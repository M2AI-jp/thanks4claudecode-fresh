#!/bin/bash
# chain.sh - event unit: subagent-stop
# Current: moved logic from .claude/hooks/subagent-stop.sh.

set -euo pipefail

EVENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$EVENT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$EVENT_DIR/../../.." && pwd)"
SKILLS_DIR="$CLAUDE_DIR/skills"

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合は Fail-closed（セキュリティのため）
if ! command -v jq &> /dev/null; then
    echo "[FAIL-CLOSED] jq not found - blocking for security" >&2
    exit 2
fi

# SubAgent 情報を取得
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# ログディレクトリ
LOG_DIR="$CLAUDE_DIR/logs"
mkdir -p "$LOG_DIR"

# 終了ログを記録
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] SubAgent stopped: $AGENT_ID (session: $SESSION_ID)" >> "$LOG_DIR/subagent.log"

# ==============================================================================
# M089: SubAgent 終了後の playbook 完了チェック
# ==============================================================================
# SubAgent 内での Edit は PostToolUse:Edit Hook を発火させないため、
# ここで playbook 完了チェックを補完する

STATE_FILE="$REPO_ROOT/state.md"
if [ -f "$STATE_FILE" ]; then
    ACTIVE_PLAYBOOK=$(grep '^active:' "$STATE_FILE" 2>/dev/null | sed 's/active: *//' | tr -d ' ')

    if [ -n "$ACTIVE_PLAYBOOK" ] && [ "$ACTIVE_PLAYBOOK" != "null" ] && [ -f "$REPO_ROOT/$ACTIVE_PLAYBOOK" ]; then
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Checking playbook completion: $ACTIVE_PLAYBOOK" >> "$LOG_DIR/subagent.log"

        # archive-playbook.sh を呼び出すための疑似 Edit イベントを作成
        # NOTE: archive-playbook.sh は */play/*/progress.json のみ受け付けるため、
        #       plan.json ではなく progress.json のパスを渡す必要がある（M090 修正）
        ARCHIVE_SCRIPT="$SKILLS_DIR/playbook-gate/workflow/archive-playbook.sh"
        if [ -x "$ARCHIVE_SCRIPT" ]; then
            # plan.json → progress.json に変換
            PROGRESS_PATH=$(echo "$ACTIVE_PLAYBOOK" | sed 's/plan\.json$/progress.json/')
            if [ -f "$REPO_ROOT/$PROGRESS_PATH" ]; then
                PSEUDO_INPUT=$(cat <<EOF2
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "$REPO_ROOT/$PROGRESS_PATH"
  }
}
EOF2
)
                echo "$PSEUDO_INPUT" | bash "$ARCHIVE_SCRIPT" 2>&1 | tee -a "$LOG_DIR/subagent.log" || true
            else
                echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] progress.json not found: $PROGRESS_PATH" >> "$LOG_DIR/subagent.log"
            fi
        fi
    fi
fi

exit 0
