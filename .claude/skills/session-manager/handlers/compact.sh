#!/bin/bash
# ==============================================================================
# pre-compact.sh - PreCompact Hook: 完全な状態スナップショット保存
# ==============================================================================
#
# 目的:
#   - compact 前に完全なセッション状態を保存
#   - snapshot.json に構造化データを保存（SessionStart で復元可能）
#   - additionalContext で Claude に重要情報を伝達
#
# 発火: PreCompact イベント（auto-compact または /compact）
# 入力: { "trigger": "auto|manual", "conversation_length": number, ... }
# 出力:
#   - .claude/.session-init/snapshot.json に状態保存
#   - stdout: additionalContext（JSON）
#   - exit 0: 正常
#
# ==============================================================================

set -e

# stdin から JSON を読み込む
INPUT=$(cat)

# トリガー取得（auto or manual）
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "auto"' 2>/dev/null || echo "auto")

INIT_DIR=".claude/.session-init"
INTENT_FILE="$INIT_DIR/user-intent.md"
SNAPSHOT_FILE="$INIT_DIR/snapshot.json"
STATE_FILE="state.md"

mkdir -p "$INIT_DIR"

# ==============================================================================
# 1. 状態情報の収集
# ==============================================================================

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ユーザー意図（最新5件）
USER_INTENTS=""
if [ -f "$INTENT_FILE" ]; then
    USER_INTENTS=$(awk '/^## \[/{ if(count<5){ block=$0; getline; while(!/^## \[/ && !/^---$/){ block=block"\n"$0; getline } print block"\n---"; count++ } }' "$INTENT_FILE" 2>/dev/null | head -100)
fi

# state.md から情報取得
FOCUS=""
PLAYBOOK_PATH=""
CURRENT_PHASE=""
PHASE_GOAL=""
DONE_CRITERIA=""
SELF_COMPLETE=""
BRANCH=""

if [ -f "$STATE_FILE" ]; then
    FOCUS=$(grep -A5 "## focus" "$STATE_FILE" 2>/dev/null | grep "current:" | head -1 | sed 's/.*current: *//' | sed 's/ *#.*//')
    PLAYBOOK_PATH=$(grep -A5 "## playbook" "$STATE_FILE" 2>/dev/null | grep "active:" | head -1 | sed 's/.*active: *//' | sed 's/ *#.*//')
    SELF_COMPLETE=$(grep "self_complete:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*self_complete: *//' | sed 's/ *#.*//')
fi

# git 情報
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
GIT_STATUS=$(git status --porcelain 2>/dev/null | head -10 || echo "")
UNCOMMITTED_COUNT=$(echo "$GIT_STATUS" | grep -c "." 2>/dev/null || echo "0")

# playbook から現在 Phase 情報
if [ -n "$PLAYBOOK_PATH" ] && [ "$PLAYBOOK_PATH" != "null" ] && [ -f "$PLAYBOOK_PATH" ]; then
    CURRENT_PHASE=$(grep -E "status: in_progress" "$PLAYBOOK_PATH" -B20 2>/dev/null | grep -E "^- id: p[0-9]" | tail -1 | sed 's/.*id: *//')
    PHASE_GOAL=$(grep -E "status: in_progress" "$PLAYBOOK_PATH" -A5 2>/dev/null | grep "goal:" | head -1 | sed 's/.*goal: *//')
    DONE_CRITERIA=$(grep -A20 "status: in_progress" "$PLAYBOOK_PATH" 2>/dev/null | grep -E "^    - " | head -10 | sed 's/^    //')
fi

# ==============================================================================
# 2. snapshot.json に構造化データを保存
# ==============================================================================

# JSON エスケープ関数
json_escape() {
    echo -n "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo '""'
}

ESCAPED_INTENTS=$(json_escape "$USER_INTENTS")
ESCAPED_DONE_CRITERIA=$(json_escape "$DONE_CRITERIA")
ESCAPED_GIT_STATUS=$(json_escape "$GIT_STATUS")

cat > "$SNAPSHOT_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "trigger": "$TRIGGER",
  "focus": "$FOCUS",
  "playbook": "$PLAYBOOK_PATH",
  "current_phase": "$CURRENT_PHASE",
  "phase_goal": "$PHASE_GOAL",
  "done_criteria": $ESCAPED_DONE_CRITERIA,
  "self_complete": "$SELF_COMPLETE",
  "branch": "$BRANCH",
  "uncommitted_count": "$UNCOMMITTED_COUNT",
  "git_status": $ESCAPED_GIT_STATUS,
  "user_intents": $ESCAPED_INTENTS
}
EOF

# ==============================================================================
# 3. additionalContext を stdout に出力
# ==============================================================================

ADDITIONAL_CONTEXT="## 📦 Compact 前の状態スナップショット（自動保存済み）

### ユーザー意図（最新の指示）
$USER_INTENTS

### 現在の作業状態
- **focus**: $FOCUS
- **branch**: $BRANCH
- **playbook**: $PLAYBOOK_PATH
- **current_phase**: $CURRENT_PHASE
- **phase_goal**: $PHASE_GOAL
- **self_complete**: $SELF_COMPLETE
- **uncommitted_changes**: $UNCOMMITTED_COUNT 件

### done_criteria（現在 Phase）
$DONE_CRITERIA

---
⚠️ **重要**: この情報は .claude/.session-init/snapshot.json に保存されました。
Compact 後も session-start.sh がこの情報を復元します。
元の指示を忘れずに作業を続けてください。"

ESCAPED_CONTEXT=$(json_escape "$ADDITIONAL_CONTEXT")
cat << EOF
{
  "additionalContext": $ESCAPED_CONTEXT
}
EOF

exit 0
