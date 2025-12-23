#!/bin/bash
# ==============================================================================
# playbook-review-trigger.sh - reviewed: false で Edit/Write をブロック
# ==============================================================================
# 目的: playbook レビュー前の作業開始を構造的に防止
# トリガー: PreToolUse(Edit), PreToolUse(Write)
#
# 設計思想:
#   - reviewed: false の playbook がある状態での作業をブロック
#   - reviewer SubAgent による検証を強制
#   - ブロック時は reviewer 呼び出しを案内
#
# ブートストラップ例外:
#   - playbook ファイル自体の編集は許可（reviewer が修正するため）
#   - state.md の編集は許可
# ==============================================================================

set -euo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

# state.md が存在しない場合はパス
if [[ ! -f "$STATE_FILE" ]]; then
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

# playbook ファイル自体の編集は許可（reviewer が修正するため）
if [[ "$FILE_PATH" == *"plan/playbook-"*.md ]] || \
   [[ "$FILE_PATH" == *"plan/active/playbook-"*.md ]]; then
    exit 0
fi

# --------------------------------------------------
# playbook チェック
# --------------------------------------------------

# playbook セクションから active を取得
PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')

# playbook が null または空なら別の Hook（playbook-guard）に任せる
if [[ -z "$PLAYBOOK" || "$PLAYBOOK" == "null" ]]; then
    exit 0
fi

# playbook ファイルが存在するか確認
if [[ ! -f "$PLAYBOOK" ]]; then
    exit 0
fi

# --------------------------------------------------
# reviewed フラグチェック（核心ロジック）
# --------------------------------------------------

# reviewed フラグを取得
REVIEWED=$(grep -E "^reviewed:" "$PLAYBOOK" 2>/dev/null | head -1 | sed 's/reviewed: *//' | sed 's/ *#.*//' | tr -d ' ')

# reviewed: false の場合は ブロック（exit 2）
if [[ "$REVIEWED" == "false" ]]; then
    cat >&2 << 'EOF'
========================================
  [playbook-review] playbook 未レビュー
========================================

  reviewed: false の playbook では作業できません。

  対処法:
    reviewer SubAgent を呼び出してください:

      Task(subagent_type='reviewer',
           prompt='playbook をレビュー。
           .claude/skills/playbook-review/frameworks/playbook-review-criteria.md を参照')

  レビュー完了後:
    playbook の reviewed: true に更新してください。

  現在の playbook:
EOF
    echo "    $PLAYBOOK" >&2
    echo "" >&2
    echo "========================================" >&2
    exit 2
fi

# reviewed: true（または未設定）ならパス
exit 0
