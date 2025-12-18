#!/bin/bash
# ============================================================
# audit-unused.sh - 未使用ファイル検出スクリプト
# ============================================================
# 目的: hooks/, agents/, skills/, commands/ 内のファイルで
#       どこからも参照されていないものを検出
#
# 使用方法:
#   bash .claude/hooks/audit-unused.sh
#
# 出力:
#   - 未使用ファイル一覧
#   - 参照元ファイル一覧（参照がある場合）
# ============================================================

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "========================================"
echo "  Unused File Audit"
echo "========================================"
echo ""

# 検索対象ディレクトリ
DIRS_TO_CHECK=(
    ".claude/hooks"
    ".claude/agents"
    ".claude/skills"
    ".claude/commands"
)

# 参照を検索するファイル
REFERENCE_FILES=(
    "CLAUDE.md"
    "RUNBOOK.md"
    "state.md"
    ".claude/settings.json"
    "docs/*.md"
    "plan/template/*.md"
)

# 結果カウンター
TOTAL_FILES=0
UNUSED_FILES=0
USED_FILES=0

# 一時ファイル
UNUSED_LIST=$(mktemp)
USED_LIST=$(mktemp)

trap "rm -f $UNUSED_LIST $USED_LIST" EXIT

# ============================================================
# 1. Hooks のチェック
# ============================================================
echo -e "${BLUE}[1/4] Checking .claude/hooks/...${NC}"
echo ""

for hook_file in .claude/hooks/*.sh; do
    [ -f "$hook_file" ] || continue
    TOTAL_FILES=$((TOTAL_FILES + 1))

    hook_name=$(basename "$hook_file")

    # settings.json で参照されているか
    in_settings=false
    if grep -q "$hook_name" .claude/settings.json 2>/dev/null; then
        in_settings=true
    fi

    # 他のファイルから参照されているか
    referenced=false
    ref_files=""

    for ref_pattern in "${REFERENCE_FILES[@]}"; do
        for ref_file in $ref_pattern; do
            [ -f "$ref_file" ] || continue
            if grep -q "$hook_name" "$ref_file" 2>/dev/null; then
                referenced=true
                ref_files="$ref_files $(basename "$ref_file")"
            fi
        done
    done

    # 他の hook から呼ばれているか
    for other_hook in .claude/hooks/*.sh; do
        [ "$other_hook" != "$hook_file" ] || continue
        if grep -q "$hook_name" "$other_hook" 2>/dev/null; then
            referenced=true
            ref_files="$ref_files $(basename "$other_hook")"
        fi
    done

    if $in_settings; then
        echo -e "  ${GREEN}[REGISTERED]${NC} $hook_name"
        USED_FILES=$((USED_FILES + 1))
        echo "$hook_name (settings.json)" >> "$USED_LIST"
    elif $referenced; then
        echo -e "  ${YELLOW}[UTILITY]${NC} $hook_name (refs:$ref_files)"
        USED_FILES=$((USED_FILES + 1))
        echo "$hook_name (utility)" >> "$USED_LIST"
    else
        echo -e "  ${RED}[UNUSED]${NC} $hook_name"
        UNUSED_FILES=$((UNUSED_FILES + 1))
        echo "$hook_name" >> "$UNUSED_LIST"
    fi
done

echo ""

# ============================================================
# 2. Agents のチェック
# ============================================================
echo -e "${BLUE}[2/4] Checking .claude/agents/...${NC}"
echo ""

for agent_file in .claude/agents/*.md; do
    [ -f "$agent_file" ] || continue
    TOTAL_FILES=$((TOTAL_FILES + 1))

    agent_name=$(basename "$agent_file" .md)

    # AGENTS.md または CLAUDE.md で参照されているか
    referenced=false
    ref_files=""

    # ファイル名で検索
    for ref_pattern in "CLAUDE.md" "AGENTS.md" "docs/*.md" ".claude/commands/*.md"; do
        for ref_file in $ref_pattern; do
            [ -f "$ref_file" ] || continue
            if grep -qi "$agent_name" "$ref_file" 2>/dev/null; then
                referenced=true
                ref_files="$ref_files $(basename "$ref_file")"
            fi
        done
    done

    if $referenced; then
        echo -e "  ${GREEN}[USED]${NC} $agent_name (refs:$ref_files)"
        USED_FILES=$((USED_FILES + 1))
        echo "$agent_name.md (agent)" >> "$USED_LIST"
    else
        echo -e "  ${RED}[UNUSED]${NC} $agent_name"
        UNUSED_FILES=$((UNUSED_FILES + 1))
        echo "$agent_name.md (agent)" >> "$UNUSED_LIST"
    fi
done

echo ""

# ============================================================
# 3. Skills のチェック
# ============================================================
echo -e "${BLUE}[3/4] Checking .claude/skills/...${NC}"
echo ""

for skill_dir in .claude/skills/*/; do
    [ -d "$skill_dir" ] || continue
    TOTAL_FILES=$((TOTAL_FILES + 1))

    skill_name=$(basename "$skill_dir")

    # CLAUDE.md または他のファイルで参照されているか
    referenced=false
    ref_files=""

    for ref_pattern in "CLAUDE.md" "docs/*.md" ".claude/commands/*.md"; do
        for ref_file in $ref_pattern; do
            [ -f "$ref_file" ] || continue
            if grep -qi "$skill_name" "$ref_file" 2>/dev/null; then
                referenced=true
                ref_files="$ref_files $(basename "$ref_file")"
            fi
        done
    done

    if $referenced; then
        echo -e "  ${GREEN}[USED]${NC} $skill_name (refs:$ref_files)"
        USED_FILES=$((USED_FILES + 1))
        echo "$skill_name/ (skill)" >> "$USED_LIST"
    else
        echo -e "  ${RED}[UNUSED]${NC} $skill_name"
        UNUSED_FILES=$((UNUSED_FILES + 1))
        echo "$skill_name/ (skill)" >> "$UNUSED_LIST"
    fi
