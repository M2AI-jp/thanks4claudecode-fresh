#!/bin/bash
# ==============================================================================
# phase-status-guard.sh - Phase status 変更時の全 subtask 完了検証（v2）
# ==============================================================================
# 目的: progress.json の phase.status を done に変更する前に
#       当該 phase の subtask が全て done であることを検証
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

printf '%s' "$INPUT" | python3 - "$FILE_PATH" << 'PY'
import json
import sys
from pathlib import Path

progress_path = Path(sys.argv[1])
plan_path = progress_path.with_name("plan.json")

try:
    payload = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)

tool_input = payload.get("tool_input", {})
content = tool_input.get("content")
old_string = tool_input.get("old_string")
new_string = tool_input.get("new_string")

try:
    current_text = progress_path.read_text()
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

old_phases = old_data.get("phases", {}) or {}
new_phases = new_data.get("phases", {}) or {}

changed_to_done = []
for phase_id, new_entry in new_phases.items():
    old_status = old_phases.get(phase_id, {}).get("status")
    new_status = new_entry.get("status")
    if new_status in ("done", "completed") and old_status not in ("done", "completed"):
        changed_to_done.append(phase_id)

if not changed_to_done:
    sys.exit(0)

if not plan_path.exists():
    print(f"plan.json が見つかりません: {plan_path}", file=sys.stderr)
    sys.exit(0)

try:
    plan_data = json.loads(plan_path.read_text())
except json.JSONDecodeError:
    print("plan.json が不正な JSON です。修正してから再実行してください。", file=sys.stderr)
    sys.exit(2)

phase_subtasks = {}
for phase in plan_data.get("phases", []) or []:
    phase_id = phase.get("id")
    if not phase_id:
        continue
    phase_subtasks[phase_id] = [s.get("id") for s in phase.get("subtasks", []) or [] if s.get("id")]

new_subtasks = new_data.get("subtasks", {}) or {}
errors = []
for phase_id in changed_to_done:
    subtasks = phase_subtasks.get(phase_id, [])
    incomplete = [
        sid for sid in subtasks
        if new_subtasks.get(sid, {}).get("status") != "done"
    ]
    if incomplete:
        errors.append((phase_id, incomplete))

if not errors:
    sys.exit(0)

lines = [
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "  ⛔ BLOCKED: Phase を done にできません",
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "",
]
for phase_id, incomplete in errors[:3]:
    sample = ", ".join(incomplete[:5])
    lines.append(f"  - {phase_id}: 未完了 subtask {len(incomplete)} 件 ({sample})")
if len(errors) > 3:
    lines.append(f"  ... and {len(errors) - 3} more")

lines.extend(
    [
        "",
        "Phase を done にする前に、全ての subtask を done にしてください。",
        f"対象ファイル: {progress_path}",
        "",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    ]
)

print("\n".join(lines), file=sys.stderr)
sys.exit(2)
PY
