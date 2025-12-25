#!/bin/bash
# abort.sh - playbook を明示的に中断・破棄
#
# 使用方法:
#   bash abort.sh [playbook_path]
#   引数省略時は state.md の playbook.active を使用
#
# 処理内容:
#   1. 未コミット変更の確認（警告のみ）
#   2. playbook を plan/archive/ へ移動（status: aborted 付与）
#   3. state.md を更新（playbook.active = null）
#   4. ブランチ処理の案内（削除はしない）

set -e

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

STATE_FILE="state.md"
ARCHIVE_DIR="plan/archive"

# ==============================================================================
# Step 0: playbook パスの取得
# ==============================================================================

PLAYBOOK_PATH="$1"

if [ -z "$PLAYBOOK_PATH" ]; then
    # state.md から playbook.active を取得
    if [ ! -f "$STATE_FILE" ]; then
        log_error "state.md が見つかりません"
        exit 1
    fi

    PLAYBOOK_PATH=$(grep -A5 "^## playbook" "$STATE_FILE" | grep "^active:" | head -1 | sed 's/active: *//' | tr -d ' \r')

    if [ -z "$PLAYBOOK_PATH" ] || [ "$PLAYBOOK_PATH" = "null" ]; then
        log_error "playbook.active が設定されていません"
        echo ""
        echo "  使用方法: bash abort.sh [playbook_path]"
        echo "  または state.md の playbook.active を設定してください"
        exit 1
    fi
fi

# playbook ファイルの存在確認
if [ ! -f "$PLAYBOOK_PATH" ]; then
    log_error "playbook ファイルが見つかりません: $PLAYBOOK_PATH"
    exit 1
fi

PLAYBOOK_NAME=$(basename "$PLAYBOOK_PATH")
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

echo ""
echo "$SEP"
echo "  🛑 Playbook 中断処理"
echo "$SEP"
echo ""
echo "  Playbook: $PLAYBOOK_PATH"
echo "  Branch: $CURRENT_BRANCH"
echo ""

# ==============================================================================
# Step 1: 未コミット変更の確認
# ==============================================================================

echo "$SEP"
echo "  Step 1: 未コミット変更の確認"
echo "$SEP"

UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
    log_warn "未コミット変更が $UNCOMMITTED 件あります"
    echo ""
    git status --short
    echo ""
    echo "  注意: abort 処理は変更を破棄しません。"
    echo "  必要に応じて git stash または git commit を実行してください。"
else
    log_info "未コミット変更なし"
fi

# ==============================================================================
# Step 2: playbook を plan/archive/ へ移動
# ==============================================================================

echo ""
echo "$SEP"
echo "  Step 2: playbook をアーカイブ"
echo "$SEP"

# archive ディレクトリ作成
mkdir -p "$ARCHIVE_DIR"

# status: aborted を meta セクションに追加
TIMESTAMP=$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S")

# 一時ファイルに書き込み
TEMP_FILE=$(mktemp)

# meta セクションに aborted 情報を追加
awk -v ts="$TIMESTAMP" '
/^```yaml$/ && found_meta {
    print
    getline
    print
    print "status: aborted"
    print "aborted_at: " ts
    found_meta = 0
    next
}
/^## meta$/ {
    found_meta = 1
}
{ print }
' "$PLAYBOOK_PATH" > "$TEMP_FILE"

# 移動
if mv "$TEMP_FILE" "$ARCHIVE_DIR/$PLAYBOOK_NAME" 2>/dev/null; then
    log_info "アーカイブ完了: $ARCHIVE_DIR/$PLAYBOOK_NAME"
    # 元ファイルを削除
    rm -f "$PLAYBOOK_PATH"
else
    log_error "アーカイブに失敗しました"
    rm -f "$TEMP_FILE"
    exit 1
fi

# ==============================================================================
# Step 3: state.md を更新（対象 playbook が active の場合のみ）
# ==============================================================================

echo ""
echo "$SEP"
echo "  Step 3: state.md を更新"
echo "$SEP"

if [ -f "$STATE_FILE" ]; then
    # 現在の playbook.active を取得
    CURRENT_ACTIVE=$(grep -A5 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | tr -d ' \r' || echo "")

    # 対象 playbook が active の場合のみ null に更新
    if [ "$CURRENT_ACTIVE" = "$PLAYBOOK_PATH" ]; then
        # playbook.active を null に
        sed -i '' 's/^active: .*/active: null/' "$STATE_FILE" 2>/dev/null || \
        sed -i 's/^active: .*/active: null/' "$STATE_FILE" 2>/dev/null || true

        # playbook.branch を null に
        sed -i '' 's/^branch: .*/branch: null/' "$STATE_FILE" 2>/dev/null || \
        sed -i 's/^branch: .*/branch: null/' "$STATE_FILE" 2>/dev/null || true

        log_info "state.md 更新完了"
        echo "  - playbook.active = null"
        echo "  - playbook.branch = null"
    else
        log_info "orphan playbook のため state.md は変更しません"
        echo "  - 現在の active: $CURRENT_ACTIVE"
        echo "  - abort 対象: $PLAYBOOK_PATH"
    fi
else
    log_warn "state.md が見つかりません"
fi

# ==============================================================================
# Step 4: ブランチ処理の案内
# ==============================================================================

echo ""
echo "$SEP"
echo "  Step 4: ブランチ処理の案内"
echo "$SEP"

if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo ""
    echo "  現在のブランチ: ${CYAN}$CURRENT_BRANCH${NC}"
    echo ""
    echo "  ブランチを削除する場合:"
    echo "    git checkout main && git branch -D $CURRENT_BRANCH"
    echo ""
    echo "  ブランチを保持する場合:"
    echo "    そのまま残す（後で再開可能）"
else
    log_info "main ブランチにいるため、ブランチ処理は不要です"
fi

# ==============================================================================
# 完了メッセージ
# ==============================================================================

echo ""
echo "$SEP"
echo "  ✅ Playbook 中断完了"
echo "$SEP"
echo ""
echo "  処理結果:"
echo "    - playbook: $ARCHIVE_DIR/$PLAYBOOK_NAME (status: aborted)"
echo "    - state.md: playbook.active = null"
echo ""

exit 0
