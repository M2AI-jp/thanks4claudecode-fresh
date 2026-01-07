#!/bin/bash
# archive-project.sh - Project 完了処理とアーカイブ
#
# 設計書: docs/project-lifecycle.md
# 呼び出し元: archive-playbook.sh（全 playbook 完了時）
#
# 処理フロー:
#   Step 1: Project 存在確認
#   Step 2: 完了判定（全 playbook done か）
#   Step 3: project.json 更新（closed_at, closed_by）
#   Step 4: アーカイブ（play/archive/projects/ へ移動）
#   Step 5: state.md 更新（project.active = null）
#   Step 6: Git 操作
#   Step 7: 完了ログ出力

set -e

# ==============================================================================
# 引数チェック
# ==============================================================================
PROJECT_ID="${1:-}"

if [ -z "$PROJECT_ID" ]; then
    echo '{"status": "error", "message": "PROJECT_ID が指定されていません"}' >&2
    exit 1
fi

# ==============================================================================
# 定数
# ==============================================================================
PROJECT_DIR="play/projects/$PROJECT_ID"
PROJECT_FILE="$PROJECT_DIR/project.json"
ARCHIVE_DIR="play/archive/projects"
STATE_FILE="state.md"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ==============================================================================
# Step 1: Project 存在確認
# ==============================================================================
log_info "Step 1: Project 存在確認"

if [ ! -d "$PROJECT_DIR" ]; then
    log_warn "Project ディレクトリが存在しません: $PROJECT_DIR"
    echo '{"status": "skip", "message": "Project ディレクトリが存在しません"}'
    exit 0
fi

if [ ! -f "$PROJECT_FILE" ]; then
    log_warn "project.json が存在しません: $PROJECT_FILE"
    echo '{"status": "skip", "message": "project.json が存在しません"}'
    exit 0
fi

log_info "Project 確認: $PROJECT_ID"

# ==============================================================================
# Step 2: 完了判定
# ==============================================================================
log_info "Step 2: 完了判定"

# jq がない場合はエラー
if ! command -v jq &> /dev/null; then
    log_error "jq が見つかりません"
    echo '{"status": "error", "message": "jq が見つかりません"}' >&2
    exit 1
fi

# 残り playbook をチェック
REMAINING=$(jq '[.milestones[].playbooks[] | select(.status != "done")] | length' "$PROJECT_FILE" 2>/dev/null || echo "-1")

if [ "$REMAINING" = "-1" ]; then
    log_error "project.json の解析に失敗しました"
    echo '{"status": "error", "message": "project.json の解析に失敗しました"}' >&2
    exit 1
fi

if [ "$REMAINING" -gt 0 ]; then
    log_info "残り playbook: $REMAINING 件（アーカイブをスキップ）"
    echo "{\"status\": \"skip\", \"message\": \"残り playbook: $REMAINING 件\", \"remaining_playbooks\": $REMAINING}"
    exit 0
fi

log_info "全 playbook 完了確認"

# ==============================================================================
# Step 3: project.json 更新
# ==============================================================================
log_info "Step 3: project.json 更新"

TIMESTAMP=$(date -Iseconds)

jq --arg ts "$TIMESTAMP" '
    .meta.status = "closed" |
    .meta.closed_at = $ts |
    .meta.closed_by = "archive-project.sh"
' "$PROJECT_FILE" > "$PROJECT_FILE.tmp" && mv "$PROJECT_FILE.tmp" "$PROJECT_FILE"

log_info "project.json 更新完了: status=closed, closed_at=$TIMESTAMP"

# ==============================================================================
# Step 4: アーカイブ
# ==============================================================================
log_info "Step 4: アーカイブ"

mkdir -p "$ARCHIVE_DIR"

if [ -d "$ARCHIVE_DIR/$PROJECT_ID" ]; then
    log_warn "アーカイブ先に既に存在します: $ARCHIVE_DIR/$PROJECT_ID"
    # 既存のアーカイブを削除して上書き
    rm -rf "$ARCHIVE_DIR/$PROJECT_ID"
fi

mv "$PROJECT_DIR" "$ARCHIVE_DIR/"
log_info "アーカイブ完了: $ARCHIVE_DIR/$PROJECT_ID"

# ==============================================================================
# Step 5: state.md 更新
# ==============================================================================
log_info "Step 5: state.md 更新"

if [ -f "$STATE_FILE" ]; then
    # project セクションの更新
    sed -i '' 's/^active: play\/projects\/.*/active: null/' "$STATE_FILE" 2>/dev/null || true
    sed -i '' 's/^current_milestone: .*/current_milestone: null/' "$STATE_FILE" 2>/dev/null || true
    sed -i '' 's/^status: in_progress/status: idle/' "$STATE_FILE" 2>/dev/null || true
    log_info "state.md 更新完了"
else
    log_warn "state.md が見つかりません"
fi

# ==============================================================================
# Step 6: Git 操作
# ==============================================================================
log_info "Step 6: Git 操作"

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    git add -A
    git commit -m "chore: archive project $PROJECT_ID

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" || log_warn "コミットに失敗しました"
    log_info "コミット完了"
else
    log_info "変更なし。コミットスキップ。"
fi

# ==============================================================================
# Step 7: 完了ログ出力
# ==============================================================================
log_info "Step 7: 完了"

cat << EOF
{
  "status": "success",
  "project_id": "$PROJECT_ID",
  "archived_to": "$ARCHIVE_DIR/$PROJECT_ID",
  "closed_at": "$TIMESTAMP",
  "message": "Project アーカイブ完了"
}
EOF

exit 0
