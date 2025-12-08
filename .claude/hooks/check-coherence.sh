#!/bin/bash
# check-coherence.sh - state.md と playbook の整合性をチェック
# + focus 矛盾検出（編集ファイルが focus.current レイヤー外でないか）

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo ""
echo "=========================================="
echo "  Coherence Check (All Layers)"
echo "=========================================="

if [ ! -f "state.md" ]; then
    echo -e "${RED}[ERROR]${NC} state.md not found"
    # exit 2 = blocking error (公式仕様)
    exit 2
fi

# focus.current を取得
CURRENT=$(grep -A5 "## focus" state.md | grep "current:" | sed 's/.*current: *//' | sed 's/ *#.*//')
echo -e "  Focus: ${GREEN}$CURRENT${NC}"
echo ""

# 全レイヤーをチェック
for LAYER in "plan-template" "workspace" "setup"; do
    echo -e "  --- Layer: $LAYER ---"

    # レイヤーの state を取得
    LAYER_STATE=$(awk "/## layer: $LAYER/,/^## [^l]/" state.md | grep "state:" | head -1 | sed 's/.*state: *//' | sed 's/ *#.*//')

    # playbook を取得
    PLAYBOOK=$(awk "/## layer: $LAYER/,/^## [^l]/" state.md | grep "playbook:" | head -1 | sed 's/.*playbook: *//' | sed 's/ *#.*//')

    if [ -z "$LAYER_STATE" ]; then
        echo -e "    ${YELLOW}[SKIP]${NC} Layer not found in state.md"
        continue
    fi

    echo -e "    State: $LAYER_STATE"

    # playbook がある場合、phase の status と state を比較
    if [ -n "$PLAYBOOK" ] && [ "$PLAYBOOK" != "null" ] && [ -f "$PLAYBOOK" ]; then
        echo -e "    Playbook: $PLAYBOOK"

        # playbook 内の全 phase の status をカウント
        DONE_COUNT=$(grep -E "status: done" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')
        PENDING_COUNT=$(grep -E "status: pending" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')
        IN_PROGRESS_COUNT=$(grep -E "status: in_progress" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')

        echo -e "    Phases: done=$DONE_COUNT, in_progress=$IN_PROGRESS_COUNT, pending=$PENDING_COUNT"

        # state と playbook の整合性チェック
        if [ "$LAYER_STATE" = "pending" ] && [ "$DONE_COUNT" -gt 0 ]; then
            echo -e "    ${RED}[ERROR]${NC} state=pending but playbook has done phases"
            ERRORS=$((ERRORS + 1))
        fi

        if [ "$LAYER_STATE" = "done" ] && [ "$PENDING_COUNT" -gt 0 ]; then
            echo -e "    ${RED}[ERROR]${NC} state=done but playbook has pending phases"
            ERRORS=$((ERRORS + 1))
        fi

        if [ "$LAYER_STATE" = "implementing" ] && [ "$IN_PROGRESS_COUNT" -eq 0 ] && [ "$PENDING_COUNT" -eq 0 ]; then
            echo -e "    ${YELLOW}[WARN]${NC} state=implementing but no in_progress/pending phases"
        fi
    fi
    echo ""
done

# focus.current のレイヤーの詳細チェック
echo -e "  --- Focus Layer Detail: $CURRENT ---"

# sub を取得
SUB=$(awk "/## layer: $CURRENT/,/^## [^l]/" state.md | grep "sub:" | head -1 | sed 's/.*sub: *//' | sed 's/ *#.*//')
echo -e "    Sub: $SUB"

# goal.phase を取得
GOAL_PHASE=$(grep -A5 "## goal" state.md | grep "phase:" | head -1 | sed 's/.*phase: *//' | sed 's/ *#.*//')
echo -e "    Goal phase: $GOAL_PHASE"

echo ""

# ========================================
# 未 staged 変更チェック（state-plan-git-branch 4つ組連動）
# ========================================
echo -e "  --- Unstaged Changes Check ---"

# staged は除外、unstaged と untracked のみカウント
# git status --porcelain: " M file" (unstaged), "?? file" (untracked)
UNSTAGED=$(git status --porcelain 2>/dev/null | grep -E '^ [MD]|^\?\?' | wc -l | tr -d ' ')
if [ "$UNSTAGED" -gt 10 ]; then
    echo -e "    ${YELLOW}[WARN]${NC} 未 staged 変更が ${UNSTAGED} 件あります"
    echo -e "    → git add で staged するか、不要なら git checkout で戻してください"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "    ${GREEN}[OK]${NC} 未 staged 変更: ${UNSTAGED} 件"
fi

echo ""

# ========================================
# playbook-branch 連動チェック（四つ組の根幹）
# ========================================
echo -e "  --- Branch Coherence Check ---"

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
echo -e "    Current branch: $CURRENT_BRANCH"

# focus.current の playbook を取得（active_playbooks セクションから）
FOCUS_PLAYBOOK=$(awk '/## active_playbooks/,/^## [^a]/' state.md | grep "^${CURRENT}:" | head -1 | sed "s/${CURRENT}: *//" | sed 's/ *#.*//')

if [ -n "$FOCUS_PLAYBOOK" ] && [ "$FOCUS_PLAYBOOK" != "null" ] && [ -f "$FOCUS_PLAYBOOK" ]; then
    echo -e "    Focus playbook: $FOCUS_PLAYBOOK"
    EXPECTED_BRANCH=$(grep -E "^branch:" "$FOCUS_PLAYBOOK" 2>/dev/null | head -1 | sed 's/branch: *//' | sed 's/ *#.*//')

    if [ -n "$EXPECTED_BRANCH" ] && [ "$EXPECTED_BRANCH" != "null" ]; then
        echo -e "    Playbook branch: $EXPECTED_BRANCH"

        if [ "$CURRENT_BRANCH" != "$EXPECTED_BRANCH" ]; then
            echo -e "    ${RED}[ERROR]${NC} Branch mismatch!"
            echo -e "    playbook expects: $EXPECTED_BRANCH"
            echo -e "    current branch:   $CURRENT_BRANCH"
            echo -e "    → git checkout $EXPECTED_BRANCH または playbook の branch を更新"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "    ${GREEN}[OK]${NC} Branch matches playbook"
        fi
    else
        echo -e "    ${YELLOW}[SKIP]${NC} Playbook has no branch constraint (initial/setup state)"
    fi
else
    echo -e "    ${YELLOW}[SKIP]${NC} No playbook to check branch against"
fi

echo ""

# ========================================
# Focus 矛盾検出（staged files vs focus.current）
# ========================================
echo -e "  --- Focus Mismatch Detection ---"

# staged ファイルを取得
STAGED_FILES=$(git diff --staged --name-only 2>/dev/null || echo "")

if [ -z "$STAGED_FILES" ]; then
    echo -e "    ${YELLOW}[SKIP]${NC} No staged files"
else
    echo -e "    Staged files:"

    # focus.current に基づいて editable 範囲を判定
    # state.md の rules セクションを参照
    for FILE in $STAGED_FILES; do
        echo -e "      - $FILE"

        # always_editable: state.md, README.md
        # CONTEXT.md は .archive に退避済み
        if [[ "$FILE" == "state.md" ]] || [[ "$FILE" == "README.md" ]]; then
            continue
        fi

        # focus.current 別の editable 判定
        case "$CURRENT" in
            "plan-template")
                # plan/template/** のみ editable
                if [[ ! "$FILE" =~ ^plan/template/ ]] && [[ ! "$FILE" =~ ^plan/active/playbook ]]; then
                    echo -e "        ${YELLOW}[WARN]${NC} focus=$CURRENT but editing: $FILE"
                    WARNINGS=$((WARNINGS + 1))
                fi
                ;;
            "workspace")
                # .claude/**, CLAUDE.md, AGENTS.md, plan/** が editable
                if [[ ! "$FILE" =~ ^\.claude/ ]] && [[ "$FILE" != "CLAUDE.md" ]] && [[ "$FILE" != "AGENTS.md" ]] && [[ ! "$FILE" =~ ^plan/ ]]; then
                    echo -e "        ${YELLOW}[WARN]${NC} focus=$CURRENT but editing: $FILE"
                    WARNINGS=$((WARNINGS + 1))
                fi
                ;;
            "setup")
                # setup/** のみ editable
                if [[ ! "$FILE" =~ ^setup/ ]]; then
                    echo -e "        ${YELLOW}[WARN]${NC} focus=$CURRENT but editing: $FILE"
                    WARNINGS=$((WARNINGS + 1))
                fi
                ;;
            *)
                # 未知のレイヤー
                echo -e "        ${YELLOW}[WARN]${NC} Unknown focus: $CURRENT"
                ;;
        esac
    done
