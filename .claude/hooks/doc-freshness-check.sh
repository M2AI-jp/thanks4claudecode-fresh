#!/bin/bash
# ==============================================================================
# doc-freshness-check.sh - PostToolUse:Read Hook: ドキュメント鮮度チェック
# ==============================================================================
#
# 目的:
#   - 重要ドキュメントを読み込んだ時に、そのドキュメントが最新かチェック
#   - 関連ファイルの更新日と比較し、乖離があれば警告
#
# 発火: PostToolUse:Read イベント
# 入力: { "tool": "Read", "params": { "file_path": "..." }, "result": {...} }
# 出力: systemMessage で警告（問題がある場合のみ）
#
# ==============================================================================

set -e

# stdin から JSON を読み込む
INPUT=$(cat)

# 読み込んだファイルパスを取得
FILE_PATH=$(echo "$INPUT" | jq -r '.params.file_path // ""' 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

# ファイル名のみ取得
FILE_NAME=$(basename "$FILE_PATH")

# ==============================================================================
# 1. 重要ドキュメントの定義と関連ファイル（bash 3.2 互換）
# ==============================================================================

RELATED_PATHS=""

case "$FILE_NAME" in
    "current-implementation.md")
        RELATED_PATHS=".claude/hooks .claude/agents .claude/skills"
        ;;
    "CLAUDE.md")
        RELATED_PATHS="state.md plan/template/playbook-format.md"
        ;;
    "extension-system.md")
        RELATED_PATHS=".claude/settings.json"
        ;;
    *)
        # 対象外なら何もしない（軽量に終了）
        exit 0
        ;;
esac

# ==============================================================================
# 2. 鮮度チェック
# ==============================================================================

# 読み込んだファイルの最終更新日（git log から取得）
DOC_DATE=$(git log -1 --format="%ci" -- "$FILE_PATH" 2>/dev/null | cut -d' ' -f1)
[ -z "$DOC_DATE" ] && exit 0

# 関連ファイルの最新更新日を取得
NEWEST_RELATED=""
NEWEST_RELATED_PATH=""

for RELATED_PATH in $RELATED_PATHS; do
    if [ -d "$RELATED_PATH" ]; then
        # ディレクトリの場合、配下のファイルを検索
        LATEST=$(git log -1 --format="%ci" -- "$RELATED_PATH" 2>/dev/null | cut -d' ' -f1)
    elif [ -f "$RELATED_PATH" ]; then
        LATEST=$(git log -1 --format="%ci" -- "$RELATED_PATH" 2>/dev/null | cut -d' ' -f1)
    else
        continue
    fi

    if [ -n "$LATEST" ]; then
        if [ -z "$NEWEST_RELATED" ] || [[ "$LATEST" > "$NEWEST_RELATED" ]]; then
            NEWEST_RELATED="$LATEST"
            NEWEST_RELATED_PATH="$RELATED_PATH"
        fi
    fi
done

# 比較対象がなければ終了
[ -z "$NEWEST_RELATED" ] && exit 0

# ==============================================================================
# 3. 日付比較（3日以上の乖離で警告）
# ==============================================================================

# macOS と Linux の両方に対応した日付計算
if [[ "$(uname)" == "Darwin" ]]; then
    DOC_EPOCH=$(date -j -f "%Y-%m-%d" "$DOC_DATE" "+%s" 2>/dev/null || echo "0")
    RELATED_EPOCH=$(date -j -f "%Y-%m-%d" "$NEWEST_RELATED" "+%s" 2>/dev/null || echo "0")
else
    DOC_EPOCH=$(date -d "$DOC_DATE" "+%s" 2>/dev/null || echo "0")
    RELATED_EPOCH=$(date -d "$NEWEST_RELATED" "+%s" 2>/dev/null || echo "0")
fi

# ドキュメントが関連ファイルより古い場合
if [ "$DOC_EPOCH" -lt "$RELATED_EPOCH" ]; then
    DIFF_DAYS=$(( (RELATED_EPOCH - DOC_EPOCH) / 86400 ))

    # 3日以上の乖離で警告 + 自動修復提案
    if [ "$DIFF_DAYS" -ge 3 ]; then
        # current-implementation.md の場合は自動生成を提案
        if [ "$FILE_NAME" = "current-implementation.md" ]; then
            cat << EOF
{
  "decision": "allow",
  "systemMessage": "[doc-freshness-check] 🔄 ドキュメント陳腐化 → 自動修復推奨\n\n読み込んだファイル: $FILE_NAME\n最終更新: $DOC_DATE\n\n関連ファイル($NEWEST_RELATED_PATH)は $NEWEST_RELATED に更新されています。\nドキュメントが $DIFF_DAYS 日古い可能性があります。\n\n【自動修復コマンド】\n  bash .claude/hooks/generate-implementation-doc.sh\n\n上記を実行すると、最新の実装状況から current-implementation.md を自動生成します。"
}
EOF
        else
            cat << EOF
{
  "decision": "allow",
  "systemMessage": "[doc-freshness-check] ⚠️ ドキュメント鮮度警告\n\n読み込んだファイル: $FILE_NAME\n最終更新: $DOC_DATE\n\n関連ファイル($NEWEST_RELATED_PATH)は $NEWEST_RELATED に更新されています。\nドキュメントが $DIFF_DAYS 日古い可能性があります。\n\n最新の情報は関連ファイルを直接確認してください。"
}
EOF
        fi
        exit 0
    fi
fi

# 問題なし
exit 0
