#!/bin/bash
# ============================================================
# merge-pr.sh - PR の自動マージスクリプト
# ============================================================
# 目的: GitHub 上の PR をマージし、ローカルブランチを同期
#
# 機能:
#   - PR のステータス確認（draft → ready）
#   - gh pr merge コマンドで自動マージ
#   - マージコンフリクト検出とエラー通知
#   - マージコミットメッセージを CLAUDE.md 準拠で生成
#
# 使用方法:
#   bash merge-pr.sh [PR番号]
#   PR番号省略時は現在のブランチの PR を対象
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
# ヘルパー関数
# ============================================================
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================
# 前提条件チェック
# ============================================================

# gh CLI の存在確認
if ! command -v gh &> /dev/null; then
    log_error "gh CLI がインストールされていません"
    echo "  インストール: brew install gh"
    exit 1
fi

# gh 認証確認
if ! gh auth status &> /dev/null; then
    log_error "gh CLI が認証されていません"
    echo "  認証: gh auth login"
    exit 1
fi

# リポジトリ確認
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    log_error "Git リポジトリではありません"
    exit 1
fi

# ============================================================
# PR 番号の取得
# ============================================================
PR_NUMBER="${1:-}"

if [ -z "$PR_NUMBER" ]; then
    # 引数なしの場合、現在のブランチの PR を取得
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

    if [ -z "$CURRENT_BRANCH" ] || [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
        log_error "main/master ブランチでは PR を特定できません"
        echo "  使用方法: bash merge-pr.sh <PR番号>"
        exit 1
    fi

    # 現在のブランチに関連する PR を検索
    PR_NUMBER=$(gh pr list --head "$CURRENT_BRANCH" --json number --jq '.[0].number' 2>/dev/null || echo "")

    if [ -z "$PR_NUMBER" ]; then
        log_error "現在のブランチ ($CURRENT_BRANCH) に関連する PR が見つかりません"
        exit 1
    fi

    log_info "現在のブランチ ($CURRENT_BRANCH) の PR #$PR_NUMBER を対象にします"
fi

# ============================================================
# PR 情報の取得
# ============================================================
echo ""
echo "$SEP"
echo "  🔍 PR #$PR_NUMBER の情報を取得中..."
echo "$SEP"
echo ""

# PR の詳細情報を取得
PR_INFO=$(gh pr view "$PR_NUMBER" --json state,title,isDraft,mergeable,mergeStateStatus,headRefName,baseRefName 2>/dev/null || echo "")

if [ -z "$PR_INFO" ]; then
    log_error "PR #$PR_NUMBER が見つかりません"
    exit 1
fi

# 各フィールドを抽出
PR_STATE=$(echo "$PR_INFO" | jq -r '.state')
PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
PR_IS_DRAFT=$(echo "$PR_INFO" | jq -r '.isDraft')
PR_MERGEABLE=$(echo "$PR_INFO" | jq -r '.mergeable')
PR_MERGE_STATE=$(echo "$PR_INFO" | jq -r '.mergeStateStatus')
PR_HEAD_BRANCH=$(echo "$PR_INFO" | jq -r '.headRefName')
PR_BASE_BRANCH=$(echo "$PR_INFO" | jq -r '.baseRefName')

echo "  PR: #$PR_NUMBER"
echo "  Title: $PR_TITLE"
echo "  State: $PR_STATE"
echo "  Draft: $PR_IS_DRAFT"
echo "  Mergeable: $PR_MERGEABLE"
echo "  Merge State: $PR_MERGE_STATE"
echo "  Head: $PR_HEAD_BRANCH → Base: $PR_BASE_BRANCH"
echo ""

# ============================================================
# ステータスチェック
# ============================================================

# PR がクローズ済みかチェック
if [ "$PR_STATE" = "CLOSED" ]; then
    log_error "PR #$PR_NUMBER は既にクローズされています"
    exit 1
fi

# PR が既にマージ済みかチェック
if [ "$PR_STATE" = "MERGED" ]; then
    log_warn "PR #$PR_NUMBER は既にマージされています"
    exit 0
fi

# Draft かどうかチェック
if [ "$PR_IS_DRAFT" = "true" ]; then
    log_error "PR #$PR_NUMBER は Draft 状態です"
    echo ""
    echo "  Draft を解除するには:"
    echo "    gh pr ready $PR_NUMBER"
    exit 1
fi

# マージ可能性チェック
if [ "$PR_MERGEABLE" = "CONFLICTING" ]; then
    log_error "PR #$PR_NUMBER にマージコンフリクトがあります"
    echo ""
    echo "  コンフリクトを解決してください:"
    echo "    1. git checkout $PR_HEAD_BRANCH"
    echo "    2. git merge $PR_BASE_BRANCH"
    echo "    3. コンフリクトを解決"
    echo "    4. git add . && git commit"
    echo "    5. git push"
    exit 1
fi

# マージステータスチェック
case "$PR_MERGE_STATE" in
    "BLOCKED")
        log_error "PR #$PR_NUMBER は必須チェックによりブロックされています"
        echo ""
        echo "  GitHub で必須チェックの状態を確認してください:"
        echo "    gh pr checks $PR_NUMBER"
        exit 1
        ;;
    "BEHIND")
        log_warn "PR #$PR_NUMBER のブランチが $PR_BASE_BRANCH より古くなっています"
        echo ""
        echo "  更新が必要です:"
        echo "    gh pr update-branch $PR_NUMBER"
        echo ""
        # 続行可能（--auto でマージ待機）
        ;;
    "UNKNOWN")
        log_warn "PR #$PR_NUMBER のマージステータスが不明です"
        echo "  GitHub API の応答を確認してください"
        # 続行可能
        ;;
