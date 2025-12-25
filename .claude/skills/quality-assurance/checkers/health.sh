#!/bin/bash
# ==============================================================================
# system-health-check.sh - SessionStart 統合: システム健全性チェック
# ==============================================================================
#
# 目的:
#   - Hook/SubAgent が正常動作しているか自動検証
#   - settings.json と実ファイルの整合性チェック
#   - 問題があれば警告を出力
#
# 発火: SessionStart イベント（session-start.sh から呼び出し）
# 入力: なし（直接呼び出し）
# 出力: 警告メッセージ（問題がある場合のみ）
#
# ==============================================================================

set -e

SETTINGS_FILE=".claude/settings.json"
ISSUES=""
ISSUE_COUNT=0

# ==============================================================================
# 1. settings.json の存在と有効性チェック
# ==============================================================================

if [ ! -f "$SETTINGS_FILE" ]; then
    ISSUES="$ISSUES\n  - [CRITICAL] $SETTINGS_FILE が存在しません"
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
else
    # JSON として有効かチェック
    if ! jq empty "$SETTINGS_FILE" 2>/dev/null; then
        ISSUES="$ISSUES\n  - [CRITICAL] $SETTINGS_FILE が無効な JSON です"
        ISSUE_COUNT=$((ISSUE_COUNT + 1))
    fi
fi

# settings.json が無効なら以降のチェックをスキップ
if [ $ISSUE_COUNT -gt 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🚨 システム健全性チェック: $ISSUE_COUNT 件の問題"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "$ISSUES"
    echo ""
    exit 0
fi

# ==============================================================================
# 2. Hook ファイルの存在・権限チェック
# ==============================================================================

# settings.json から全 Hook コマンドを抽出
HOOK_COMMANDS=$(jq -r '.. | objects | select(.command != null) | .command' "$SETTINGS_FILE" 2>/dev/null | sort -u)

for cmd in $HOOK_COMMANDS; do
    # "bash .claude/hooks/xxx.sh" から .sh ファイルパスを抽出
    HOOK_FILE=$(echo "$cmd" | grep -oE '\.claude/hooks/[^ ]+\.sh' || true)

    if [ -n "$HOOK_FILE" ]; then
        if [ ! -f "$HOOK_FILE" ]; then
            ISSUES="$ISSUES\n  - [ERROR] Hook ファイルが見つかりません: $HOOK_FILE"
            ISSUE_COUNT=$((ISSUE_COUNT + 1))
        elif [ ! -x "$HOOK_FILE" ]; then
            ISSUES="$ISSUES\n  - [WARN] 実行権限がありません: $HOOK_FILE"
            ISSUE_COUNT=$((ISSUE_COUNT + 1))
        fi
    fi
done

# ==============================================================================
# 3. SubAgent 定義ファイルのチェック
# ==============================================================================

AGENTS_DIR=".claude/agents"
if [ -d "$AGENTS_DIR" ]; then
    # CLAUDE.md で参照されている SubAgent が存在するか
    EXPECTED_AGENTS="critic pm reviewer health-checker"

    for agent in $EXPECTED_AGENTS; do
        if [ ! -f "$AGENTS_DIR/$agent.md" ]; then
            ISSUES="$ISSUES\n  - [WARN] SubAgent 定義が見つかりません: $AGENTS_DIR/$agent.md"
            ISSUE_COUNT=$((ISSUE_COUNT + 1))
        fi
    done
fi

# ==============================================================================
# 4. Skills ディレクトリのチェック
# ==============================================================================

SKILLS_DIR=".claude/skills"
if [ -d "$SKILLS_DIR" ]; then
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            if [ ! -f "${skill_dir}skill.md" ]; then
                ISSUES="$ISSUES\n  - [WARN] Skill 定義が見つかりません: ${skill_dir}skill.md"
                ISSUE_COUNT=$((ISSUE_COUNT + 1))
            fi
        fi
    done
fi

# ==============================================================================
# 5. state.md の形式チェック
# ==============================================================================

STATE_FILE="state.md"
if [ -f "$STATE_FILE" ]; then
    # 必須セクションの存在チェック（個別に検証）
    if ! grep -q "^## playbook" "$STATE_FILE" 2>/dev/null; then
        ISSUES="$ISSUES\n  - [WARN] state.md に必須セクションがありません: ## playbook"
        ISSUE_COUNT=$((ISSUE_COUNT + 1))
    fi
    if ! grep -q "^## goal" "$STATE_FILE" 2>/dev/null; then
        ISSUES="$ISSUES\n  - [WARN] state.md に必須セクションがありません: ## goal"
        ISSUE_COUNT=$((ISSUE_COUNT + 1))
    fi
    if ! grep -q "^## config" "$STATE_FILE" 2>/dev/null; then
        ISSUES="$ISSUES\n  - [WARN] state.md に必須セクションがありません: ## config"
        ISSUE_COUNT=$((ISSUE_COUNT + 1))
    fi

    # 整合性チェック: milestone/phase=null なのに playbook.active がある矛盾
    PLAYBOOK=$(grep "^active:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')
    MILESTONE=$(grep "^milestone:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/milestone: *//' | sed 's/ *#.*//' | tr -d ' ')
    PHASE=$(grep "^phase:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/phase: *//' | sed 's/ *#.*//' | tr -d ' ')

    if [[ -n "$PLAYBOOK" && "$PLAYBOOK" != "null" ]]; then
        # playbook がある場合、milestone と phase も設定されているべき
        if [[ -z "$MILESTONE" || "$MILESTONE" == "null" ]]; then
            ISSUES="$ISSUES\n  - [ERROR] state.md 不整合: playbook=$PLAYBOOK だが milestone=null"
            ISSUE_COUNT=$((ISSUE_COUNT + 1))
        fi
        if [[ -z "$PHASE" || "$PHASE" == "null" ]]; then
            ISSUES="$ISSUES\n  - [WARN] state.md 不整合: playbook=$PLAYBOOK だが phase=null"
            ISSUE_COUNT=$((ISSUE_COUNT + 1))
        fi
    fi
else
    ISSUES="$ISSUES\n  - [ERROR] state.md が存在しません"
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
fi

# ==============================================================================
# 6. 結果出力
# ==============================================================================

if [ $ISSUE_COUNT -gt 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔍 システム健全性チェック: $ISSUE_COUNT 件の問題"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "$ISSUES"
    echo ""
    echo "  修復コマンド例:"
    echo "    chmod +x .claude/hooks/*.sh  # 権限付与"
    echo ""
fi

exit 0