fi

# ========================================
# History 更新検知（state.md 変更履歴確認）
# ========================================
echo -e "  --- History Update Detection ---"

# state.md の sub からバージョン番号を抽出 (例: v13-system-integrity → v13)
VERSION=$(echo "$SUB" | grep -oE "^v[0-9]+" || echo "")

if [ -n "$VERSION" ]; then
    echo -e "    Current version: $VERSION"
    echo -e "    ${GREEN}[OK]${NC} バージョン形式の sub を検出"
else
    echo -e "    ${YELLOW}[SKIP]${NC} バージョン形式でない sub: $SUB"
fi

echo ""

# ========================================
# Playbook 配置チェック（plan/active/ 運用）
# ========================================
echo -e "  --- Playbook Location Check ---"

# plan/ 直下に playbook があれば WARNING
STRAY_PLAYBOOKS=$(ls plan/playbook-*.md 2>/dev/null || echo "")
if [ -n "$STRAY_PLAYBOOKS" ]; then
    echo -e "    ${YELLOW}[WARN]${NC} plan/ 直下に playbook があります:"
    for pb in $STRAY_PLAYBOOKS; do
        echo -e "      - $pb"
    done
    echo -e "    → plan/active/ または plan/archive/ に移動してください"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "    ${GREEN}[OK]${NC} plan/ 直下に stray playbook なし"
