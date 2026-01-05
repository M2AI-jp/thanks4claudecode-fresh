#!/bin/bash
# scope-guard.sh - done_when/done_criteria の無断変更を検出（playbook v2）
#
# 目的: pm を経由せずにスコープを拡張することを防止
# トリガー: PreToolUse(Edit), PreToolUse(Write)

set -euo pipefail

STRICT_MODE="${STRICT_MODE:-false}"

INPUT=$(cat)

if ! command -v jq &> /dev/null; then
    cat >&2 << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ jq 未インストール - セキュリティチェック不可
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
jq はセキュリティガードに必須です。
Install: brew install jq
EOF
    exit 2
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

case "$FILE_PATH" in
    */play/*/plan.json) ;;
    *) exit 0 ;;
esac

if [[ "$FILE_PATH" == */archive/* ]] || [[ "$FILE_PATH" == */template/* ]]; then
    exit 0
fi

STRICT_MODE="$STRICT_MODE" printf '%s' "$INPUT" | python3 - "$FILE_PATH" << 'PY'
import json
import os
import sys
from pathlib import Path

plan_path = Path(sys.argv[1])
strict_mode = os.environ.get("STRICT_MODE", "false").lower() == "true"

try:
    payload = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)

tool_input = payload.get("tool_input", {})
content = tool_input.get("content")
old_string = tool_input.get("old_string")
new_string = tool_input.get("new_string")

try:
    current_text = plan_path.read_text()
except FileNotFoundError:
    sys.exit(0)

try:
    old_data = json.loads(current_text)
except json.JSONDecodeError:
    print("plan.json が不正な JSON です。修正してから再実行してください。", file=sys.stderr)
    sys.exit(2)

if content:
    new_text = content
elif old_string and new_string:
    if old_string not in current_text:
        sys.exit(0)
    new_text = current_text.replace(old_string, new_string, 1)
else:
    sys.exit(0)

if new_text == current_text:
    sys.exit(0)

try:
    new_data = json.loads(new_text)
except json.JSONDecodeError:
    print("plan.json の更新後内容が JSON として不正です。", file=sys.stderr)
    sys.exit(2)

def normalized(value):
    if value is None:
        return []
    return value

old_goal = old_data.get("goal", {}) or {}
new_goal = new_data.get("goal", {}) or {}

old_done_when = normalized(old_goal.get("done_when"))
new_done_when = normalized(new_goal.get("done_when"))
old_done_criteria = normalized(old_goal.get("done_criteria"))
new_done_criteria = normalized(new_goal.get("done_criteria"))

changed = old_done_when != new_done_when or old_done_criteria != new_done_criteria
if not changed:
    sys.exit(0)

lines = [
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "  ⚠️ スコープ変更を検出",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "",
    "  done_when または done_criteria を変更しようとしています。",
    "",
    "  確認事項:",
    "    - この変更はユーザーの承認を得ていますか？",
    "    - pm エージェントを経由しましたか？",
    "    - スコープクリープではありませんか？",
    "",
    "  正しい手順:",
    "    1. ユーザーに変更理由を説明",
    "    2. pm SubAgent 経由で playbook を更新",
    "    3. 承認を得てから編集",
    "",
    f"  対象ファイル: {plan_path}",
    "",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
]

print("\n".join(lines), file=sys.stderr)
if strict_mode:
    print("  🚫 STRICT_MODE=true: この変更はブロックされます", file=sys.stderr)
    sys.exit(2)
sys.exit(0)
PY
