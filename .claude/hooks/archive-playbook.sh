#!/bin/bash
# archive-playbook.sh - playbook 完了時の自動アーカイブ提案
#
# 発火条件: PostToolUse:Edit
# 目的: playbook の全 Phase が done になったら .archive/plan/ に移動を提案
#
# 設計思想:
#   - playbook 完了を自動検出
#   - 移動は提案のみ（自動実行しない）
#   - ユーザー判断でアーカイブを実行

set -e

# state.md が存在しない場合はスキップ
if [ ! -f "state.md" ]; then
    exit 0
fi

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# 編集対象ファイルを取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# playbook ファイル以外は無視
if [[ "$FILE_PATH" != *playbook*.md ]]; then
    exit 0
fi

# playbook ファイルが存在しない場合はスキップ
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# playbook 内の Phase status を確認
# 全ての status: が done であるかチェック
TOTAL_PHASES=$(grep -c "^  status:" "$FILE_PATH" 2>/dev/null || echo "0")
DONE_PHASES=$(grep "^  status: done" "$FILE_PATH" 2>/dev/null | wc -l | tr -d ' ')

# Phase がない場合はスキップ
if [ "$TOTAL_PHASES" -eq 0 ]; then
    exit 0
fi

# 全 Phase が done でない場合はスキップ
if [ "$DONE_PHASES" -ne "$TOTAL_PHASES" ]; then
    exit 0
fi

# 相対パスに変換
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RELATIVE_PATH="${FILE_PATH#$PROJECT_DIR/}"

# playbook 名を取得
PLAYBOOK_NAME=$(basename "$FILE_PATH")

# アーカイブ先を決定
ARCHIVE_DIR=".archive/plan"
ARCHIVE_PATH="$ARCHIVE_DIR/$PLAYBOOK_NAME"

# 全 Phase が done の場合、アーカイブを提案
cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📦 Playbook 完了検出
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Playbook: $RELATIVE_PATH
  Status: 全 $TOTAL_PHASES Phase が done

  アーカイブを推奨します:
    mkdir -p $ARCHIVE_DIR
    mv $RELATIVE_PATH $ARCHIVE_PATH

  アーカイブ後:
    1. state.md の active_playbooks を null に更新
    2. 新しい playbook を作成（必要に応じて）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

exit 0
