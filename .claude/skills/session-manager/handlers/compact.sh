#!/bin/bash
# ==============================================================================
# compact.sh - PreCompact Hook: 最小ポインタで復元橋を架ける
# ==============================================================================
#
# 設計思想:
#   - 永続データは playbook に集約（SSOT の延長）
#   - additionalContext は最小のポインタのみ
#   - snapshot.json は廃止（.claude/ 配下は compact で削除される）
#
# 発火: PreCompact イベント（auto-compact または /compact）
# 出力: additionalContext（JSON）- 最小セット
#
# ==============================================================================

set -e

STATE_FILE="state.md"

# ==============================================================================
# 1. 最小限の情報収集
# ==============================================================================

PLAYBOOK_PATH=""
CURRENT_PHASE=""

if [ -f "$STATE_FILE" ]; then
    PLAYBOOK_PATH=$(grep -A5 "## playbook" "$STATE_FILE" 2>/dev/null | grep "active:" | head -1 | sed 's/.*active: *//' | sed 's/ *#.*//')
fi

# playbook から現在 Phase を取得
if [ -n "$PLAYBOOK_PATH" ] && [ "$PLAYBOOK_PATH" != "null" ] && [ -f "$PLAYBOOK_PATH" ]; then
    CURRENT_PHASE=$(grep -E "status: in_progress" "$PLAYBOOK_PATH" -B20 2>/dev/null | grep -E "^- id: p[0-9]" | tail -1 | sed 's/.*id: *//')
fi

# branch（オプション、便利）
BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# ==============================================================================
# 2. additionalContext を stdout に出力（最小セット）
# ==============================================================================

# JSON エスケープ関数
json_escape() {
    echo -n "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo '""'
}

# resume_instruction: 1行で「何を読むか」
if [ -n "$PLAYBOOK_PATH" ] && [ "$PLAYBOOK_PATH" != "null" ]; then
    RESUME_INSTRUCTION="Read state.md then open $PLAYBOOK_PATH"
else
    RESUME_INSTRUCTION="Read state.md to check current task"
fi

# 最小の additionalContext
ADDITIONAL_CONTEXT="resume_instruction: \"$RESUME_INSTRUCTION\"
playbook: \"$PLAYBOOK_PATH\"
phase: \"$CURRENT_PHASE\"
branch: \"$BRANCH\""

ESCAPED_CONTEXT=$(json_escape "$ADDITIONAL_CONTEXT")
cat << EOF
{
  "additionalContext": $ESCAPED_CONTEXT
}
EOF

exit 0
