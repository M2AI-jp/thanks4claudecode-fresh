#!/bin/bash
# check-coherence.sh - 簡略版：state.md と playbook の整合性チェック

set -e

# ==============================================================================
# state-schema.sh を source して state.md のスキーマを参照
# ==============================================================================
source .claude/schema/state-schema.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo ""
echo "=========================================="
echo "  Coherence Check"
echo "=========================================="

if [ ! -f "state.md" ]; then
    echo -e "${RED}[ERROR]${NC} state.md not found"
    exit 2
fi

# focus.current を state-schema.sh から取得
CURRENT=$(get_focus_current)
echo -e "  Focus: ${GREEN}$CURRENT${NC}"
echo ""

# ========================================
# Active Playbooks チェック
# ========================================
echo -e "  --- Active Playbooks ---"

ACTIVE_PLAYBOOKS=$(awk '/## playbook/,/^## [^p]/' state.md | grep "active:" | sed 's/.*active: *//' | sed 's/ *#.*//')

if [ -z "$ACTIVE_PLAYBOOKS" ] || [ "$ACTIVE_PLAYBOOKS" = "null" ]; then
    echo -e "    ${YELLOW}[SKIP]${NC} No active playbook"
else
    echo -e "    Playbook: $ACTIVE_PLAYBOOKS"
    if [ -f "$ACTIVE_PLAYBOOKS" ]; then
        DONE_COUNT=$(grep -E "status: done" "$ACTIVE_PLAYBOOKS" 2>/dev/null | wc -l | tr -d ' ')
        PENDING_COUNT=$(grep -E "status: pending" "$ACTIVE_PLAYBOOKS" 2>/dev/null | wc -l | tr -d ' ')
        IN_PROGRESS_COUNT=$(grep -E "status: in_progress" "$ACTIVE_PLAYBOOKS" 2>/dev/null | wc -l | tr -d ' ')
        echo -e "      Phases: done=$DONE_COUNT, in_progress=$IN_PROGRESS_COUNT, pending=$PENDING_COUNT"
    else
        echo -e "      ${YELLOW}[WARN]${NC} Playbook file not found: $ACTIVE_PLAYBOOKS"
        WARNINGS=$((WARNINGS + 1))
    fi
fi
echo ""

# ========================================
# Branch Coherence チェック
# ========================================
echo -e "  --- Branch Coherence ---"

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
echo -e "    Current branch: $CURRENT_BRANCH"

PLAYBOOK_BRANCH=$(grep "branch:" state.md | grep -A1 "## playbook" | tail -1 | sed 's/.*branch: *//' | sed 's/ *#.*//' || echo "")

if [ -n "$PLAYBOOK_BRANCH" ] && [ "$PLAYBOOK_BRANCH" != "null" ] && [ "$PLAYBOOK_BRANCH" != "main" ]; then
    if [ "$CURRENT_BRANCH" != "$PLAYBOOK_BRANCH" ]; then
        echo -e "    ${RED}[ERROR]${NC} Branch mismatch!"
        echo -e "    expected: $PLAYBOOK_BRANCH"
        echo -e "    current:  $CURRENT_BRANCH"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "    ${GREEN}[OK]${NC} Branch matches"
    fi
else
    echo -e "    ${YELLOW}[SKIP]${NC} No branch constraint"
fi
echo ""

# ========================================
# Stray Playbooks チェック
# ========================================
echo -e "  --- Stray Playbooks ---"

STRAY_PLAYBOOKS=$(ls plan/playbook-*.md 2>/dev/null || echo "")
if [ -n "$STRAY_PLAYBOOKS" ]; then
    echo -e "    ${YELLOW}[WARN]${NC} Found stray playbooks in plan/:"
    for pb in $STRAY_PLAYBOOKS; do
        echo -e "      - $pb"
    done
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "    ${GREEN}[OK]${NC} No stray playbooks"
fi
echo ""

# ========================================
# Critic Enforcement チェック
# ========================================
echo ""
echo "--- Critic Enforcement ---"

if git diff --cached --name-only 2>/dev/null | grep -q "^state.md$"; then
    DONE_CHANGES=$(git diff --cached state.md 2>/dev/null | grep -E "^\+.*status: done" | wc -l | tr -d ' ')

    if [ "$DONE_CHANGES" -gt 0 ]; then
        SELF_COMPLETE=$(grep -E "self_complete: true" state.md 2>/dev/null | wc -l | tr -d ' ')

        if [ "$SELF_COMPLETE" -gt 0 ]; then
            echo -e "  ${GREEN}[OK]${NC} state: done + self_complete: true"
        else
            echo -e "  ${RED}[BLOCKED]${NC} state: done requires critic PASS"
            echo -e ""
            echo -e "  ${RED}call Task(subagent_type='critic') before commit${NC}"
            echo -e ""
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "  ${GREEN}[OK]${NC} No state: done changes"
    fi
else
    echo -e "  ${GREEN}[SKIP]${NC} state.md not staged"
fi

echo ""
echo "=========================================="
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}[FAIL]${NC} $ERRORS error(s), $WARNINGS warning(s)"
    exit 2
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}[WARN]${NC} $WARNINGS warning(s)"
    exit 0
else
    echo -e "${GREEN}[PASS]${NC} Coherence check passed"
fi
echo "=========================================="

exit 0