done

echo ""

# ============================================================
# 4. Commands のチェック
# ============================================================
echo -e "${BLUE}[4/4] Checking .claude/commands/...${NC}"
echo ""

for cmd_file in .claude/commands/*.md; do
    [ -f "$cmd_file" ] || continue
    TOTAL_FILES=$((TOTAL_FILES + 1))

    cmd_name=$(basename "$cmd_file" .md)

    # CLAUDE.md または docs で参照されているか
    referenced=false
    ref_files=""

    for ref_pattern in "CLAUDE.md" "RUNBOOK.md" "docs/*.md"; do
        for ref_file in $ref_pattern; do
            [ -f "$ref_file" ] || continue
            if grep -qi "/$cmd_name" "$ref_file" 2>/dev/null || grep -qi "$cmd_name.md" "$ref_file" 2>/dev/null; then
                referenced=true
                ref_files="$ref_files $(basename "$ref_file")"
            fi
        done
    done

    # コマンドは基本的に使用されているとみなす（ユーザーが直接呼び出すため）
    echo -e "  ${GREEN}[COMMAND]${NC} /$cmd_name"
    USED_FILES=$((USED_FILES + 1))
    echo "$cmd_name.md (command)" >> "$USED_LIST"
done

echo ""

# ============================================================
# Summary
# ============================================================
echo "========================================"
echo "  Summary"
echo "========================================"
echo "  Total files:  $TOTAL_FILES"
echo "  Used:         $USED_FILES"
echo "  Unused:       $UNUSED_FILES"
echo "========================================"

if [ $UNUSED_FILES -gt 0 ]; then
    echo ""
    echo -e "${RED}Unused files:${NC}"
    cat "$UNUSED_LIST" | while read -r line; do
        echo "  - $line"
    done
    echo ""
    echo -e "${YELLOW}These files may be candidates for deletion.${NC}"
    echo "Verify manually before removing."
    exit 1
else
    echo ""
    echo -e "${GREEN}All files are referenced!${NC}"
    exit 0
fi
