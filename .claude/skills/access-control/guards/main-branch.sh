#!/bin/bash
# main-branch.sh - main ブランチでの作業をブロック
#
# PreToolUse(*) フックとして実行される。
# main/master ブランチでの編集系ツール使用を常にブロック。
#
# 設計思想:
#   - main ブランチは保護対象（常にブランチを切って作業）
#   - Claude が playbook 作成時に自動でブランチを切る
#   - ユーザーの手動ブランチ操作は不要
#
# ブロック条件:
#   - main/master ブランチ + Edit/Write/Bash(変更系)
#
# 例外（常に許可）:
#   - Read/Glob/Grep ツール（読み取りのみ）
#   - state.md への編集（デッドロック回避）
#   - git 操作コマンド（ブランチ切り替え等）

set -e

# 現在のブランチを取得
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# main ブランチでなければスキップ
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    exit 0
fi

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# ツール名を取得
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Read ツールは許可（読み取りのみ）
if [ "$TOOL_NAME" = "Read" ] || [ "$TOOL_NAME" = "Glob" ] || [ "$TOOL_NAME" = "Grep" ]; then
    exit 0
fi

# state.md への編集は許可（デッドロック回避）
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
    if [[ "$FILE_PATH" == *"state.md" ]]; then
        exit 0
    fi
fi

# Bash の場合、許可されたコマンドはスキップ
if [ "$TOOL_NAME" = "Bash" ]; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

    # session-state/ 操作は許可（post-loop 完了処理用）
    if [[ "$COMMAND" == *"session-state"* ]] || \
       [[ "$COMMAND" == *"complete.sh"* ]]; then
        exit 0
    fi

    # git 操作は基本的に許可（main での作業禁止は Edit/Write が対象）
    # ブランチ操作: checkout, switch, branch
    # 同期操作: pull, fetch, push
    # 確認操作: status, log, diff
    # 統合操作: merge, add, commit, stash, rebase
    if [[ "$COMMAND" == *"git checkout"* ]] || \
       [[ "$COMMAND" == *"git switch"* ]] || \
       [[ "$COMMAND" == *"git branch"* ]] || \
       [[ "$COMMAND" == *"git pull"* ]] || \
       [[ "$COMMAND" == *"git fetch"* ]] || \
       [[ "$COMMAND" == *"git status"* ]] || \
       [[ "$COMMAND" == *"git log"* ]] || \
       [[ "$COMMAND" == *"git diff"* ]] || \
       [[ "$COMMAND" == *"git push"* ]] || \
       [[ "$COMMAND" == *"git merge"* ]] || \
       [[ "$COMMAND" == *"git add"* ]] || \
       [[ "$COMMAND" == *"git commit"* ]] || \
       [[ "$COMMAND" == *"git stash"* ]] || \
       [[ "$COMMAND" == *"git rebase"* ]]; then
        exit 0
    fi
fi

# それ以外はブロック
echo "" >&2
echo "========================================" >&2
echo "  🚨 main ブランチでの作業は禁止" >&2
echo "========================================" >&2
echo "" >&2
echo "  branch: $CURRENT_BRANCH" >&2
echo "  tool: $TOOL_NAME" >&2
echo "" >&2
echo "  playbook を作成すると自動でブランチが作成されます。" >&2
echo "  手動で作成する場合: git checkout -b {type}/{description}" >&2
echo "" >&2
echo "========================================" >&2

# exit 2 = ブロック（Claude Code 公式仕様）
exit 2
