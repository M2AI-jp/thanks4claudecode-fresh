#!/bin/bash
# depends-check.sh - Phase の depends_on を検証
# depends_on で指定された Phase が done でないと警告

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# state.md から現在の playbook を取得
if [ ! -f "state.md" ]; then
    exit 0  # state.md がない場合はスキップ
fi

# focus.current を取得
FOCUS=$(grep -A5 "## focus" state.md | grep "current:" | sed 's/.*current: *//' | sed 's/ *#.*//')

# active_playbooks から playbook パスを取得
PLAYBOOK=$(awk "/## active_playbooks/,/^## [^a]/" state.md | grep "^${FOCUS}:" | sed "s/${FOCUS}: *//" | sed 's/ *#.*//')

if [ -z "$PLAYBOOK" ] || [ "$PLAYBOOK" = "null" ] || [ ! -f "$PLAYBOOK" ]; then
    exit 0  # playbook がない場合はスキップ
fi

# 現在の phase を取得
CURRENT_PHASE=$(awk "/## goal/,/^## [^g]/" state.md | grep "phase:" | head -1 | sed 's/.*phase: *//' | sed 's/ *#.*//')

if [ -z "$CURRENT_PHASE" ]; then
    exit 0  # phase が不明な場合はスキップ
fi

# playbook から現在の Phase セクションを取得
# depends_on を探す
# セクション区切りは "---"
DEPENDS_ON=$(awk "/^### ${CURRENT_PHASE}:/,/^---/" "$PLAYBOOK" | grep "depends_on:" | sed 's/.*depends_on: *//' | sed 's/\[//g' | sed 's/\]//g' | tr ',' '\n' | tr -d ' ')

if [ -z "$DEPENDS_ON" ]; then
    exit 0  # depends_on がない場合はスキップ
fi

echo ""
echo "=========================================="
echo "  Depends Check: $CURRENT_PHASE"
echo "=========================================="

ERRORS=0

for DEP in $DEPENDS_ON; do
    if [ -z "$DEP" ]; then
        continue
    fi

    # 依存 Phase の status を取得
    DEP_STATUS=$(awk "/^### ${DEP}:/,/^---/" "$PLAYBOOK" | grep "status:" | head -1 | sed 's/.*status: *//' | sed 's/ *#.*//')

    if [ -z "$DEP_STATUS" ]; then
        echo -e "  ${YELLOW}[WARN]${NC} $DEP: status not found"
        continue
    fi

    if [ "$DEP_STATUS" = "done" ]; then
        echo -e "  ${GREEN}[OK]${NC} $DEP: done"
    else
        echo -e "  ${RED}[ERROR]${NC} $DEP: $DEP_STATUS (not done)"
        echo -e "       → ${CURRENT_PHASE} を進める前に ${DEP} を完了してください"
        ERRORS=$((ERRORS + 1))
    fi
done

echo "=========================================="

if [ $ERRORS -gt 0 ]; then
    echo -e "${YELLOW}[WARN]${NC} $ERRORS 件の依存 Phase が未完了です"
    echo ""
    # 警告のみで exit 0（ブロックしない）
    # 将来的に exit 2 でブロックする場合はコメント解除
    # exit 2
    exit 0
else
    echo -e "${GREEN}[PASS]${NC} 全ての依存 Phase が完了しています"
    exit 0
fi
