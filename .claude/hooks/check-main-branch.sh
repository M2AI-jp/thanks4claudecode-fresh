#!/bin/bash
# check-main-branch.sh - main ブランチでの作業をブロック
#
# PreToolUse(*) フックとして実行される。
# main ブランチ かつ focus=workspace の場合、編集系ツール使用をブロック
#
# 設計思想（アクションベース Guards）:
#   - Edit/Write などの編集アクション時にチェック
#   - Read/Grep は常に許可
#
# ブロック条件:
#   - main/master ブランチ
#   - focus.current = workspace
#
# 許可条件（main ブランチでも作業可能）:
#   - focus.current = setup   → 新規ユーザーのセットアップ
#   - focus.current = product → 新規ユーザーのプロダクト開発
#
# 例外（常に許可）:
#   - git checkout / git switch（ブランチ切り替え用）
#   - git branch（ブランチ確認用）
#   - Read ツール（読み取りのみ）

set -e

# state.md が存在しない場合はスキップ
if [ ! -f "state.md" ]; then
    exit 0
fi

# focus.current を取得
FOCUS=$(grep "current:" state.md | head -1 | sed 's/.*current: *//' | sed 's/ *#.*//')

# setup / product / plan-template なら main ブランチでも許可
# （新規ユーザーの作業は main ブランチで行われる）
if [ "$FOCUS" = "setup" ] || [ "$FOCUS" = "product" ] || [ "$FOCUS" = "plan-template" ]; then
    exit 0
fi

# focus=workspace の場合のみ main ブランチチェック
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

# Bash の場合、許可された git コマンドはスキップ
if [ "$TOOL_NAME" = "Bash" ]; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

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
echo "  focus: workspace" >&2
echo "  branch: $CURRENT_BRANCH" >&2
echo "  tool: $TOOL_NAME" >&2
echo "" >&2
echo "  作業を開始する前に、必ずブランチを作成してください:" >&2
echo "  git checkout -b {fix|feat|refactor}/{description}" >&2
echo "" >&2
echo "========================================" >&2

# exit 2 = ブロック（Claude Code 公式仕様）
exit 2