fi

echo ""

# ========================================
# spec.yaml 整合性チェック
# ========================================
echo -e "  --- spec.yaml Integrity Check ---"

if [ -f "spec.yaml" ]; then
    # hooks チェック（hooks: から次のトップレベルセクションまで）
    HOOKS=$(awk '/^hooks:/,/^[a-z_]+:/' spec.yaml | grep -E "^  [a-z-]+:" | sed 's/://g' | tr -d ' ')
    for hook in $HOOKS; do
        if [ -f ".claude/hooks/$hook.sh" ]; then
            echo -e "    ${GREEN}[OK]${NC} Hook: $hook"
        else
            echo -e "    ${YELLOW}[WARN]${NC} Hook not found: $hook"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
else
    echo -e "    ${YELLOW}[SKIP]${NC} spec.yaml not found"
fi

# ==============================================================================
# critic 強制メカニズム: state: done への変更を検出
# ==============================================================================
echo ""
echo "--- Critic Enforcement Check ---"

# state.md が staged にある場合、done への変更をチェック
if git diff --cached --name-only 2>/dev/null | grep -q "^state.md$"; then
    # state: done への変更を検出
    DONE_CHANGES=$(git diff --cached state.md 2>/dev/null | grep -E "^\+.*state: done" | wc -l | tr -d ' ')

    if [ "$DONE_CHANGES" -gt 0 ]; then
        # self_complete: true がファイルに存在するか確認（critic PASS の証拠）
        # ファイルの現在の状態をチェック（diff ではなく）
        SELF_COMPLETE=$(grep -E "self_complete: true" state.md 2>/dev/null | wc -l | tr -d ' ')

        if [ "$SELF_COMPLETE" -gt 0 ]; then
            echo -e "  ${GREEN}[OK]${NC} state: done + self_complete: true（critic PASS 証拠あり）"
        else
            echo -e "  ${RED}[BLOCKED]${NC} state: done への変更を検出"
            echo -e ""
            echo -e "  ┌─────────────────────────────────────────────────────────┐"
            echo -e "  │ ${RED}🚨 CRITIC 必須 - コミットをブロックしました${NC}            │"
            echo -e "  │                                                         │"
            echo -e "  │ done 判定には以下が必須です:                            │"
            echo -e "  │   1. done_criteria の全項目に証拠を示す                 │"
            echo -e "  │   2. Task(subagent_type='critic') を呼び出す           │"
            echo -e "  │   3. critic が PASS を返す                             │"
            echo -e "  │                                                         │"
            echo -e "  │ ${RED}critic PASS 後に再度コミットしてください。${NC}             │"
            echo -e "  │ 証拠なしの done は自己報酬詐欺です。                    │"
            echo -e "  └─────────────────────────────────────────────────────────┘"
            echo -e ""
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "  ${GREEN}[OK]${NC} No state: done changes detected"
    fi
else
    echo -e "  ${GREEN}[SKIP]${NC} state.md not in staged files"
fi

# ==============================================================================
# Phase 完了時の /clear リマインダー（Issue #10: 自動 /clear 判断）
# ==============================================================================
echo ""
echo "--- Context Management Reminder ---"

# playbook が staged にある場合、status: done への変更をチェック
PLAYBOOK_STAGED=$(git diff --cached --name-only 2>/dev/null | grep "playbook-" || echo "")

if [ -n "$PLAYBOOK_STAGED" ]; then
    # status: done への変更を検出
    PHASE_DONE=$(git diff --cached 2>/dev/null | grep -E "^\+.*status: done" | wc -l | tr -d ' ')

    if [ "$PHASE_DONE" -gt 0 ]; then
        echo -e ""
        echo -e "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo -e "    📊 Phase 完了 - コンテキスト確認推奨" >&2
        echo -e "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo -e "    /context でコンテキスト使用率を確認してください。" >&2
        echo -e "    80% 超過の場合は /clear を実行してください。" >&2
        echo -e "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo -e ""
    else
        echo -e "  ${GREEN}[OK]${NC} No phase completion detected"
    fi
else
    echo -e "  ${GREEN}[SKIP]${NC} No playbook in staged files"
fi

echo ""
echo "=========================================="
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}[FAIL]${NC} $ERRORS error(s), $WARNINGS warning(s)"
    # exit 2 = blocking error (公式仕様)
    exit 2
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}[WARN]${NC} $WARNINGS warning(s) - focus mismatch detected"
    echo -e "  Consider: Is focus.current correct? Or should you change it?"
    # WARNING は exit 0 で通す（ブロックはしない）
    exit 0
else
    echo -e "${GREEN}[PASS]${NC} Coherence check passed"
fi
echo "=========================================="

exit 0
