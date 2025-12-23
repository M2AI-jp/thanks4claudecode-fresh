#!/bin/bash
# ==============================================================================
# pre-playbook-understanding.sh - playbook 作成前の理解確認トリガー Hook
# ==============================================================================
# 目的: playbook 作成前に理解確認（5W1H）を強制
# トリガー: UserPromptSubmit（タスク要求パターン検出時）
#
# 設計思想:
#   - playbook が null の状態でタスク要求を検出
#   - pm を呼ぶ前に理解確認を推奨（systemMessage で通知）
#   - 理解確認は pm の step 1.5 で実施されるべき
#
# 出力:
#   - systemMessage: 理解確認の推奨メッセージ
#   - exit 0: 警告のみ（ブロックしない）
#
# 参照: .claude/skills/understanding-check/SKILL.md
# ==============================================================================

set -euo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# state.md が存在しない場合はパス
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# stdin から JSON を読み込む
INPUT=$(cat)

# prompt を取得
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')

# プロンプトが空の場合はスキップ
if [ -z "$PROMPT" ]; then
    exit 0
fi

# --------------------------------------------------
# playbook の存在チェック
# --------------------------------------------------

PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')

# playbook が存在する場合はスキップ（既にタスク実行中）
if [[ -n "$PLAYBOOK" && "$PLAYBOOK" != "null" ]]; then
    exit 0
fi

# --------------------------------------------------
# タスク要求パターンの検出
# --------------------------------------------------

WORK_PATTERNS="(作って|実装して|追加して|修正して|変更して|削除して|create|implement|add|fix|change|delete|update|edit|write)"

if ! echo "$PROMPT" | grep -iE "$WORK_PATTERNS" > /dev/null 2>&1; then
    # タスク要求パターンではない → スキップ
    exit 0
fi

# --------------------------------------------------
# 理解確認推奨メッセージを出力
# --------------------------------------------------

# JSON 用にエスケープ
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/	/\\t/g'
}

MESSAGE="━━━━━━━━━━━━━━━━━━━━━━━━\\n"
MESSAGE="${MESSAGE}📋 【理解確認推奨】\\n"
MESSAGE="${MESSAGE}\\n"
MESSAGE="${MESSAGE}タスク要求を検出しました。playbook 作成前に理解確認（5W1H）を実施してください。\\n"
MESSAGE="${MESSAGE}\\n"
MESSAGE="${MESSAGE}推奨フロー:\\n"
MESSAGE="${MESSAGE}  1. pm を呼び出す\\n"
MESSAGE="${MESSAGE}  2. pm が understanding-check で 5W1H 分析を実施\\n"
MESSAGE="${MESSAGE}  3. ユーザーが承認\\n"
MESSAGE="${MESSAGE}  4. playbook 作成\\n"
MESSAGE="${MESSAGE}\\n"
MESSAGE="${MESSAGE}理解確認の内容:\\n"
MESSAGE="${MESSAGE}  - What: 何を作るか\\n"
MESSAGE="${MESSAGE}  - Why: なぜ必要か\\n"
MESSAGE="${MESSAGE}  - Who: 誰が使うか\\n"
MESSAGE="${MESSAGE}  - When: いつまでに\\n"
MESSAGE="${MESSAGE}  - Where: どこに実装するか\\n"
MESSAGE="${MESSAGE}  - How: どのように実装するか\\n"
MESSAGE="${MESSAGE}  - リスク分析と対策\\n"
MESSAGE="${MESSAGE}  - 不明点の洗い出し\\n"
MESSAGE="${MESSAGE}\\n"
MESSAGE="${MESSAGE}参照: .claude/skills/understanding-check/SKILL.md\\n"
MESSAGE="${MESSAGE}━━━━━━━━━━━━━━━━━━━━━━━━"

# systemMessage を JSON で出力
cat <<EOF
{
  "systemMessage": "${MESSAGE}"
}
EOF

exit 0
