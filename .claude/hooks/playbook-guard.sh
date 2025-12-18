#!/bin/bash
# playbook-guard.sh - Edit/Write 時に playbook=null ならブロック
#
# 目的: playbook なしでのコード変更を構造的に防止
# トリガー: PreToolUse(Edit), PreToolUse(Write)
#
# 設計思想（アクションベース Guards）:
#   - プロンプトの「意図」ではなく「アクション」を制御
#   - Read/Grep/WebSearch 等は常に許可
#   - Edit/Write のみ playbook チェック
#
# ブートストラップ例外 (M-bootstrap):
#   - playbook=null でも playbook ファイル自体の作成は許可
#   - これがないと /playbook-init が動作しない（デッドロック）

set -euo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

# state.md が存在しない場合はパス
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# --------------------------------------------------
# Admin モードチェック（最優先）
# --------------------------------------------------
SECURITY=$(grep -A3 "^## config" "$STATE_FILE" 2>/dev/null | grep "security:" | head -1 | sed 's/security: *//' | tr -d ' ')
if [[ "$SECURITY" == "admin" ]]; then
    # admin モードは全ての制限をバイパス
    exit 0
fi

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# ファイルパスを取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# --------------------------------------------------
# 常に許可するファイル（デッドロック回避）
# --------------------------------------------------

# state.md への編集は常に許可
if [[ "$FILE_PATH" == *"state.md" ]]; then
    exit 0
fi

# --------------------------------------------------
# ブートストラップ例外: playbook ファイル自体の作成/編集は許可
# /playbook-init や pm が新規 playbook を作成できるようにする
# --------------------------------------------------
if [[ "$FILE_PATH" == *"plan/playbook-"*.md ]] || \
   [[ "$FILE_PATH" == *"plan/active/playbook-"*.md ]]; then
    exit 0
fi

# --------------------------------------------------
# playbook チェック
# --------------------------------------------------

# focus.current を取得
FOCUS=$(grep -A6 "^## focus" "$STATE_FILE" | grep "^current:" | head -1 | sed 's/current: *//' | sed 's/ *#.*//' | tr -d ' ')

# playbook セクションから active を取得
PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')

# playbook が null または空なら ブロック
if [[ -z "$PLAYBOOK" || "$PLAYBOOK" == "null" ]]; then
    # 失敗を記録（学習ループ用）
    if [[ -f ".claude/hooks/failure-logger.sh" ]]; then
        echo '{"hook": "playbook-guard", "context": "playbook=null", "action": "Edit/Write blocked"}' | bash .claude/hooks/failure-logger.sh 2>/dev/null || true
    fi

    cat >&2 << 'EOF'
========================================
  ⛔ playbook 必須
========================================

  Edit/Write には playbook が必要です。

  対処法（いずれかを実行）:

    [推奨] pm エージェントを呼び出す:
      Task(subagent_type='pm', prompt='playbook を作成してください')

    または /playbook-init を実行:
      /playbook-init

  現在の状態:
EOF
    echo "    focus: $FOCUS" >&2
    echo "    playbook: null" >&2
    echo "" >&2
    echo "========================================" >&2
    exit 2
fi

# playbook ファイルが存在するか確認
if [[ ! -f "$PLAYBOOK" ]]; then
    exit 0
fi

# reviewed フラグを取得
REVIEWED=$(grep -E "^reviewed:" "$PLAYBOOK" 2>/dev/null | head -1 | sed 's/reviewed: *//' | sed 's/ *#.*//' | tr -d ' ')

# reviewed: false の場合は警告（ブロックではない）
if [[ "$REVIEWED" == "false" ]]; then
    cat << 'EOF'
{
  "decision": "allow",
  "systemMessage": "[playbook-guard] ⚠️ playbook 未レビュー\n\n実装開始前に reviewer による検証を推奨します:\n  Task(subagent_type='reviewer', prompt='playbook をレビュー')\n\nレビュー完了後、playbook の reviewed: true に更新してください。"
}
EOF
    exit 0
fi

# playbook があり、reviewed: true（または未設定）ならパス
exit 0
