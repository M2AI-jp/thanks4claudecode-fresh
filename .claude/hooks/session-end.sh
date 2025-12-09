#!/bin/bash
# session-end.sh - セッション終了時に四つ組整合性チェック + リマインド
#
# 目的: 次のセッション開始前に問題を認識させる
# - 未コミット変更の検出
# - state-plan-git-branch 四つ組の整合性チェック
# - critic 呼び出しのリマインド
#
# 自動更新機能:
#   - state.md の session_tracking.last_end を自動更新
#   - state.md の session_tracking.uncommitted_warning を自動更新
#   - LLM の行動に依存しない

set -e

# === state.md の session_tracking を自動更新 ===
if [ -f "state.md" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # uncommitted_warning を先に計算（state.md の session_tracking 変更を除外）
    # state.md 以外の変更をカウント
    UNCOMMITTED=$(git status --porcelain 2>/dev/null | grep -v "^.M state.md$" | grep -v "^ M state.md$" | grep -v "^M  state.md$" | wc -l | tr -d ' ')
    if [ "$UNCOMMITTED" -gt 0 ]; then
        WARN_VALUE="true"
    else
        WARN_VALUE="false"
    fi

    # last_end を更新
    if grep -q "last_end:" state.md; then
        sed -i '' "s/last_end: .*/last_end: $TIMESTAMP/" state.md 2>/dev/null || \
        sed -i "s/last_end: .*/last_end: $TIMESTAMP/" state.md 2>/dev/null || true
    fi

    # uncommitted_warning を更新
    if grep -q "uncommitted_warning:" state.md; then
        sed -i '' "s/uncommitted_warning: .*/uncommitted_warning: $WARN_VALUE/" state.md 2>/dev/null || \
        sed -i "s/uncommitted_warning: .*/uncommitted_warning: $WARN_VALUE/" state.md 2>/dev/null || true
    fi
fi

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

WARNINGS=0

echo ""
echo -e "${BOLD}=========================================="
echo "           SESSION END CHECK"
echo -e "==========================================${NC}"
echo ""

# ========================================
# 1. 未コミット変更チェック（四つ組の根幹）
# ========================================
echo -e "${BOLD}--- 未コミット変更チェック ---${NC}"

UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
    echo -e "  ${RED}[WARNING]${NC} 未コミット変更が ${UNCOMMITTED} 件あります"
    echo ""
    echo -e "  ${YELLOW}変更ファイル:${NC}"
    git status --porcelain 2>/dev/null | head -10 | while read line; do
        echo "    $line"
    done
    if [ "$UNCOMMITTED" -gt 10 ]; then
        echo "    ... (他 $((UNCOMMITTED - 10)) 件)"
    fi
    echo ""
    echo -e "  ${YELLOW}対処:${NC}"
    echo "    git add -A && git commit -m \"...\""
    echo ""
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "  ${GREEN}[OK]${NC} 未コミット変更なし"
fi
echo ""

# ========================================
# 2. 四つ組整合性チェック（state-plan-git-branch）
# ========================================
echo -e "${BOLD}--- 四つ組整合性チェック ---${NC}"

if [ ! -f "state.md" ]; then
    echo -e "  ${RED}[ERROR]${NC} state.md not found"
    exit 0  # SessionEnd はブロックしない
fi

# focus.current を取得
CURRENT=$(grep -A5 "## focus" state.md | grep "current:" | sed 's/.*current: *//' | sed 's/ *#.*//')
echo -e "  Focus: ${GREEN}$CURRENT${NC}"

# playbook を取得
PLAYBOOK=$(awk "/## layer: $CURRENT/,/^## [^l]/" state.md | grep "playbook:" | head -1 | sed 's/.*playbook: *//' | sed 's/ *#.*//')
echo -e "  Playbook: ${GREEN}${PLAYBOOK:-null}${NC}"

# branch を取得
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
echo -e "  Branch: ${GREEN}$CURRENT_BRANCH${NC}"

# playbook と branch の整合性
if [ -n "$PLAYBOOK" ] && [ "$PLAYBOOK" != "null" ] && [ -f "$PLAYBOOK" ]; then
    EXPECTED_BRANCH=$(grep -E "^branch:" "$PLAYBOOK" 2>/dev/null | head -1 | sed 's/branch: *//' | sed 's/ *#.*//')

    if [ -n "$EXPECTED_BRANCH" ] && [ "$EXPECTED_BRANCH" != "null" ]; then
        if [ "$CURRENT_BRANCH" != "$EXPECTED_BRANCH" ]; then
            echo ""
            echo -e "  ${RED}[WARNING]${NC} Branch mismatch!"
            echo -e "    playbook expects: $EXPECTED_BRANCH"
            echo -e "    current branch:   $CURRENT_BRANCH"
            WARNINGS=$((WARNINGS + 1))
        else
            echo -e "  ${GREEN}[OK]${NC} Branch matches playbook"
        fi
    fi
fi

# layer.state と playbook の整合性
if [ -n "$PLAYBOOK" ] && [ "$PLAYBOOK" != "null" ] && [ -f "$PLAYBOOK" ]; then
    LAYER_STATE=$(awk "/## layer: $CURRENT/,/^## [^l]/" state.md | grep "state:" | head -1 | sed 's/.*state: *//' | sed 's/ *#.*//')
    DONE_COUNT=$(grep -E "status: done" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')
    PENDING_COUNT=$(grep -E "status: pending" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')
    IN_PROGRESS_COUNT=$(grep -E "status: in_progress" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')

    echo ""
    echo -e "  Layer state: ${GREEN}$LAYER_STATE${NC}"
    echo -e "  Playbook phases: done=$DONE_COUNT, in_progress=$IN_PROGRESS_COUNT, pending=$PENDING_COUNT"

    # 整合性チェック
    if [ "$LAYER_STATE" = "done" ] && [ "$PENDING_COUNT" -gt 0 ]; then
        echo -e "  ${RED}[WARNING]${NC} state=done but playbook has pending phases"
        WARNINGS=$((WARNINGS + 1))
    fi

    if [ "$LAYER_STATE" = "implementing" ] && [ "$IN_PROGRESS_COUNT" -eq 0 ] && [ "$PENDING_COUNT" -gt 0 ]; then
        echo -e "  ${YELLOW}[INFO]${NC} No in_progress phase, but pending phases exist"
    fi
fi

echo ""

# ========================================
# 3. 追加チェック（critic リマインド）
# ========================================
echo -e "${BOLD}--- CRITIQUE リマインド ---${NC}"

# critic リマインド
echo -e "  ${RED}[CRITIQUE 必須]${NC}"
echo -e "  Phase を done にする前に critic を呼び出しましたか？"
echo ""
echo -e "  ${YELLOW}呼び出し方法:${NC}"
echo "    Task(subagent_type='critic')"
echo "    または /crit コマンド"
echo ""

# state.md が更新されているか
if git diff --name-only 2>/dev/null | grep -q "state.md"; then
    echo -e "  ${GREEN}[OK]${NC} state.md は更新済み"
else
    if git diff --cached --name-only 2>/dev/null | grep -q "state.md"; then
        echo -e "  ${GREEN}[OK]${NC} state.md は staged"
    else
        echo -e "  ${YELLOW}[CHECK]${NC} state.md は更新されていません"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# playbook が更新されているか
if git diff --name-only 2>/dev/null | grep -q "playbook"; then
    echo -e "  ${GREEN}[OK]${NC} playbook は更新済み"
else
    if git diff --cached --name-only 2>/dev/null | grep -q "playbook"; then
        echo -e "  ${GREEN}[OK]${NC} playbook は staged"
    else
        echo -e "  ${YELLOW}[CHECK]${NC} playbook は更新されていません"
    fi
fi
echo ""

# ========================================
# 4. 未 push コミットの検知
# ========================================
echo -e "${BOLD}--- 未 push コミットチェック ---${NC}"

if git rev-parse --git-dir > /dev/null 2>&1; then
    if git remote -v 2>/dev/null | grep -q "origin"; then
        git fetch origin 2>/dev/null || true

        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
        REMOTE_BRANCH="origin/$CURRENT_BRANCH"

        if git rev-parse "$REMOTE_BRANCH" > /dev/null 2>&1; then
            UNPUSHED=$(git log "$REMOTE_BRANCH..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')
            if [ "$UNPUSHED" -gt 0 ]; then
                echo -e "  ${YELLOW}[WARNING]${NC} 未 push コミットが ${UNPUSHED} 件あります"
                echo ""
                echo -e "  ${YELLOW}コマンド:${NC} git push origin $CURRENT_BRANCH"
                echo ""
                git log "$REMOTE_BRANCH..HEAD" --oneline 2>/dev/null | head -5 | while read line; do
                    echo "    - $line"
                done
                WARNINGS=$((WARNINGS + 1))
            else
                echo -e "  ${GREEN}[OK]${NC} 全てのコミットが push 済み"
            fi
        else
            echo -e "  ${YELLOW}[INFO]${NC} リモートブランチが存在しません（初回 push が必要）"
        fi
    else
        echo -e "  ${YELLOW}[SKIP]${NC} リモートが設定されていません"
    fi
fi

echo ""

# ========================================
# 5. セッションサマリー生成
# ========================================
echo -e "${BOLD}--- セッションサマリー生成 ---${NC}"

SESSIONS_DIR=".claude/logs/sessions"
mkdir -p "$SESSIONS_DIR"

# セッション番号を決定（その日の連番）
TODAY=$(date '+%Y-%m-%d')
SESSION_NUM=$(ls "$SESSIONS_DIR" 2>/dev/null | grep "^${TODAY}" | wc -l | tr -d ' ')
SESSION_NUM=$((SESSION_NUM + 1))
SESSION_FILE="${SESSIONS_DIR}/${TODAY}_session-$(printf '%03d' $SESSION_NUM).md"

# state.md から情報取得
SESSION_START=""
if [ -f "state.md" ]; then
    SESSION_START=$(grep "last_start:" state.md 2>/dev/null | sed 's/.*last_start: *//' | head -1)
fi
SESSION_END=$(date '+%Y-%m-%d %H:%M:%S')

# playbook の phase 情報取得
PHASE_INFO=""
if [ -n "$PLAYBOOK" ] && [ "$PLAYBOOK" != "null" ] && [ -f "$PLAYBOOK" ]; then
    DONE_PHASES=$(grep -E "status: done" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')
    PENDING_PHASES=$(grep -E "status: pending" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')
    PHASE_INFO="完了: $DONE_PHASES, 残り: $PENDING_PHASES"
fi

# セッション中のコミット取得
COMMITS=""
if [ -n "$SESSION_START" ]; then
    START_EPOCH=$(date -j -f "%Y-%m-%d %H:%M:%S" "$SESSION_START" "+%s" 2>/dev/null || echo "0")
    if [ "$START_EPOCH" != "0" ]; then
        COMMITS=$(git log --since="@$START_EPOCH" --oneline 2>/dev/null | head -10)
    fi
fi

# 変更ファイル数
CHANGED_FILES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

# サマリーファイル生成
{
    echo "# セッションサマリー"
    echo ""
    echo "## 基本情報"
    echo ""
    echo "| 項目 | 内容 |"
    echo "|------|------|"
    echo "| 日時 | ${SESSION_START:-不明} → $SESSION_END |"
    echo "| ブランチ | $CURRENT_BRANCH |"
    echo "| Focus | $CURRENT |"
    echo "| Playbook | ${PLAYBOOK:-なし} |"
    echo "| Phase 進捗 | ${PHASE_INFO:-N/A} |"
    echo ""
    echo "## このセッションでの作業"
    echo ""
    if [ -n "$COMMITS" ]; then
        echo "### コミット履歴"
        echo ""
        echo '```'
        echo "$COMMITS"
        echo '```'
        echo ""
    else
        echo "_このセッションではコミットされていません_"
        echo ""
    fi
    echo "### 変更ファイル（未コミット）"
    echo ""
    if [ "$CHANGED_FILES" -gt 0 ]; then
        echo '```'
        git status --porcelain 2>/dev/null | head -20
        if [ "$CHANGED_FILES" -gt 20 ]; then
            echo "... 他 $((CHANGED_FILES - 20)) 件"
        fi
        echo '```'
    else
        echo "_変更ファイルなし_"
    fi
    echo ""
    echo "## 結果"
    echo ""
    if [ $WARNINGS -gt 0 ]; then
        echo "- 警告: $WARNINGS 件"
    else
        echo "- 正常終了"
    fi
    echo ""
    echo "---"
    echo ""
    echo "_自動生成: session-end.sh_"
} > "$SESSION_FILE"

echo -e "  ${GREEN}[OK]${NC} サマリーを生成しました"
echo -e "  → ${BLUE}$SESSION_FILE${NC}"
echo ""

# ========================================
# サマリー
# ========================================
echo -e "${BOLD}=========================================="
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}[SESSION END]${NC} ${WARNINGS} 件の警告があります"
    echo ""
    echo -e "  次のセッション開始前に対処してください。"
    echo -e "  四つ組（state-plan-git-branch）の整合性を保つことで"
    echo -e "  コンテキスト喪失時の復旧が容易になります。"
else
    echo -e "${GREEN}[SESSION END]${NC} 問題なし"
fi
echo -e "==========================================${NC}"
echo ""

exit 0
