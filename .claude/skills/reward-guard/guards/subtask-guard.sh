#!/bin/bash
# ==============================================================================
# subtask-guard.sh - subtask 完了時の critic 検証を強制（playbook v2 / progress.json）
# ==============================================================================
# 目的: progress.json で subtask の status が done に変わる際に以下を要求:
#       1. validations(technical/consistency/completeness) の status が全て PASS
#       2. validated_by: "critic" が設定されていること（自己報酬詐欺防止）
#       3. validated_at が設定されていること
#
# 設計思想:
#   - Claude が自分で validations を埋めて done にすることを防止
#   - critic SubAgent が PASS 判定した証拠として validated_by を要求
#   - Hook Unit = 強制の入口（exit 2 でブロック）
#
# トリガー: PreToolUse(Edit/Write)
# ==============================================================================

set -euo pipefail

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
    */play/*/progress.json) ;;
    *) exit 0 ;;
esac

if [[ "$FILE_PATH" == */archive/* ]] || [[ "$FILE_PATH" == */template/* ]]; then
    exit 0
fi

# 環境変数経由で payload を渡す（HEREDOC と stdin の競合を回避）
export SUBTASK_GUARD_PAYLOAD="$INPUT"

python3 - "$FILE_PATH" << 'PY'
import json
import sys
import os
from pathlib import Path

file_path = sys.argv[1]

try:
    payload = json.loads(os.environ.get("SUBTASK_GUARD_PAYLOAD", "{}"))
except json.JSONDecodeError:
    sys.exit(0)

tool_input = payload.get("tool_input", {})
content = tool_input.get("content")
old_string = tool_input.get("old_string")
new_string = tool_input.get("new_string")

try:
    current_text = Path(file_path).read_text()
except FileNotFoundError:
    sys.exit(0)

try:
    old_data = json.loads(current_text)
except json.JSONDecodeError:
    print("progress.json が不正な JSON です。修正してから再実行してください。", file=sys.stderr)
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
    print("progress.json の更新後内容が JSON として不正です。", file=sys.stderr)
    sys.exit(2)

old_subtasks = old_data.get("subtasks", {}) or {}
new_subtasks = new_data.get("subtasks", {}) or {}

errors = []
for subtask_id, new_entry in new_subtasks.items():
    old_status = old_subtasks.get(subtask_id, {}).get("status")
    new_status = new_entry.get("status")
    if old_status != "done" and new_status == "done":
        missing = []
        validations = new_entry.get("validations", {}) or {}
        for key in ("technical", "consistency", "completeness"):
            v = validations.get(key, {}) or {}
            status = v.get("status")
            evidence = v.get("evidence", [])
            if status != "PASS" or not isinstance(evidence, list) or not evidence:
                missing.append(key)
        if not new_entry.get("validated_at"):
            missing.append("validated_at")
        # validated_by: "critic" のチェック（自己報酬詐欺防止）
        validated_by = new_entry.get("validated_by", "")
        if validated_by != "critic":
            missing.append("validated_by: critic")
        if missing:
            errors.append((subtask_id, missing))

if not errors:
    sys.exit(0)

lines = [
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "  ⛔ subtask 完了には critic 検証が必須です",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "",
]
for subtask_id, missing in errors[:3]:
    lines.append(f"  - {subtask_id}: missing {', '.join(missing)}")
if len(errors) > 3:
    lines.append(f"  ... and {len(errors) - 3} more")

lines.extend(
    [
        "",
        "必要条件:",
        "  - validations.technical/consistency/completeness の status = PASS",
        "  - 各 validation の evidence が1件以上",
        "  - validated_at を設定",
        "  - validated_by: 'critic' を設定（自己報酬詐欺防止）",
        "",
        "対処法:",
        "  1. Task(subagent_type='critic') で検証を実行",
        "  2. critic が PASS を返したら validated_by: 'critic' を設定",
        "  3. 再度 status: done に変更",
        "",
        f"対象ファイル: {file_path}",
        "",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    ]
)

print("\n".join(lines), file=sys.stderr)
sys.exit(2)
PY
