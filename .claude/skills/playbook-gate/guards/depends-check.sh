#!/bin/bash
# depends-check.sh - Phase の depends_on を検証（playbook v2 / JSON）
# depends_on で指定された Phase が done でないと警告
#
# 更新: play/<id>/plan.json + progress.json を使用

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

STATE_FILE="${STATE_FILE:-state.md}"

# state.md から現在の playbook を取得
if [ ! -f "$STATE_FILE" ]; then
    exit 0  # state.md がない場合はスキップ
fi

if ! command -v jq &> /dev/null; then
    exit 0  # jq がない場合はスキップ（他ガードでブロック）
fi

# playbook セクションから active を取得
PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')

if [ -z "$PLAYBOOK" ] || [ "$PLAYBOOK" = "null" ] || [ ! -f "$PLAYBOOK" ]; then
    exit 0  # playbook がない場合はスキップ
fi

PLAYBOOK_DIR=$(dirname "$PLAYBOOK")
PLAN_PATH="$PLAYBOOK"
PROGRESS_PATH="$PLAYBOOK_DIR/progress.json"

if [ ! -f "$PROGRESS_PATH" ]; then
    exit 0
fi

# 現在の phase を取得（progress.json 優先、state.md は fallback）
CURRENT_PHASE=$(jq -r '.active.phase // empty' "$PROGRESS_PATH")
if [ -z "$CURRENT_PHASE" ] || [ "$CURRENT_PHASE" = "null" ]; then
    CURRENT_PHASE=$(grep -A6 "^## goal" "$STATE_FILE" | grep "^phase:" | head -1 | sed 's/phase: *//' | sed 's/ *#.*//' | tr -d ' ')
fi

if [ -z "$CURRENT_PHASE" ] || [ "$CURRENT_PHASE" = "null" ]; then
    exit 0  # phase が不明な場合はスキップ
fi

DEPENDS_ON=$(jq -r --arg phase "$CURRENT_PHASE" '.phases[] | select(.id == $phase) | .depends_on[]? // empty' "$PLAN_PATH")

if [ -z "$DEPENDS_ON" ]; then
    exit 0  # depends_on がない場合はスキップ
fi

echo ""
echo "=========================================="
echo "  Depends Check: $CURRENT_PHASE"
echo "=========================================="

ERRORS=0

while IFS= read -r dep; do
    if [ -z "$dep" ]; then
        continue
    fi

    DEP_STATUS=$(jq -r --arg dep "$dep" '.phases[$dep].status // empty' "$PROGRESS_PATH")
    if [ -z "$DEP_STATUS" ] || [ "$DEP_STATUS" = "null" ]; then
        echo -e "  ${YELLOW}[WARN]${NC} $dep: status not found"
        continue
    fi

    if [ "$DEP_STATUS" = "done" ] || [ "$DEP_STATUS" = "completed" ]; then
        echo -e "  ${GREEN}[OK]${NC} $dep: $DEP_STATUS"
    else
        echo -e "  ${RED}[ERROR]${NC} $dep: $DEP_STATUS (not done/completed)"
        echo -e "       → ${CURRENT_PHASE} を進める前に ${dep} を完了してください"
        ERRORS=$((ERRORS + 1))
    fi
done <<< "$DEPENDS_ON"

echo "=========================================="

if [ $ERRORS -gt 0 ]; then
    echo -e "${YELLOW}[WARN]${NC} $ERRORS 件の依存 Phase が未完了です"
    echo ""
    exit 0  # 警告のみ
fi

echo -e "${GREEN}[PASS]${NC} 全ての依存 Phase が完了しています"
exit 0
