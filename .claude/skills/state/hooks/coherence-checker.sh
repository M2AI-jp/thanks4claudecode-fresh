#!/bin/bash
# ==============================================================================
# coherence-checker.sh - 三つ組整合性チェック Hook
# ==============================================================================
# 目的: state.md, playbook, git branch の整合性を検証
# トリガー: SessionStart または手動実行
#
# 設計思想:
#   - 「三つ組」の整合性を維持することで状態の乖離を防止
#   - 不整合があればセッション開始時に警告
#   - 深刻な不整合はブロック（exit 2）
#
# 三つ組:
#   1. state.md の playbook.active
#   2. playbook ファイルの存在と内容
#   3. git の現在ブランチ
#
# 参照: .claude/skills/state/SKILL.md
# ==============================================================================

set -euo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo ""
echo "=========================================="
echo "  [coherence-checker] 三つ組整合性チェック"
echo "=========================================="

# --------------------------------------------------
# 1. state.md の存在チェック
# --------------------------------------------------

if [[ ! -f "$STATE_FILE" ]]; then
    echo -e "${RED}[ERROR]${NC} state.md が存在しません"
    exit 2
fi

# --------------------------------------------------
# 2. playbook の整合性チェック
# --------------------------------------------------

echo ""
echo "  --- Playbook ---"

ACTIVE_PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')

if [[ -z "$ACTIVE_PLAYBOOK" || "$ACTIVE_PLAYBOOK" == "null" ]]; then
    echo -e "    ${YELLOW}[INFO]${NC} アクティブな playbook なし"
else
    echo -e "    Active: $ACTIVE_PLAYBOOK"
    if [[ -f "$ACTIVE_PLAYBOOK" ]]; then
        # playbook の reviewed フラグをチェック
        REVIEWED=$(grep -E "^reviewed:" "$ACTIVE_PLAYBOOK" 2>/dev/null | head -1 | sed 's/reviewed: *//' | sed 's/ *#.*//' | tr -d ' ')
        if [[ "$REVIEWED" == "false" ]]; then
            echo -e "    ${YELLOW}[WARN]${NC} reviewed: false（レビュー未完了）"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "    ${GREEN}[OK]${NC} playbook 存在"
        fi
    else
        echo -e "    ${RED}[ERROR]${NC} playbook ファイルが存在しません"
        ERRORS=$((ERRORS + 1))
    fi
fi

# --------------------------------------------------
# 3. Branch の整合性チェック
# --------------------------------------------------

echo ""
echo "  --- Git Branch ---"

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
PLAYBOOK_BRANCH=$(grep -A6 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^branch:" | head -1 | sed 's/branch: *//' | sed 's/ *#.*//' | tr -d ' ')

echo -e "    Current: $CURRENT_BRANCH"
echo -e "    Expected: ${PLAYBOOK_BRANCH:-null}"

if [[ -n "$PLAYBOOK_BRANCH" && "$PLAYBOOK_BRANCH" != "null" && "$PLAYBOOK_BRANCH" != "main" ]]; then
    if [[ "$CURRENT_BRANCH" != "$PLAYBOOK_BRANCH" ]]; then
        echo -e "    ${RED}[ERROR]${NC} ブランチ不一致"
        echo -e "    → git checkout $PLAYBOOK_BRANCH を実行してください"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "    ${GREEN}[OK]${NC} ブランチ一致"
    fi
else
    echo -e "    ${YELLOW}[INFO]${NC} ブランチ制約なし"
fi

# --------------------------------------------------
# 4. 孤立 playbook チェック
# --------------------------------------------------

echo ""
echo "  --- Orphan Playbooks ---"

ORPHAN_COUNT=0
for pb in plan/playbook-*.md; do
    if [[ -f "$pb" && "$pb" != "$ACTIVE_PLAYBOOK" ]]; then
        echo -e "    ${YELLOW}[WARN]${NC} 孤立 playbook: $pb"
        ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
        WARNINGS=$((WARNINGS + 1))
    fi
done

if [[ $ORPHAN_COUNT -eq 0 ]]; then
    echo -e "    ${GREEN}[OK]${NC} 孤立 playbook なし"
fi

# --------------------------------------------------
# 結果サマリー
# --------------------------------------------------

echo ""
echo "=========================================="
if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}[FAIL]${NC} $ERRORS error(s), $WARNINGS warning(s)"
    echo "=========================================="
    exit 2
elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}[WARN]${NC} $WARNINGS warning(s)"
    echo "=========================================="
    exit 0
else
    echo -e "${GREEN}[PASS]${NC} 整合性チェック OK"
    echo "=========================================="
fi

exit 0
