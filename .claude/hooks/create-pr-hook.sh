#!/bin/bash
# ============================================================
# create-pr-hook.sh - playbook 完了時の PR 自動作成フック
# ============================================================
# 発火条件: playbook の全 Phase が done になった後
# 目的: POST_LOOP で自動的に PR を作成
#
# このスクリプトは create-pr.sh のラッパーとして機能し、
# 以下の追加チェックを行います：
#   - playbook が完了しているか確認
#   - 未コミット変更がないか確認
#   - create-pr.sh を呼び出し
# ============================================================

set -euo pipefail

# ============================================================
# 設定
# ============================================================
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATE_FILE="$REPO_ROOT/state.md"
CREATE_PR_SCRIPT="$REPO_ROOT/.claude/hooks/create-pr.sh"
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

# create-pr.sh を実行
exec "$CREATE_PR_SCRIPT"
