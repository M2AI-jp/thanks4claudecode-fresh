#!/bin/bash
# check-coherence.sh - 簡略版：state.md と playbook の整合性チェック

set -e

# ==============================================================================
# SCRIPT_DIR と REPO_ROOT を計算して絶対パスで source
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/../../../.."

STATE_SCHEMA_FILE="${REPO_ROOT}/.claude/schema/state-schema.sh"
if [[ -f "$STATE_SCHEMA_FILE" ]]; then
    # shellcheck source=../../../schema/state-schema.sh
    source "$STATE_SCHEMA_FILE"
fi

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
        if [[ "$ACTIVE_PLAYBOOKS" == *.json ]] && command -v jq &> /dev/null; then
            PROGRESS_PATH="$(dirname "$ACTIVE_PLAYBOOKS")/progress.json"
            if [ -f "$PROGRESS_PATH" ]; then
                DONE_COUNT=$(jq '[.phases[] | select(.status == "done" or .status == "completed")] | length' "$PROGRESS_PATH" 2>/dev/null || echo "0")
                IN_PROGRESS_COUNT=$(jq '[.phases[] | select(.status == "in_progress")] | length' "$PROGRESS_PATH" 2>/dev/null || echo "0")
                PENDING_COUNT=$(jq '[.phases[] | select(.status == "pending")] | length' "$PROGRESS_PATH" 2>/dev/null || echo "0")
                echo -e "      Phases: done=$DONE_COUNT, in_progress=$IN_PROGRESS_COUNT, pending=$PENDING_COUNT"
            else
                echo -e "      ${YELLOW}[WARN]${NC} progress.json not found: $PROGRESS_PATH"
                WARNINGS=$((WARNINGS + 1))
            fi
        else
            DONE_COUNT=$(grep -E "status: done" "$ACTIVE_PLAYBOOKS" 2>/dev/null | wc -l | tr -d ' ')
            PENDING_COUNT=$(grep -E "status: pending" "$ACTIVE_PLAYBOOKS" 2>/dev/null | wc -l | tr -d ' ')
            IN_PROGRESS_COUNT=$(grep -E "status: in_progress" "$ACTIVE_PLAYBOOKS" 2>/dev/null | wc -l | tr -d ' ')
            echo -e "      Phases: done=$DONE_COUNT, in_progress=$IN_PROGRESS_COUNT, pending=$PENDING_COUNT"
        fi
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
    echo -e "    ${GREEN}[OK]${NC} No stray legacy playbooks"
fi

V2_PLAYBOOKS=$(find play -maxdepth 2 -name "plan.json" ! -path "*/archive/*" ! -path "*/template/*" 2>/dev/null || echo "")
if [ -n "$V2_PLAYBOOKS" ]; then
    if [ -z "$ACTIVE_PLAYBOOKS" ] || [ "$ACTIVE_PLAYBOOKS" = "null" ]; then
        echo -e "    ${YELLOW}[WARN]${NC} Active playbook is null but play/ has drafts:"
        echo "$V2_PLAYBOOKS" | sed 's/^/      - /'
        WARNINGS=$((WARNINGS + 1))
    else
        ORPHANS=$(echo "$V2_PLAYBOOKS" | grep -v "$ACTIVE_PLAYBOOKS" || true)
        if [ -n "$ORPHANS" ]; then
            echo -e "    ${YELLOW}[WARN]${NC} Found additional playbooks in play/:"
            echo "$ORPHANS" | sed 's/^/      - /'
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
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
            echo -e "  ${RED}call Skill(skill='crit') or /crit before commit${NC}"
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
