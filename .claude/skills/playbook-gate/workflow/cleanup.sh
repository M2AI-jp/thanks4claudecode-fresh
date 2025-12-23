#!/bin/bash
# cleanup-hook.sh - playbook 完了時のテンポラリファイル自動クリーンアップ
#
# 発火条件: PostToolUse:Edit
# 目的: playbook の全 Phase が done になったら tmp/ 内のテンポラリファイルを削除
#
# 設計思想:
#   - playbook 完了を自動検出（archive-playbook.sh と同様のロジック）
#   - tmp/ 内のファイルを削除（README.md は保持）
#   - 削除されたファイル数を systemMessage で通知
#   - dry-run モードはなし（tmp/ は一時ファイル専用なので安全）
#
# 連携:
#   - archive-playbook.sh: playbook 完了検出ロジックを共有
#
# 参照: docs/folder-management.md

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
DONE_PHASES=$(grep -c "^  status: done" "$FILE_PATH" 2>/dev/null || echo "0")

# Phase がない場合はスキップ
if [ "$TOTAL_PHASES" -eq 0 ]; then
    exit 0
fi

# 全 Phase が done でない場合はスキップ
if [ "$DONE_PHASES" -ne "$TOTAL_PHASES" ]; then
    exit 0
fi

# tmp/ フォルダが存在しない場合はスキップ
if [ ! -d "tmp" ]; then
    exit 0
fi

# tmp/ 内のファイルをカウント（README.md を除く）
TMP_FILES=$(find tmp -type f ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')

# 削除対象がない場合はスキップ
if [ "$TMP_FILES" -eq 0 ]; then
    exit 0
fi

# tmp/ 内のファイルを削除（README.md を除く）
find tmp -type f ! -name "README.md" -delete 2>/dev/null || true

# 空のサブディレクトリを削除
find tmp -type d -empty -delete 2>/dev/null || true

# リポジトリマップを自動更新
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAP_SCRIPT="$SCRIPT_DIR/generate-repository-map.sh"
MAP_RESULT=""
if [ -x "$MAP_SCRIPT" ]; then
    MAP_RESULT=$(bash "$MAP_SCRIPT" 2>&1 || true)
fi

# 進捗情報は state.md/playbook から取得（project.md は廃止済み）
TOTAL_MILESTONES="N/A"
ACHIEVED_MILESTONES="N/A"

# 通知を出力
cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🎉 Playbook 完了: $(basename "$FILE_PATH")
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  📊 Playbook: $(basename "$FILE_PATH") completed

  [1] テンポラリファイル クリーンアップ
      削除ファイル数: $TMP_FILES

  [2] リポジトリマップ 自動更新
      出力: docs/repository-map.yaml

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⚠️ /clear を実行してください
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  コンテキストがリフレッシュされ、
  次のタスクで動作が安定します。

  実行後、INIT が再実行され
  次の milestone に自動で進みます。
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

exit 0
