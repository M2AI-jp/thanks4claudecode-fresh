#!/bin/bash
# ==============================================================================
# update-tracker.sh - PostToolUse:Edit/Write Hook: 変更追跡と自動更新提案
# ==============================================================================
#
# 目的:
#   - ファイル変更を追跡し、変更ログに記録
#   - 変更が蓄積されたら current-implementation.md の自動更新を促す
#   - 依存マップに基づいて関連ドキュメントを特定
#
# 発火: PostToolUse:Edit / PostToolUse:Write イベント
# 入力: { "tool": "Edit|Write", "params": { "file_path": "..." }, "result": {...} }
# 出力: systemMessage で更新提案（該当する場合のみ）
#
# ==============================================================================

set -e

# stdin から JSON を読み込む
INPUT=$(cat)

# 変更したファイルパスを取得
FILE_PATH=$(echo "$INPUT" | jq -r '.params.file_path // ""' 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

# ==============================================================================
# 1. 変更ログの記録
# ==============================================================================

LOG_DIR=".claude/logs"
CHANGE_LOG="$LOG_DIR/changes.log"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# 重要ファイルの変更のみ記録
SHOULD_LOG=false
case "$FILE_PATH" in
    *.claude/hooks/*|*.claude/agents/*|*.claude/skills/*|*.claude/frameworks/*|*.claude/settings.json|*plan/template/*)
        SHOULD_LOG=true
        ;;
esac

if [ "$SHOULD_LOG" = true ]; then
    # JSONL 形式で記録
    echo "{\"timestamp\":\"$TIMESTAMP\",\"file\":\"$FILE_PATH\",\"branch\":\"$BRANCH\"}" >> "$CHANGE_LOG"

    # ログが大きくなりすぎたら古いエントリを削除
    if [ -f "$CHANGE_LOG" ]; then
        LINE_COUNT=$(wc -l < "$CHANGE_LOG" | tr -d ' ')
        if [ "$LINE_COUNT" -gt 100 ]; then
            tail -n 100 "$CHANGE_LOG" > "$CHANGE_LOG.tmp"
            mv "$CHANGE_LOG.tmp" "$CHANGE_LOG"
        fi
    fi
fi

# ==============================================================================
# 2. 依存マップ定義（bash 3.2 互換）
# ==============================================================================

AFFECTED_DOCS=""
NEEDS_REGEN=false

# パターンマッチで判定
case "$FILE_PATH" in
    *.claude/hooks/*)
        AFFECTED_DOCS="docs/current-implementation.md"
        NEEDS_REGEN=true
        ;;
    *.claude/agents/*)
        AFFECTED_DOCS="docs/current-implementation.md"
        NEEDS_REGEN=true
        ;;
    *.claude/skills/*)
        AFFECTED_DOCS="docs/current-implementation.md"
        NEEDS_REGEN=true
        ;;
    *plan/template/*)
        AFFECTED_DOCS="docs/current-implementation.md"
        NEEDS_REGEN=true
        ;;
    *.claude/settings.json)
        AFFECTED_DOCS="docs/current-implementation.md"
        NEEDS_REGEN=true
        ;;
    *.claude/frameworks/*)
        AFFECTED_DOCS="docs/current-implementation.md"
        NEEDS_REGEN=true
        ;;
    docs/*)
        # docs/ へのファイル変更時は repository-map.yaml 自動更新を通知
        # repository-map.yaml 自体への変更は除外
        if [ "$FILE_PATH" != "docs/repository-map.yaml" ]; then
            cat << EOF
{
  "decision": "allow",
  "systemMessage": "[update-tracker] 📄 docs/ ファイル変更検出\n\n変更されたファイル: $FILE_PATH\n\nℹ️ repository-map.yaml は playbook 完了時に自動更新されます\n\n手動更新する場合:\n  bash .claude/hooks/generate-repository-map.sh"
}
EOF
        fi
        exit 0
        ;;
    *)
        # 該当なしなら終了
        exit 0
        ;;
esac

# ==============================================================================
# 3. 変更数をカウントして自動更新を判断
# ==============================================================================

CHANGE_COUNT=0
if [ -f "$CHANGE_LOG" ]; then
    # 直近1時間の変更をカウント
    ONE_HOUR_AGO=$(date -v-1H '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || date -d '1 hour ago' '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo "")
    if [ -n "$ONE_HOUR_AGO" ]; then
        CHANGE_COUNT=$(awk -v cutoff="$ONE_HOUR_AGO" -F'"' '$2 >= cutoff {count++} END {print count+0}' "$CHANGE_LOG" 2>/dev/null || echo "0")
    else
        CHANGE_COUNT=$(wc -l < "$CHANGE_LOG" | tr -d ' ')
    fi
fi

# ==============================================================================
# 4. 更新提案を出力
# ==============================================================================

if [ "$NEEDS_REGEN" = true ]; then
    if [ "$CHANGE_COUNT" -ge 5 ]; then
        # 5件以上の変更があれば自動生成を強く推奨
        cat << EOF
{
  "decision": "allow",
  "systemMessage": "[update-tracker] 🔄 ドキュメント自動更新が必要\n\n変更されたファイル: $FILE_PATH\n直近の変更: $CHANGE_COUNT 件\n\n⚠️ 多数の変更が蓄積されています。\n以下のコマンドで current-implementation.md を自動更新してください:\n\n  bash .claude/hooks/generate-implementation-doc.sh\n\nまたは、doc-updater SubAgent を呼び出して更新:\n  Task(subagent_type='Explore', prompt='generate-implementation-doc.sh を実行して current-implementation.md を更新')"
}
EOF
    else
        # 通常の更新提案
        cat << EOF
{
  "decision": "allow",
  "systemMessage": "[update-tracker] 📝 ドキュメント更新推奨\n\n変更されたファイル: $FILE_PATH\n\n以下のドキュメントも更新が必要かもしれません:\n  - docs/current-implementation.md\n\n自動更新コマンド:\n  bash .claude/hooks/generate-implementation-doc.sh"
}
EOF
    fi
fi

exit 0
