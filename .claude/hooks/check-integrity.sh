#!/bin/bash
# ============================================================
# check-integrity.sh - リポジトリ整合性チェック
# ============================================================
# 目的: コマンド/エージェント/state が参照するファイルの存在を検証
# 
# チェック項目:
#   1. .claude/commands/*.md が参照する .claude/hooks/*.sh
#   2. .claude/commands/*.md が参照する .claude/scripts/*.sh
#   3. state.md の参照セクションに記載されたファイル
#   4. .claude/agents/*.md が参照するフレームワークファイル
#
# 使用方法:
#   bash .claude/hooks/check-integrity.sh
#
# 戻り値:
#   0: 全て存在
#   1: 欠損あり
# ============================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_ok() { echo -e "  ${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; WARNINGS=$((WARNINGS + 1)); }
log_err() { echo -e "  ${RED}[ERROR]${NC} $1"; ERRORS=$((ERRORS + 1)); }

echo ""
echo "========================================"
echo "  Repository Integrity Check"
echo "========================================"
echo ""

# ============================================================
# 1. Commands が参照する hooks/scripts をチェック
# ============================================================
echo "[1/4] Checking commands → hooks/scripts references..."

for cmd_file in .claude/commands/*.md; do
    [ -f "$cmd_file" ] || continue
    
    # bash .claude/hooks/*.sh を抽出
    hooks=$(grep -oE 'bash \.claude/hooks/[a-zA-Z0-9_-]+\.sh' "$cmd_file" 2>/dev/null | sed 's/bash //' || true)
    for hook in $hooks; do
        if [ -f "$hook" ]; then
            log_ok "$cmd_file → $hook"
        else
            log_err "$cmd_file → $hook (NOT FOUND)"
        fi
    done
    
    # bash .claude/scripts/*.sh を抽出
    scripts=$(grep -oE 'bash \.claude/scripts/[a-zA-Z0-9_-]+\.sh' "$cmd_file" 2>/dev/null | sed 's/bash //' || true)
    for script in $scripts; do
        if [ -f "$script" ]; then
            log_ok "$cmd_file → $script"
        else
            log_err "$cmd_file → $script (NOT FOUND)"
        fi
    done
done

echo ""

# ============================================================
# 2. state.md の参照セクションをチェック
# ============================================================
echo "[2/4] Checking state.md references..."

if [ -f "state.md" ]; then
    # 参照セクションからファイルパスを抽出
    refs=$(awk '/^## 参照/,/^## [^参]/' state.md | grep -oE '[a-zA-Z0-9_/-]+\.(md|yaml)' | sort -u || true)
    for ref in $refs; do
        if [ -f "$ref" ]; then
            log_ok "state.md → $ref"
        else
            log_err "state.md → $ref (NOT FOUND)"
        fi
    done
else
    log_warn "state.md not found"
fi

echo ""

# ============================================================
# 3. Agents が参照するファイルをチェック
# ============================================================
echo "[3/4] Checking agents → framework references..."

for agent_file in .claude/agents/*.md; do
    [ -f "$agent_file" ] || continue
    
    # 参照パスを抽出（.claude/rules/, docs/, plan/ など）
    refs=$(grep -oE '\.(claude|docs|plan)/[a-zA-Z0-9_/-]+\.(md|yaml|sh)' "$agent_file" 2>/dev/null | sort -u || true)
    for ref in $refs; do
        if [ -f "$ref" ]; then
            log_ok "$(basename "$agent_file") → $ref"
        else
            log_warn "$(basename "$agent_file") → $ref (NOT FOUND - may be optional)"
        fi
    done
done

echo ""

# ============================================================
# 4. Settings.json が参照する hooks をチェック
# ============================================================
echo "[4/5] Checking settings.json → hooks references..."

if [ -f ".claude/settings.json" ] && command -v jq &> /dev/null; then
    hooks=$(jq -r '.. | objects | select(.command) | .command' .claude/settings.json 2>/dev/null | grep -oE '\.claude/hooks/[a-zA-Z0-9_-]+\.sh' | sort -u || true)
    for hook in $hooks; do
        if [ -f "$hook" ]; then
            log_ok "settings.json → $hook"
        else
            log_err "settings.json → $hook (NOT FOUND)"
        fi
    done
elif [ ! -f ".claude/settings.json" ]; then
    log_warn ".claude/settings.json not found"
else
    log_warn "jq not installed - skipping settings.json check"
fi

echo ""

# ============================================================
# 5. Achieved milestone の playbook アーカイブ漏れチェック
# ============================================================
echo "[5/5] Checking for unarchived playbooks of achieved milestones..."

if [ -f "plan/project.md" ]; then
    for playbook in plan/playbook-*.md; do
        [ -f "$playbook" ] || continue

        PLAYBOOK_NAME=$(basename "$playbook")

        # derives_from から milestone ID を取得
        MILESTONE_ID=$(grep "derives_from:" "$playbook" 2>/dev/null | head -1 | sed 's/.*derives_from: *//' | tr -d ' ')

        if [ -n "$MILESTONE_ID" ]; then
            # project.md でその milestone が achieved かチェック
            MILESTONE_STATUS=$(awk "/id: $MILESTONE_ID\$/,/^- id:/" plan/project.md 2>/dev/null | grep "status:" | head -1 | sed 's/.*status: *//')

            if [ "$MILESTONE_STATUS" = "achieved" ]; then
                log_err "$PLAYBOOK_NAME → $MILESTONE_ID is achieved but playbook not archived"
                echo "       → Run: mv $playbook plan/archive/"
            else
                log_ok "$PLAYBOOK_NAME → $MILESTONE_ID (status: ${MILESTONE_STATUS:-in_progress})"
            fi
        fi
    done
else
    log_warn "plan/project.md not found"
fi

echo ""

# ============================================================
# Summary
# ============================================================
echo "========================================"
echo "  Summary"
echo "========================================"
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"
echo "========================================"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}FAILED${NC}: $ERRORS missing file(s) detected"
    exit 1
else
    echo -e "${GREEN}PASSED${NC}: All referenced files exist"
    exit 0
fi
