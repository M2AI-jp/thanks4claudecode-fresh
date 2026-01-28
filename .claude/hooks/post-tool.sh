#!/bin/bash
# post-tool.sh - PostToolUse(*) 導火線
# ツール実行後の処理を Skills に委譲

set -euo pipefail

# === reviewer 証拠永続化チェック ===
# reviewed: true を設定する際、evidence が必須
check_reviewer_evidence() {
    local input="$1"
    local tool_name
    tool_name=$(echo "$input" | jq -r '.tool_name // empty')

    if [[ "$tool_name" == "Edit" || "$tool_name" == "Write" ]]; then
        local file_path
        file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

        # plan.json への書き込みで reviewed: true が含まれる場合
        if [[ "$file_path" == *"plan.json" ]]; then
            local content
            content=$(echo "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')

            if echo "$content" | grep -q '"reviewed": true'; then
                # reviewer_evidence が空でないか確認
                # （実際の検証は progress.json を確認する必要がある）
                echo "[WARN] reviewed: true が設定されました。reviewer_evidence を確認してください。" >&2
            fi
        fi
    fi
}


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/../skills"
EVENTS_DIR="$SCRIPT_DIR/../events"
LIB_DIR="$SCRIPT_DIR/../lib"

# 共通ライブラリ読み込み
if [[ -f "$LIB_DIR/common.sh" ]]; then
    source "$LIB_DIR/common.sh"
fi

# 入力を読み込み
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Skill を呼び出す関数（失敗しても継続）
invoke_skill() {
    local skill="$1"
    local script="$2"
    local path="$SKILLS_DIR/$skill/$script"
    if [[ -x "$path" ]]; then
        echo "$INPUT" | bash "$path" || true
    fi
}

invoke_event_chain() {
    local unit="$1"
    local path="$EVENTS_DIR/$unit/chain.sh"
    if [[ -f "$path" ]]; then
        echo "$INPUT" | bash "$path"
    fi
}

case "$TOOL_NAME" in
    Edit|Write)
        invoke_event_chain "post-tool-edit"
        ;;
    Task)
        # SubAgent ログ記録（必要に応じて）
        ;;
esac

exit 0
