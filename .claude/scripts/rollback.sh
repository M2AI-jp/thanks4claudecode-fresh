#!/bin/bash
# ==============================================================================
# rollback.sh - Git ロールバックスクリプト
# ==============================================================================
# Issue #11: ロールバック機能
#
# 使用方法:
#   ./rollback.sh git {soft|mixed|hard} {n}     - n 回分の commit を reset
#   ./rollback.sh git revert {commit_hash}      - 特定コミットを revert
#   ./rollback.sh stash                         - 変更を stash に退避
#   ./rollback.sh stash-pop                     - stash から復元
#   ./rollback.sh status                        - ロールバック候補を表示
#   ./rollback.sh --help                        - ヘルプ表示
# ==============================================================================

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ヘルプ表示
show_help() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Git ロールバックスクリプト"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "使用方法:"
    echo "  ./rollback.sh git soft {n}        - n 回分の commit を soft reset"
    echo "                                      （変更はステージングに保持）"
    echo "  ./rollback.sh git mixed {n}       - n 回分の commit を mixed reset"
    echo "                                      （変更はワーキングディレクトリに保持）"
    echo "  ./rollback.sh git hard {n}        - n 回分の commit を hard reset"
    echo "                                      （変更も破棄 - 危険）"
    echo "  ./rollback.sh git revert {hash}   - 特定コミットを revert"
    echo "                                      （新コミットで打ち消し）"
    echo "  ./rollback.sh stash               - 変更を stash に退避"
    echo "  ./rollback.sh stash-pop           - stash から復元"
    echo "  ./rollback.sh status              - ロールバック候補を表示"
    echo "  ./rollback.sh --help              - このヘルプを表示"
    echo ""
    echo "例:"
    echo "  ./rollback.sh git soft 1          - 直前のコミットを soft reset"
    echo "  ./rollback.sh git revert abc123   - abc123 を revert"
    echo "  ./rollback.sh stash               - 現在の変更を退避"
    echo ""
}

# エラー表示
error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# 成功表示
success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# 警告表示
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 情報表示
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 未コミット変更の確認
check_uncommitted() {
    if [ -n "$(git status --porcelain)" ]; then
        warn "未コミットの変更があります"
        git status -sb
        echo ""
        return 1
    fi
    return 0
}

# ステータス表示
show_status() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ロールバック候補"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "最近のコミット（5件）:"
    git log --oneline -5
    echo ""

    if [ -n "$(git stash list)" ]; then
        echo "Stash 一覧:"
        git stash list
        echo ""
    fi

    echo "現在のブランチ: $(git branch --show-current)"
    echo "未コミット変更: $(git status --porcelain | wc -l | tr -d ' ') 件"
    echo ""
}

# Git soft reset
git_soft_reset() {
    local n=${1:-1}

    info "Soft reset を実行します（$n コミット）"

    # 確認
    echo "対象コミット:"
    git log --oneline -"$n"
    echo ""

    read -p "続行しますか？ [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "キャンセルしました"
        exit 0
    fi

    git reset --soft HEAD~"$n"
    success "Soft reset 完了（$n コミット）"
    echo ""
    echo "変更はステージングに保持されています:"
    git status -sb
}

# Git mixed reset
git_mixed_reset() {
    local n=${1:-1}

    info "Mixed reset を実行します（$n コミット）"

    # 確認
    echo "対象コミット:"
    git log --oneline -"$n"
    echo ""

    read -p "続行しますか？ [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "キャンセルしました"
        exit 0
    fi

    git reset HEAD~"$n"
    success "Mixed reset 完了（$n コミット）"
    echo ""
    echo "変更はワーキングディレクトリに保持されています:"
    git status -sb
}

# Git hard reset
git_hard_reset() {
    local n=${1:-1}

    warn "Hard reset は変更を完全に破棄します！"
    info "Hard reset を実行します（$n コミット）"

    # 確認
    echo "対象コミット:"
    git log --oneline -"$n"
    echo ""

    # 未コミット変更がある場合は警告
    if [ -n "$(git status --porcelain)" ]; then
        error "未コミットの変更があります。先に stash してください。"
        git status -sb
        exit 1
    fi

    read -p "本当に続行しますか？（変更は失われます）[y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "キャンセルしました"
        exit 0
    fi

    git reset --hard HEAD~"$n"
    success "Hard reset 完了（$n コミット）"
}

# Git revert
git_revert() {
    local commit_hash=$1

    if [ -z "$commit_hash" ]; then
        error "コミットハッシュを指定してください"
        exit 1
    fi

    info "Revert を実行します（$commit_hash）"

    # コミット情報を表示
    echo "対象コミット:"
    git log --oneline -1 "$commit_hash" 2>/dev/null || {
        error "コミット $commit_hash が見つかりません"
        exit 1
    }
    echo ""

    read -p "続行しますか？ [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "キャンセルしました"
        exit 0
    fi

    git revert --no-edit "$commit_hash"
    success "Revert 完了"
    echo ""
    echo "新しいコミットが作成されました:"
    git log --oneline -1
}

# Stash 作成
do_stash() {
    if [ -z "$(git status --porcelain)" ]; then
        info "stash する変更がありません"
        exit 0
    fi

    local message=${1:-"Rollback stash $(date +%Y%m%d-%H%M%S)"}

    git stash push -m "$message"
    success "変更を stash に退避しました"
    echo ""
    git stash list | head -1
}

# Stash pop
do_stash_pop() {
    if [ -z "$(git stash list)" ]; then
        info "stash がありません"
        exit 0
    fi

    git stash pop
    success "stash から復元しました"
    echo ""
    git status -sb
}

# メイン処理
main() {
    case "${1:-}" in
        git)
            case "${2:-}" in
                soft)
                    git_soft_reset "${3:-1}"
                    ;;
                mixed)
                    git_mixed_reset "${3:-1}"
                    ;;
                hard)
                    git_hard_reset "${3:-1}"
                    ;;
                revert)
                    git_revert "${3:-}"
                    ;;
                *)
                    error "不明な git サブコマンド: ${2:-}"
                    echo "使用可能: soft, mixed, hard, revert"
                    exit 1
                    ;;
            esac
            ;;
        stash)
            do_stash "${2:-}"
            ;;
        stash-pop)
            do_stash_pop
            ;;
        status)
            show_status
            ;;
        --help|-h|help)
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

main "$@"
