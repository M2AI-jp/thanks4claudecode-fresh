#!/bin/bash
# ==============================================================================
# state-rollback.sh - state.md ロールバックスクリプト
# ==============================================================================
# Issue #11: ロールバック機能
#
# 使用方法:
#   ./state-rollback.sh backup                   - 現在の state.md をバックアップ
#   ./state-rollback.sh list                     - バックアップ一覧を表示
#   ./state-rollback.sh rollback {n}             - n 世代前に復元
#   ./state-rollback.sh snapshot {name}          - 名前付きスナップショット作成
#   ./state-rollback.sh restore {snapshot_name}  - スナップショットから復元
#   ./state-rollback.sh cleanup                  - 古いバックアップを削除
#   ./state-rollback.sh --help                   - ヘルプ表示
# ==============================================================================

set -e

# 設定
STATE_FILE="state.md"
HISTORY_DIR=".claude/state-history"
SNAPSHOT_DIR=".claude/state-history/snapshots"
MAX_GENERATIONS=50
CLEANUP_THRESHOLD=60

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ヘルプ表示
show_help() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  state.md ロールバックスクリプト"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "使用方法:"
    echo "  ./state-rollback.sh backup              - 現在の state.md をバックアップ"
    echo "  ./state-rollback.sh list                - バックアップ一覧を表示"
    echo "  ./state-rollback.sh rollback {n}        - n 世代前に復元"
    echo "  ./state-rollback.sh snapshot {name}     - 名前付きスナップショット作成"
    echo "  ./state-rollback.sh restore {name}      - スナップショットから復元"
    echo "  ./state-rollback.sh cleanup             - 古いバックアップを削除"
    echo "  ./state-rollback.sh --help              - このヘルプを表示"
    echo ""
    echo "世代管理ルール:"
    echo "  - 最大 ${MAX_GENERATIONS} 世代を保持"
    echo "  - ${CLEANUP_THRESHOLD} 世代超過時に古い 10 世代を自動削除"
    echo "  - スナップショットは手動削除のみ"
    echo ""
    echo "例:"
    echo "  ./state-rollback.sh backup              - バックアップ作成"
    echo "  ./state-rollback.sh rollback 1          - 1 世代前に復元"
    echo "  ./state-rollback.sh snapshot phase-done - スナップショット作成"
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

# ディレクトリ初期化
init_dirs() {
    mkdir -p "$HISTORY_DIR"
    mkdir -p "$SNAPSHOT_DIR"
}

# バックアップ作成
do_backup() {
    init_dirs

    if [ ! -f "$STATE_FILE" ]; then
        error "state.md が存在しません"
        exit 1
    fi

    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="${HISTORY_DIR}/state-${timestamp}.md"

    cp "$STATE_FILE" "$backup_file"
    success "バックアップ作成: $backup_file"

    # 自動クリーンアップ
    local count=$(ls -1 "$HISTORY_DIR"/state-*.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "$count" -gt "$CLEANUP_THRESHOLD" ]; then
        warn "バックアップが ${count} 世代あります（閾値: ${CLEANUP_THRESHOLD}）"
        info "古い 10 世代を削除します"
        ls -1t "$HISTORY_DIR"/state-*.md | tail -10 | xargs rm -f
        success "クリーンアップ完了"
    fi
}

# バックアップ一覧
do_list() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  state.md バックアップ一覧"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ -d "$HISTORY_DIR" ]; then
        local count=$(ls -1 "$HISTORY_DIR"/state-*.md 2>/dev/null | wc -l | tr -d ' ')
        echo "自動バックアップ（${count} 件）:"
        if [ "$count" -gt 0 ]; then
            ls -lt "$HISTORY_DIR"/state-*.md 2>/dev/null | head -10 | awk '{print "  " NR ". " $NF " (" $6 " " $7 " " $8 ")"}'
            if [ "$count" -gt 10 ]; then
                echo "  ... 他 $((count - 10)) 件"
            fi
        else
            echo "  （なし）"
        fi
    else
        echo "自動バックアップ: （なし）"
    fi

    echo ""

    if [ -d "$SNAPSHOT_DIR" ]; then
        local snap_count=$(ls -1 "$SNAPSHOT_DIR"/snapshot-*.md 2>/dev/null | wc -l | tr -d ' ')
        echo "スナップショット（${snap_count} 件）:"
        if [ "$snap_count" -gt 0 ]; then
            for f in "$SNAPSHOT_DIR"/snapshot-*.md; do
                local name=$(basename "$f" .md | sed 's/snapshot-//')
                echo "  - $name"
            done
        else
            echo "  （なし）"
        fi
    else
        echo "スナップショット: （なし）"
    fi

    echo ""
}

