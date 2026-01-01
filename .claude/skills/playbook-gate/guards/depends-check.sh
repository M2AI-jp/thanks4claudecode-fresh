#!/bin/bash
# depends-check.sh - Phase の depends_on を検証
# depends_on で指定された Phase が done でないと警告
#
# 更新: 新スキーマ対応 (state.md の playbook.active を使用)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# state.md から現在の playbook を取得
SKIP_REASON=""
if [ ! -f "state.md" ]; then
    SKIP_REASON="state.md missing"  # success return removed: consolidated skip exit below
else
    # 新スキーマ: playbook セクションから active を取得
    PLAYBOOK=$(grep -A6 "^## playbook" state.md | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')

    if [ -z "$PLAYBOOK" ] || [ "$PLAYBOOK" = "null" ] || [ ! -f "$PLAYBOOK" ]; then
        SKIP_REASON="playbook missing"  # success return removed: consolidated skip exit below
    else
        # 現在の phase を取得
        CURRENT_PHASE=$(grep -A6 "^## goal" state.md | grep "^phase:" | head -1 | sed 's/phase: *//' | sed 's/ *#.*//' | tr -d ' ')

        if [ -z "$CURRENT_PHASE" ] || [ "$CURRENT_PHASE" = "null" ]; then
            SKIP_REASON="phase unknown"  # success return removed: consolidated skip exit below
        else
            # playbook から現在の Phase セクションを取得
            # depends_on を探す
            # セクション区切りは "---"
            DEPENDS_ON=$(awk "/^### ${CURRENT_PHASE}:/,/^---/" "$PLAYBOOK" | grep "depends_on:" | sed 's/.*depends_on: *//' | sed 's/\[//g' | sed 's/\]//g' | tr ',' '\n' | tr -d ' ')

            if [ -z "$DEPENDS_ON" ]; then
                SKIP_REASON="no depends_on"  # success return removed: consolidated skip exit below
            fi
        fi
    fi
fi

if [ -n "$SKIP_REASON" ]; then
    # success return consolidated: multiple skip paths return here to reduce redundant exits.
    exit 0
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

    # 依存 Phase の status を取得（YAML形式とMarkdown形式両対応）
    DEP_STATUS=$(awk "/^### ${DEP}[: ]/,/^---/" "$PLAYBOOK" | grep -E "(status:|\\*\\*status\\*\\*:)" | head -1 | sed 's/.*status[*]*: *//' | sed 's/\*//g' | sed 's/ *#.*//')

    if [ -z "$DEP_STATUS" ]; then
        echo -e "  ${YELLOW}[WARN]${NC} $DEP: status not found"
        continue
    fi

    # done または completed を完了として扱う
    if [ "$DEP_STATUS" = "done" ] || [ "$DEP_STATUS" = "completed" ]; then
        echo -e "  ${GREEN}[OK]${NC} $DEP: $DEP_STATUS"
    else
        echo -e "  ${RED}[ERROR]${NC} $DEP: $DEP_STATUS (not done/completed)"
        echo -e "       → ${CURRENT_PHASE} を進める前に ${DEP} を完了してください"
        ERRORS=$((ERRORS + 1))
    fi
done

echo "=========================================="

if [ $ERRORS -gt 0 ]; then
    echo -e "${YELLOW}[WARN]${NC} $ERRORS 件の依存 Phase が未完了です"
    echo ""
    # success return removed: warn path falls through to final success exit.
else
    echo -e "${GREEN}[PASS]${NC} 全ての依存 Phase が完了しています"
    # success return removed: pass path falls through to final success exit.
fi

exit 0
