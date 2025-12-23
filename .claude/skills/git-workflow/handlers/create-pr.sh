#!/bin/bash
# ============================================================
# create-pr.sh - Phase/Playbook 完了時の自動 PR 作成
# ============================================================
# 用途: playbook 完了時に GitHub へ PR を自動作成
# 呼び出し元: POST_LOOP（playbook 完了後）
#
# 前提条件:
#   - gh CLI がインストール済み（brew install gh）
#   - gh auth でログイン済み
#   - 現在のブランチが main ではない
#   - リモートへ push 済み
#
# 引数:
#   なし（state.md と playbook から情報を取得）
#
# 戻り値:
#   0: 成功
#   1: エラー
#   2: スキップ（PR 既存、main ブランチ等）
# ============================================================

set -euo pipefail

# ============================================================
# 設定
# ============================================================
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATE_FILE="$REPO_ROOT/state.md"
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================
# 前提条件チェック
# ============================================================

# gh CLI の存在確認
if ! command -v gh &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} gh CLI がインストールされていません"
    echo "  brew install gh"
    exit 1
fi

# gh 認証確認
if ! gh auth status &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} gh CLI が認証されていません"
    echo "  gh auth login"
    exit 1
fi

# 現在のブランチ取得
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -z "$CURRENT_BRANCH" ]; then
    echo -e "${RED}[ERROR]${NC} git ブランチを取得できません"
    exit 1
fi

# main ブランチチェック
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    echo -e "${YELLOW}[SKIP]${NC} main/master ブランチでは PR を作成しません"
    exit 2
fi

# ============================================================
# state.md から情報取得
# ============================================================