# n 世代前に復元
do_rollback() {
    local n=${1:-1}

    if [ ! -d "$HISTORY_DIR" ]; then
        error "バックアップが存在しません"
        exit 1
    fi

    local files=($(ls -1t "$HISTORY_DIR"/state-*.md 2>/dev/null))
    local count=${#files[@]}

    if [ "$count" -eq 0 ]; then
        error "バックアップが存在しません"
        exit 1
    fi

    if [ "$n" -gt "$count" ]; then
        error "指定した世代 ($n) が存在しません（最大: $count）"
        exit 1
    fi

    local target_file="${files[$((n-1))]}"

    info "復元対象: $target_file"
    echo ""
    echo "復元前の state.md をバックアップします..."
    do_backup

    read -p "state.md を復元しますか？ [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "キャンセルしました"
        exit 0
    fi

    cp "$target_file" "$STATE_FILE"
    success "state.md を復元しました"
}

# スナップショット作成
do_snapshot() {
    local name=$1

    if [ -z "$name" ]; then
        error "スナップショット名を指定してください"
        exit 1
    fi

    init_dirs

    if [ ! -f "$STATE_FILE" ]; then
        error "state.md が存在しません"
        exit 1
    fi

    local timestamp=$(date +%Y%m%d-%H%M%S)
    local snapshot_file="${SNAPSHOT_DIR}/snapshot-${name}-${timestamp}.md"

    cp "$STATE_FILE" "$snapshot_file"
    success "スナップショット作成: $snapshot_file"
}

# スナップショットから復元
do_restore() {
    local name=$1

    if [ -z "$name" ]; then
        error "スナップショット名を指定してください"
        exit 1
    fi

    local snapshot_file=$(ls -1t "$SNAPSHOT_DIR"/snapshot-${name}*.md 2>/dev/null | head -1)

    if [ -z "$snapshot_file" ]; then
        error "スナップショット '$name' が見つかりません"
        exit 1
    fi

    info "復元対象: $snapshot_file"
    echo ""
    echo "復元前の state.md をバックアップします..."
    do_backup

    read -p "state.md を復元しますか？ [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "キャンセルしました"
        exit 0
    fi

    cp "$snapshot_file" "$STATE_FILE"
    success "state.md を復元しました"
}

# クリーンアップ
do_cleanup() {
    if [ ! -d "$HISTORY_DIR" ]; then
        info "クリーンアップするバックアップがありません"
        exit 0
    fi

    local count=$(ls -1 "$HISTORY_DIR"/state-*.md 2>/dev/null | wc -l | tr -d ' ')

    if [ "$count" -le "$MAX_GENERATIONS" ]; then
        info "バックアップは ${count} 件です（最大: ${MAX_GENERATIONS}）。クリーンアップ不要です。"
        exit 0
    fi

    local to_delete=$((count - MAX_GENERATIONS))
    warn "${to_delete} 件のバックアップを削除します"

    read -p "続行しますか？ [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "キャンセルしました"
        exit 0
    fi

    ls -1t "$HISTORY_DIR"/state-*.md | tail -"$to_delete" | xargs rm -f
    success "クリーンアップ完了（${to_delete} 件削除）"
}

# メイン処理
main() {
    case "${1:-}" in
        backup)
            do_backup
            ;;
        list)
            do_list
            ;;
        rollback)
            do_rollback "${2:-1}"
            ;;
        snapshot)
            do_snapshot "${2:-}"
            ;;
        restore)
            do_restore "${2:-}"
            ;;
        cleanup)
            do_cleanup
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
