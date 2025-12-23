#!/bin/bash
# ==============================================================================
# init-guard.sh - セッション開始時の強制的自己認識ガード
# ==============================================================================
# 目的: 必須ファイルが Read されるまで他のツールをブロック
# トリガー: PreToolUse (*)
# ==============================================================================

set -euo pipefail

# ==============================================================================
# state-schema.sh を source して state.md のスキーマを参照
# ==============================================================================
source .claude/schema/state-schema.sh

# 状態管理ディレクトリ
INIT_DIR=".claude/.session-init"
PENDING_FILE="$INIT_DIR/pending"
READ_DIR="$INIT_DIR/read"

# 入力JSONを読み取り
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')

# --------------------------------------------------
# security チェック（admin モードはバイパス）
# --------------------------------------------------
SECURITY_MODE=""
if [[ -f "state.md" ]]; then
      SECURITY_MODE=$(grep "^security:" state.md | head -1 | sed 's/security: *//' | sed 's/ *#.*//' | tr -d ' ')
fi

# admin モードでも playbook チェックは維持（2025-12-14 修正）
# admin がバイパスするのは「必須ファイル Read チェック」のみ
ADMIN_MODE=false
if [[ "$SECURITY_MODE" == "admin" ]]; then
    ADMIN_MODE=true
fi

# --------------------------------------------------
# 必須ファイルの定義（focus 別に分岐）
# --------------------------------------------------
# focus を state-schema.sh から取得
FOCUS=""
if [[ -f "state.md" ]]; then
    FOCUS=$(get_focus_current)
fi

# 必須ファイル: state.md のみ
REQUIRED_FILES=(
    "state.md"
)

# playbook は state.md から動的に取得（session-start.sh で設定済み）
# デッドロック対策: playbook ファイルが実際に存在する場合のみ REQUIRED_FILES に追加
if [[ -f "$INIT_DIR/required_playbook" ]]; then
    PLAYBOOK=$(cat "$INIT_DIR/required_playbook")
    if [[ -n "$PLAYBOOK" && "$PLAYBOOK" != "null" ]]; then
        if [[ -f "$PLAYBOOK" ]]; then
            REQUIRED_FILES+=("$PLAYBOOK")
        else
            # フォールバック: 存在しない playbook は必須から除外（デッドロック回避）
            echo "⚠️ playbook ファイルが存在しません: $PLAYBOOK" >&2
            echo "  → 必須 Read 対象から除外しました（デッドロック回避）" >&2
        fi
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
# 【単一責任原則】init-guard.sh は「必須ファイル Read 強制」のみを担当
# playbook 存在チェックは playbook-guard.sh が担当（Edit/Write 時に発火）
# Bash コマンドは全て許可（情報収集に制限を設けない）

# pending ファイルが存在しない = 初期化完了済み or 未開始
if [[ ! -f "$PENDING_FILE" ]]; then
    exit 0
fi

# admin モードは必須ファイル Read チェックをバイパス
if [[ "$ADMIN_MODE" == "true" ]]; then
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

# Bash コマンドの許可ロジック
if [[ "$TOOL_NAME" == "Bash" ]]; then
    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

    # M021: 基本コマンドを許可（情報収集に制限を設けない）
    # sed, grep, cat, echo, ls, wc, head, tail は常に許可
    if [[ "$COMMAND" =~ ^(sed|grep|cat|echo|ls|wc|head|tail|pwd|which|type|file)[[:space:]] ]] || \
       [[ "$COMMAND" =~ ^(sed|grep|cat|echo|ls|wc|head|tail|pwd|which|type|file)$ ]]; then
        exit 0
    fi

    # git コマンド: 状態確認 + ブランチ操作 + show（M021 修正）
    if [[ "$COMMAND" =~ ^git\ (status|branch|rev-parse|log|diff|show) ]]; then
        exit 0
    fi
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
