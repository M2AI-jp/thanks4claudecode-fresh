#!/bin/bash
# ============================================================
# create-pr-hook.sh - playbook 完了時の PR 自動作成 + マージフック
# ============================================================
# 発火条件: playbook の全 Phase が done になった後
# 目的: POST_LOOP で PR 作成からマージまでを自動実行
#
# このスクリプトは以下を順次実行:
#   1. playbook が完了しているか確認
#   2. 未コミット変更がないか確認
#   3. create-pr.sh で PR 作成
#   4. merge-pr.sh で PR マージ + main checkout + pull
# ============================================================

set -euo pipefail

# ============================================================
# 設定
# ============================================================
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATE_FILE="$REPO_ROOT/state.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREATE_PR_SCRIPT="$SCRIPT_DIR/create-pr.sh"
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================
# 前提条件チェック
# ============================================================

# create-pr.sh の存在確認
if [ ! -x "$CREATE_PR_SCRIPT" ]; then
    echo -e "${RED}[ERROR]${NC} create-pr.sh が見つからないか、実行権限がありません"
    echo "  $CREATE_PR_SCRIPT"
    exit 1
fi

# state.md の存在確認
if [ ! -f "$STATE_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} state.md が見つかりません"
    exit 1
fi

# ============================================================
# playbook 完了チェック
# ============================================================

# active playbook を取得
PLAYBOOK_PATH=$(grep -A5 "## playbook" "$STATE_FILE" 2>/dev/null | grep "active:" | sed 's/.*: *//' | sed 's/ *#.*//' || echo "null")

if [ "$PLAYBOOK_PATH" = "null" ] || [ -z "$PLAYBOOK_PATH" ]; then
    echo -e "${YELLOW}[SKIP]${NC} アクティブな playbook がありません"
    exit 0
fi

if [ ! -f "$REPO_ROOT/$PLAYBOOK_PATH" ]; then
    echo -e "${RED}[ERROR]${NC} playbook が見つかりません: $PLAYBOOK_PATH"
    exit 1
fi

PLAYBOOK_FILE="$REPO_ROOT/$PLAYBOOK_PATH"

# 全 Phase が done かチェック
# status: pending または in_progress があれば未完了
INCOMPLETE_PHASES=$(grep -cE "status: (pending|in_progress)" "$PLAYBOOK_FILE" 2>/dev/null || echo "0")

if [ "$INCOMPLETE_PHASES" -gt 0 ]; then
    echo -e "${YELLOW}[SKIP]${NC} playbook に未完了の Phase があります ($INCOMPLETE_PHASES 件)"
    exit 0
fi

# ============================================================
# 未コミット変更チェック
# ============================================================

UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

if [ "$UNCOMMITTED" -gt 0 ]; then
    echo ""
    echo "$SEP"
    echo -e "  ${YELLOW}⚠️ 未コミット変更があります${NC}"
    echo "$SEP"
    echo ""
    echo "  PR 作成前にコミットしてください:"
    echo "    git add -A && git commit -m \"feat: playbook 完了\""
    echo ""
    exit 1
fi

# ============================================================
# PR 作成
# ============================================================

echo ""
echo "$SEP"
echo "  🚀 PR 自動作成を開始します"
echo "$SEP"
echo ""
echo "  Playbook: $PLAYBOOK_PATH"
echo "  全 Phase: done"
echo ""

# create-pr.sh を実行（exec ではなく通常呼び出しで exit code を取得）
"$CREATE_PR_SCRIPT"
PR_EXIT_CODE=$?

if [ $PR_EXIT_CODE -eq 0 ]; then
    # PR 作成成功 → マージを実行
    echo ""
    echo "$SEP"
    echo "  🔄 PR マージを開始します"
    echo "$SEP"
    echo ""

    MERGE_SCRIPT="$SCRIPT_DIR/merge-pr.sh"
    if [ -x "$MERGE_SCRIPT" ]; then
        "$MERGE_SCRIPT"
        MERGE_EXIT_CODE=$?
        if [ $MERGE_EXIT_CODE -ne 0 ]; then
            echo -e "${RED}[ERROR]${NC} PR マージに失敗しました (exit code: $MERGE_EXIT_CODE)"
            echo ""
            echo "  手動で確認してください:"
            echo "    gh pr view"
            echo "    gh pr checks"
            exit 1
        fi
    else
        echo -e "${RED}[ERROR]${NC} merge-pr.sh が見つかりません: $MERGE_SCRIPT"
        exit 1
    fi
elif [ $PR_EXIT_CODE -eq 2 ]; then
    # スキップ（PR 既存等）
    echo -e "${YELLOW}[SKIP]${NC} PR 作成がスキップされたため、マージも実行しません"
    exit 0
else
    # エラー
    echo -e "${RED}[ERROR]${NC} PR 作成に失敗しました (exit code: $PR_EXIT_CODE)"
    exit 1
fi

echo ""
echo "$SEP"
echo "  ✅ PR 作成からマージまで完了しました"
echo "$SEP"
echo ""