if [ ! -f "$STATE_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} state.md が見つかりません"
    exit 1
fi

# focus と playbook パスを取得
FOCUS=$(grep -A5 "## focus" "$STATE_FILE" 2>/dev/null | grep "current:" | sed 's/.*: *//' | sed 's/ *#.*//' || echo "")
PLAYBOOK_PATH=$(grep -A5 "## playbook" "$STATE_FILE" 2>/dev/null | grep "active:" | sed 's/.*: *//' | sed 's/ *#.*//' || echo "null")

if [ "$PLAYBOOK_PATH" = "null" ] || [ -z "$PLAYBOOK_PATH" ]; then
    echo -e "${YELLOW}[SKIP]${NC} アクティブな playbook がありません"
    exit 2
fi

# ============================================================
# playbook から情報取得
# ============================================================

if [ ! -f "$REPO_ROOT/$PLAYBOOK_PATH" ]; then
    echo -e "${RED}[ERROR]${NC} playbook が見つかりません: $PLAYBOOK_PATH"
    exit 1
fi

PLAYBOOK_FILE="$REPO_ROOT/$PLAYBOOK_PATH"

# playbook 名を取得（ファイル名から）
PLAYBOOK_NAME=$(basename "$PLAYBOOK_PATH" .md | sed 's/playbook-//')

# 現在の phase を state.md から取得
CURRENT_PHASE=$(grep -A5 "## goal" "$STATE_FILE" 2>/dev/null | grep "phase:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//' || echo "")

# goal.summary を取得（YAML コードブロック内）
GOAL_SUMMARY=$(awk '/^## goal/,/^## [^g]/' "$PLAYBOOK_FILE" 2>/dev/null | awk '/summary: \|/,/^done_when:/' | grep -v -E "^(summary:|done_when:)" | sed 's/^  //' | tr '\n' ' ' | sed 's/  */ /g' || echo "")

# done_when を取得（playbook の goal セクション）
DONE_WHEN=$(awk '/^## goal/,/^## [^g]/' "$PLAYBOOK_FILE" 2>/dev/null | awk '/done_when:/,/^```/' | grep "^  - " | sed 's/^  - /- /' || echo "")

# 現在の phase の done_criteria を取得（playbook の phases セクション）
# Phase ID（p1, p2, etc.）で該当ブロックを抽出
# インデント: "- id: p2" 後は 2 スペース、done_criteria 項目は 4 スペース
if [ -n "$CURRENT_PHASE" ]; then
    PHASE_DONE_CRITERIA=$(awk -v phase="$CURRENT_PHASE" '
        /^- id: / && $3 == phase { found=1; next }
        /^- id: / && found { exit }
        /^# Phase / && found { exit }
        found && /  done_criteria:$/ { start=1; next }
        start && /^    - / { gsub(/^    - /, "- "); print }
        start && /^  [a-z_]+:/ { start=0 }
    ' "$PLAYBOOK_FILE" 2>/dev/null || echo "")
else
    PHASE_DONE_CRITERIA=""
fi

# phases から完了済み Phase を取得
COMPLETED_PHASES=$(awk '/^## phases/,/^## [^p]/' "$PLAYBOOK_FILE" 2>/dev/null | awk '
  /^- id:/ { id = $3 }
  /name:/ { name = $0; sub(/.*name: */, "", name) }
  /status: done/ { print "- " name }
' || echo "")

# ============================================================
# リモートへ push
# ============================================================

echo "$SEP"
echo "  📤 リモートへ push 中..."
echo "$SEP"

# upstream が設定されているか確認
if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' &> /dev/null; then
    # upstream 未設定: -u で push
    if ! git push -u origin "$CURRENT_BRANCH" 2>&1; then
        echo -e "${RED}[ERROR]${NC} push に失敗しました"
        exit 1
    fi
else
    # upstream 設定済み: 通常 push
    if ! git push 2>&1; then
        echo -e "${RED}[ERROR]${NC} push に失敗しました"
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} push 完了"

# ============================================================
# PR 既存チェック
# ============================================================

EXISTING_PR=$(gh pr list --head "$CURRENT_BRANCH" --json number --jq '.[0].number' 2>/dev/null || echo "")

if [ -n "$EXISTING_PR" ]; then
    echo ""
    echo -e "${YELLOW}[INFO]${NC} PR #$EXISTING_PR が既に存在します"
    echo "  https://github.com/$(gh repo view --json nameWithOwner -q '.nameWithOwner')/pull/$EXISTING_PR"
    exit 2
fi

# ============================================================
# PR 本文を生成
# ============================================================

# PR タイトルに playbook 名と phase 名を含める
if [ -n "$CURRENT_PHASE" ]; then
    PR_TITLE="feat($PLAYBOOK_NAME/$CURRENT_PHASE): $GOAL_SUMMARY"
else
    PR_TITLE="feat($PLAYBOOK_NAME): $GOAL_SUMMARY"
fi
# タイトルは 72 文字以内に制限
PR_TITLE=$(echo "$PR_TITLE" | cut -c1-72)

PR_BODY=$(cat <<EOF
## Summary

$GOAL_SUMMARY

## Playbook

- **Name**: $PLAYBOOK_NAME
- **Phase**: $CURRENT_PHASE
- **Path**: $PLAYBOOK_PATH
- **Focus**: $FOCUS

## Done When (Playbook Goal)

$DONE_WHEN

## Done Criteria (Current Phase: $CURRENT_PHASE)

$PHASE_DONE_CRITERIA

## Completed Phases

$COMPLETED_PHASES

---

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)

# ============================================================
# PR 作成
# ============================================================

echo ""
echo "$SEP"
echo "  🚀 PR を作成中..."
echo "$SEP"
echo ""
echo "Title: $PR_TITLE"
echo "Base: main"
echo "Head: $CURRENT_BRANCH"
echo ""

# PR 作成実行
PR_URL=$(gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base main \
    --head "$CURRENT_BRANCH" \
    2>&1) || {
    echo -e "${RED}[ERROR]${NC} PR 作成に失敗しました"
    echo "$PR_URL"
    exit 1
}

echo ""
echo "$SEP"
echo -e "  ${GREEN}✓ PR 作成完了${NC}"
echo "$SEP"
echo ""
echo "  $PR_URL"
echo ""

exit 0
