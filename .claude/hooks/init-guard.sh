#!/bin/bash
# ==============================================================================
# init-guard.sh - セッション開始時の強制的自己認識ガード
# ==============================================================================
# 目的: 必須ファイルが Read されるまで他のツールをブロック
# トリガー: PreToolUse (*)
# ==============================================================================

set -euo pipefail

# 状態管理ディレクトリ
INIT_DIR=".claude/.session-init"
PENDING_FILE="$INIT_DIR/pending"
READ_DIR="$INIT_DIR/read"

# 入力JSONを読み取り
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')

# --------------------------------------------------
# 必須ファイルの定義（focus 別に分岐）
# --------------------------------------------------
# focus を state.md から取得
FOCUS=""
if [[ -f "state.md" ]]; then
    FOCUS=$(grep -A5 "## focus" state.md | grep "current:" | sed 's/.*: *//' | sed 's/ *#.*//')
fi

# 必須ファイル: state.md のみ
# CONTEXT.md は .archive に退避済み（開発履歴）
# 設計思想は CLAUDE.md と architecture-*.md を参照
REQUIRED_FILES=(
    "state.md"
)

# playbook は state.md から動的に取得（session-start.sh で設定済み）
if [[ -f "$INIT_DIR/required_playbook" ]]; then
    PLAYBOOK=$(cat "$INIT_DIR/required_playbook")
    if [[ -n "$PLAYBOOK" && "$PLAYBOOK" != "null" ]]; then
        REQUIRED_FILES+=("$PLAYBOOK")
    fi
fi

# --------------------------------------------------
# 関数: 全必須ファイルが Read されたか確認
# --------------------------------------------------
check_all_read() {
    if [[ ! -d "$READ_DIR" ]]; then
        return 1
    fi

    for file in "${REQUIRED_FILES[@]}"; do
        local basename_file=$(basename "$file")
        if [[ ! -f "$READ_DIR/$basename_file" ]]; then
            return 1
        fi
    done

    return 0
}

# --------------------------------------------------
# 関数: 残りの必須ファイルをリスト
# --------------------------------------------------
get_remaining_files() {
    local remaining=()
    for file in "${REQUIRED_FILES[@]}"; do
        local basename_file=$(basename "$file")
        if [[ ! -f "$READ_DIR/$basename_file" ]]; then
            remaining+=("$file")
        fi
    done
    echo "${remaining[*]}"
}

# --------------------------------------------------
# メイン処理
# --------------------------------------------------

# pending ファイルが存在しない = 初期化完了済み or 未開始
if [[ ! -f "$PENDING_FILE" ]]; then
    exit 0
fi

# Read ツールの場合: ファイルを記録
if [[ "$TOOL_NAME" == "Read" ]]; then
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')

    if [[ -n "$FILE_PATH" ]]; then
        BASENAME=$(basename "$FILE_PATH")
        mkdir -p "$READ_DIR"
        touch "$READ_DIR/$BASENAME"

        # 全て読まれたか確認
        if check_all_read; then
            # 初期化完了
            rm -f "$PENDING_FILE"
            rm -rf "$READ_DIR"
            echo "✅ 必須ファイルの Read が完了しました。作業を開始できます。"
        fi
    fi

    exit 0
fi

# Grep/Glob も情報収集用なので許可
if [[ "$TOOL_NAME" == "Grep" || "$TOOL_NAME" == "Glob" ]]; then
    exit 0
fi

# git コマンドを許可（状態確認用 + ブランチ切り替え用）
if [[ "$TOOL_NAME" == "Bash" ]]; then
    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty')
    # 状態確認コマンド
    if [[ "$COMMAND" =~ ^git\ (status|branch|rev-parse|log|diff) ]]; then
        exit 0
    fi
    # ブランチ切り替えコマンド
    if [[ "$COMMAND" =~ ^git\ (checkout|switch|stash) ]]; then
        exit 0
    fi
fi

# その他のツール: 必須ファイルが Read されていなければブロック
REMAINING=$(get_remaining_files)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "  ⛔ 初期化未完了 - ツール使用をブロック" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "  以下のファイルを Read してください:" >&2
for file in $REMAINING; do
    echo "    - $file" >&2
done
echo "" >&2
echo "  必須ファイルを Read するまで $TOOL_NAME は使用できません。" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

exit 2