esac

# ============================================================
# マージ実行
# ============================================================
echo ""
echo "$SEP"
echo "  🚀 PR #$PR_NUMBER をマージします"
echo "$SEP"
echo ""

# playbook 情報を取得（マージコミットメッセージ用）
PLAYBOOK_PATH=""
GOAL_SUMMARY=""

if [ -f "$STATE_FILE" ]; then
    # state.md から playbook パスを取得
    PLAYBOOK_PATH=$(grep -A5 "## playbook" "$STATE_FILE" 2>/dev/null | grep "active:" | sed 's/.*: *//' | sed 's/ *#.*//' || echo "")

    # goal の summary を取得
    GOAL_SUMMARY=$(grep -A5 "## goal" "$STATE_FILE" 2>/dev/null | grep "name:" | sed 's/.*: *//' | sed 's/ *#.*//' || echo "")
fi

# マージコミットメッセージを生成
MERGE_BODY="## Summary
$GOAL_SUMMARY

## PR Details
- PR: #$PR_NUMBER
- Branch: $PR_HEAD_BRANCH → $PR_BASE_BRANCH
- Playbook: ${PLAYBOOK_PATH:-N/A}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# マージ実行（--merge でマージコミット作成）
# --auto を使用して必須チェック通過後に自動マージ
if gh pr merge "$PR_NUMBER" \
    --merge \
    --auto \
    --body "$MERGE_BODY" \
    --delete-branch 2>&1; then

    echo ""
    log_info "PR #$PR_NUMBER のマージが完了（または自動マージが設定）されました"

    # ローカルブランチを同期
    echo ""
    echo "$SEP"
    echo "  🔄 ローカルブランチを同期中..."
    echo "$SEP"
    echo ""

    # main/master に切り替えて pull
    git fetch origin "$PR_BASE_BRANCH" 2>/dev/null || true

    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

    if [ "$CURRENT_BRANCH" != "$PR_BASE_BRANCH" ]; then
        log_info "ブランチを $PR_BASE_BRANCH に切り替えます"
        git checkout "$PR_BASE_BRANCH" 2>/dev/null || true
    fi

    git pull origin "$PR_BASE_BRANCH" 2>/dev/null || true

    log_info "ローカルブランチの同期が完了しました"

else
    log_error "PR #$PR_NUMBER のマージに失敗しました"
    echo ""
    echo "  詳細を確認:"
    echo "    gh pr view $PR_NUMBER"
    echo "    gh pr checks $PR_NUMBER"
    exit 1
fi

# ============================================================
# 完了メッセージ
# ============================================================
echo ""
echo "$SEP"
echo "  ✅ PR マージ処理が完了しました"
echo "$SEP"
echo ""
echo "  次のステップ:"
echo "    1. git log で マージコミットを確認"
echo "    2. 次の playbook/Phase を開始"
echo ""

exit 0
