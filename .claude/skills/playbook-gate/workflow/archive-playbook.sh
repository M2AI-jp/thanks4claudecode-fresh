#!/bin/bash
# archive-playbook.sh - playbook 完了時の自動処理
#
# 発火条件: PostToolUse:Edit
# 目的: playbook の全 Phase が done になったら自動でアーカイブ・PR 作成・マージを実行
#
# 設計思想（2025-12-25 改善）:
#   - playbook 完了を自動検出
#   - 自動実行: コミット、push、PR 作成、アーカイブ、マージ
#   - pending ファイルで post-loop Skill 呼び出しを強制
#   - 失敗時は警告を出力して続行（部分的成功を許容）
#
# 処理順序（内部ステップ番号）:
#   1. 自動コミット（未コミット変更がある場合）
#   2. push（PR 作成前に必要）
#   3. PR 作成（create-pr.sh - playbook.active が必要）
#   4. バックグラウンドタスク クリーンアップ（M088、旧 Step 3.5）
#   5. playbook アーカイブ（play/archive/ へ移動、旧 Step 4）
#   6. アーカイブのコミット（playbook 移動のみ、旧 Step 5）
#   7. push（アーカイブ分、旧 Step 6）
#   8. state.md 更新（playbook.active = null、旧 Step 7）
#   9. state.md 更新のコミット（旧 Step 8）
#   10. push（state.md 分、旧 Step 9）
#   11. PR マージ（merge-pr.sh、旧 Step 10）
#   12. main 同期（旧 Step 11）
#   13. pending ファイル作成（旧 Step 12）
#   14. Project 完了チェック（M090 連携 - archive-project.sh 呼び出し）
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
SESSION_STATE_DIR=".claude/session-state"
PENDING_FILE="$SESSION_STATE_DIR/post-loop-pending"
BG_TASKS_FILE="$SESSION_STATE_DIR/background-tasks.json"
CHECKPOINT_FILE="$SESSION_STATE_DIR/archive-checkpoint.json"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ステータス追跡
OVERALL_STATUS="success"
CURRENT_STEP=0

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; OVERALL_STATUS="partial"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; OVERALL_STATUS="partial"; }

# デバッグログ（SubagentStop 経由のデバッグ用）
CLAUDE_DIR="${CLAUDE_DIR:-.claude}"
DEBUG_LOG="${CLAUDE_DIR}/logs/archive-playbook.log"
log_debug() {
    local msg="$1"
    mkdir -p "$(dirname "$DEBUG_LOG")"
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $msg" >> "$DEBUG_LOG"
}

# ==============================================================================
# チェックポイント機構
# ==============================================================================

# チェックポイント初期化
init_checkpoint() {
    local playbook_id="$1"
    mkdir -p "$SESSION_STATE_DIR"
    cat > "$CHECKPOINT_FILE" << EOF
{
  "playbook_id": "$playbook_id",
  "started_at": "$(date -Iseconds)",
  "current_step": 0,
  "completed_steps": [],
  "failed_step": null,
  "last_error": null
}
EOF
}

# ステップ開始時に呼ぶ
update_checkpoint_start() {
    local step="$1"
    CURRENT_STEP="$step"
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        local tmp_file="${CHECKPOINT_FILE}.tmp"
        jq --argjson step "$step" '.current_step = $step' "$CHECKPOINT_FILE" > "$tmp_file" && mv "$tmp_file" "$CHECKPOINT_FILE"
    fi
}

# ステップ完了時に呼ぶ
update_checkpoint_complete() {
    local step="$1"
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        local tmp_file="${CHECKPOINT_FILE}.tmp"
        jq --argjson step "$step" '.completed_steps += [$step]' "$CHECKPOINT_FILE" > "$tmp_file" && mv "$tmp_file" "$CHECKPOINT_FILE"
    fi
}

# エラー時に呼ぶ
update_checkpoint_error() {
    local step="$1"
    local error_msg="$2"
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        local tmp_file="${CHECKPOINT_FILE}.tmp"
        jq --argjson step "$step" --arg err "$error_msg" '.failed_step = $step | .last_error = $err' "$CHECKPOINT_FILE" > "$tmp_file" && mv "$tmp_file" "$CHECKPOINT_FILE"
    fi
}

# 完了時にチェックポイント削除
cleanup_checkpoint() {
    rm -f "$CHECKPOINT_FILE"
}

# エラーハンドリング（set -e と併用）
handle_error() {
    local exit_code="$1"
    local command="$2"
    local step="$3"
    update_checkpoint_error "$step" "Exit code $exit_code: $command"
    exit "$exit_code"
}

trap 'handle_error $? "$BASH_COMMAND" "$CURRENT_STEP"' ERR

# ==============================================================================
# M088: バックグラウンドタスクのクリーンアップ（Phase 完了時）
# ==============================================================================
cleanup_background_tasks_for_phase() {
    local phase="$1"

    if [[ ! -f "$BG_TASKS_FILE" ]]; then
        return 0
    fi

    # jq がない場合はスキップ
    if ! command -v jq &> /dev/null; then
        return 0
    fi

    # 該当 phase のタスク数を確認
    PHASE_TASK_COUNT=$(jq --arg phase "$phase" '[.tasks[] | select(.phase == $phase)] | length' "$BG_TASKS_FILE" 2>/dev/null || echo "0")
    if [[ "$PHASE_TASK_COUNT" -eq 0 ]]; then
        log_info "バックグラウンドタスク: phase '$phase' に関連するタスクなし"
        return 0
    fi

    log_info "バックグラウンドタスク: phase '$phase' のタスクをクリーンアップ中..."

    # 保護リストを取得
    PROTECTED=$(jq -r '.metadata.protected_commands[]?' "$BG_TASKS_FILE" 2>/dev/null || echo "")

    # 該当 phase のタスクを終了
    jq -r --arg phase "$phase" '.tasks[] | select(.phase == $phase) | "\(.pid)|\(.command)"' "$BG_TASKS_FILE" 2>/dev/null | while IFS='|' read -r pid command; do
        # 保護リストチェック
        IS_PROTECTED=false
        for protected_cmd in $PROTECTED; do
            if [[ "$command" == *"$protected_cmd"* ]]; then
                IS_PROTECTED=true
                break
            fi
        done

        if [[ "$IS_PROTECTED" == true ]]; then
            log_info "  [SKIP] PID $pid: $command (protected)"
            continue
        fi

        # プロセスが存在するか確認
        if kill -0 "$pid" 2>/dev/null; then
            log_info "  [STOP] PID $pid: $command"
            kill "$pid" 2>/dev/null || true
        fi
    done

    # 該当 phase のタスクをリストから削除
    jq --arg phase "$phase" 'del(.tasks[] | select(.phase == $phase)) | .metadata.updated_at = now | .metadata.updated_at |= tostring' "$BG_TASKS_FILE" > "$BG_TASKS_FILE.tmp" 2>/dev/null && \
        mv "$BG_TASKS_FILE.tmp" "$BG_TASKS_FILE"

    log_info "バックグラウンドタスク クリーンアップ完了"
}

# ==============================================================================
# コマンドライン引数の解析
# ==============================================================================
RESUME_MODE=false
SHOW_HELP=false
RESUME_FROM_CHECKPOINT=false
RESUME_STEP=0

# 引数解析
while [[ $# -gt 0 ]]; do
    case "$1" in
        --resume)
            RESUME_MODE=true
            shift
            ;;
        -h|--help)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# ヘルプ表示
if [[ "$SHOW_HELP" == true ]]; then
    cat << 'HELPEOF'
Usage: archive-playbook.sh [OPTIONS]

Options:
  --resume    前回失敗したアーカイブ処理を再開します。
              チェックポイントファイルから状態を復元し、
              失敗したステップから処理を再開します。
  -h, --help  このヘルプを表示します。

通常実行:
  stdin から JSON 入力を受け取り、playbook の完了を検出して
  自動アーカイブ処理を実行します。

再開実行:
  $ archive-playbook.sh --resume

チェックポイントファイル:
  .claude/session-state/archive-checkpoint.json

HELPEOF
    exit 0
fi

# ==============================================================================
# --resume モードの処理
# ==============================================================================
if [[ "$RESUME_MODE" == true ]]; then
    log_info "再開モードで起動しました"
    
    # チェックポイントファイルの存在確認
    if [[ ! -f "$CHECKPOINT_FILE" ]]; then
        log_error "チェックポイントファイルが見つかりません: $CHECKPOINT_FILE"
        log_error "再開可能なアーカイブ処理がありません。"
        exit 1
    fi
    
    # jq がない場合はエラー
    if ! command -v jq &> /dev/null; then
        log_error "jq が見つかりません。再開処理には jq が必要です。"
        exit 1
    fi
    
    # チェックポイントから状態を読み込み
    CHECKPOINT_PLAYBOOK_ID=$(jq -r '.playbook_id // ""' "$CHECKPOINT_FILE")
    CHECKPOINT_FAILED_STEP=$(jq -r '.failed_step // 0' "$CHECKPOINT_FILE")
    CHECKPOINT_LAST_ERROR=$(jq -r '.last_error // ""' "$CHECKPOINT_FILE")
    CHECKPOINT_COMPLETED=$(jq -r '.completed_steps | @json' "$CHECKPOINT_FILE")
    
    if [[ -z "$CHECKPOINT_PLAYBOOK_ID" ]]; then
        log_error "チェックポイントファイルが不正です: playbook_id が空"
        exit 1
    fi
    
    if [[ "$CHECKPOINT_FAILED_STEP" == "null" ]] || [[ "$CHECKPOINT_FAILED_STEP" == "0" ]]; then
        log_error "チェックポイントに失敗ステップが記録されていません"
        log_error "正常終了したか、まだ開始されていない可能性があります"
        exit 1
    fi
    
    log_info "チェックポイント情報:"
    log_info "  Playbook ID: $CHECKPOINT_PLAYBOOK_ID"
    log_info "  失敗ステップ: $CHECKPOINT_FAILED_STEP"
    log_info "  エラー: $CHECKPOINT_LAST_ERROR"
    log_info "  完了済みステップ: $CHECKPOINT_COMPLETED"
    
    # 変数の設定（通常フローで設定される値を復元）
    PLAYBOOK_ID="$CHECKPOINT_PLAYBOOK_ID"
    PLAYBOOK_NAME="$PLAYBOOK_ID"
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    
    # PLAYBOOK_DIR の復元（アーカイブ前 or アーカイブ後を判定）
    # ステップ5以降で失敗した場合、playbook は既にアーカイブ済みの可能性がある
    if [[ -d "play/playbooks/$PLAYBOOK_ID" ]]; then
        PLAYBOOK_DIR="play/playbooks/$PLAYBOOK_ID"
    elif [[ -d "play/$PLAYBOOK_ID" ]]; then
        PLAYBOOK_DIR="play/$PLAYBOOK_ID"
    elif [[ -d "play/archive/standalone/$PLAYBOOK_ID" ]]; then
        PLAYBOOK_DIR="play/archive/standalone/$PLAYBOOK_ID"
        ARCHIVE_DIR="play/archive/standalone"
    else
        # project 配下を検索
        FOUND_DIR=$(find play -type d -name "$PLAYBOOK_ID" 2>/dev/null | head -1)
        if [[ -n "$FOUND_DIR" ]]; then
            PLAYBOOK_DIR="$FOUND_DIR"
        else
            log_warn "playbook ディレクトリが見つかりません（既に完全にアーカイブ済みの可能性）"
            PLAYBOOK_DIR=""
        fi
    fi
    
    # ARCHIVE_DIR の設定（まだ設定されていない場合）
    if [[ -z "${ARCHIVE_DIR:-}" ]]; then
        # state.md から parent_project を取得
        PARENT_PROJECT=""
        if [ -f "state.md" ]; then
            PARENT_PROJECT=$(grep '^parent_project:' state.md 2>/dev/null | sed 's/parent_project: *//' | tr -d ' ')
        fi
        
        if [ -n "$PARENT_PROJECT" ] && [ "$PARENT_PROJECT" != "null" ]; then
            ARCHIVE_DIR="play/archive/projects/$PARENT_PROJECT/playbooks"
        else
            ARCHIVE_DIR="play/archive/standalone"
        fi
    fi
    
    echo ""
    echo "$SEP"
    echo "  Playbook アーカイブ再開"
    echo "$SEP"
    echo ""
    echo "  Playbook: $PLAYBOOK_ID"
    echo "  再開ステップ: $CHECKPOINT_FAILED_STEP"
    echo "  Branch: $CURRENT_BRANCH"
    echo ""
    
    # 失敗ステップにジャンプするためのフラグ設定
    RESUME_FROM_CHECKPOINT=true
    RESUME_STEP="$CHECKPOINT_FAILED_STEP"
    
    # 以下の通常フローへジャンプ（stdin 読み込みをスキップ）
fi

# ==============================================================================
# 通常モード: stdin から JSON を読み込んで playbook 完了を検出
# ==============================================================================
if [[ "$RESUME_FROM_CHECKPOINT" != true ]]; then
    # state.md が存在しない場合はスキップ
    if [ ! -f "state.md" ]; then
        log_debug "SKIP: state.md not found"
        exit 0
    fi

    # stdin から JSON を読み込む
    INPUT=$(cat)

    # jq がない場合はスキップ
    if ! command -v jq &> /dev/null; then
        log_debug "SKIP: jq not found"
        exit 0
    fi

    # 編集対象ファイルを取得
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
    if [[ -z "$FILE_PATH" ]]; then
        log_debug "SKIP: file_path is empty"
        exit 0
    fi

    # progress.json 以外は無視
    case "$FILE_PATH" in
        */play/*/progress.json) ;;
        *)
            log_debug "SKIP: not a progress.json: $FILE_PATH"
            exit 0
            ;;
    esac

    if [[ "$FILE_PATH" == */archive/* ]] || [[ "$FILE_PATH" == */template/* ]]; then
        log_debug "SKIP: archive or template path: $FILE_PATH"
        exit 0
    fi

    if [ ! -f "$FILE_PATH" ]; then
        log_debug "SKIP: file not found: $FILE_PATH"
        exit 0
    fi

    if ! jq -e . "$FILE_PATH" >/dev/null 2>&1; then
        log_debug "SKIP: invalid JSON: $FILE_PATH"
        exit 0
    fi

    # 全 Phase が done であるかチェック
    TOTAL_PHASES=$(jq '.phases | length' "$FILE_PATH" 2>/dev/null || echo "0")
    DONE_PHASES=$(jq '[.phases[] | select(.status == "done" or .status == "completed")] | length' "$FILE_PATH" 2>/dev/null || echo "0")
    TOTAL_PHASES=${TOTAL_PHASES:-0}
    DONE_PHASES=${DONE_PHASES:-0}

    if [ "$TOTAL_PHASES" -eq 0 ]; then
        log_debug "SKIP: TOTAL_PHASES is 0"
        exit 0
    fi

    if [ "$DONE_PHASES" -ne "$TOTAL_PHASES" ]; then
        log_debug "SKIP: phases not complete ($DONE_PHASES/$TOTAL_PHASES)"
        exit 0
    fi

    # 全 subtask 完了チェック
    INCOMPLETE_COUNT=$(jq '[.subtasks[] | select(.status != "done")] | length' "$FILE_PATH" 2>/dev/null || echo "0")
    INCOMPLETE_COUNT=${INCOMPLETE_COUNT:-0}

    if [ "$INCOMPLETE_COUNT" -gt 0 ]; then
        log_debug "SKIP: incomplete subtasks: $INCOMPLETE_COUNT"
        exit 0
    fi

    log_debug "TRIGGER: all phases done in $FILE_PATH"

    # ==============================================================================
    # ここから実際の処理
    # ==============================================================================

    # playbook ディレクトリを特定
    PLAYBOOK_DIR=$(dirname "$FILE_PATH")
    # playbook ID を取得
    if [ -f "$PLAYBOOK_DIR/playbook.md" ]; then
        PLAYBOOK_ID=$(grep -m1 '^id:' "$PLAYBOOK_DIR/playbook.md" 2>/dev/null | sed 's/id: *//' || basename "$PLAYBOOK_DIR")
    else
        PLAYBOOK_ID=$(basename "$PLAYBOOK_DIR")
    fi
    PLAYBOOK_NAME="$PLAYBOOK_ID"
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

    # チェックポイント初期化
    init_checkpoint "$PLAYBOOK_ID"

    # ==============================================================================
    # M090: Project 階層判定
    # playbook が project 配下か standalone かを判定し、アーカイブ先を決定
    # ==============================================================================
    PARENT_PROJECT=""
    ARCHIVE_DIR="play/archive/standalone"  # デフォルトは standalone

    # state.md から parent_project を取得
    if [ -f "state.md" ]; then
        PARENT_PROJECT=$(grep '^parent_project:' state.md 2>/dev/null | sed 's/parent_project: *//' | tr -d ' ')
    fi

    # playbook パスから project を判定（state.md の情報がない場合のフォールバック）
    if [ -z "$PARENT_PROJECT" ] || [ "$PARENT_PROJECT" = "null" ]; then
        # パスが play/projects/<project-id>/playbooks/<playbook-id>/ の形式か確認
        if echo "$PLAYBOOK_DIR" | grep -q "play/projects/.*/playbooks/"; then
            PARENT_PROJECT=$(echo "$PLAYBOOK_DIR" | sed 's|play/projects/\([^/]*\)/playbooks/.*|\1|')
        fi
    fi

    # アーカイブ先の決定
    if [ -n "$PARENT_PROJECT" ] && [ "$PARENT_PROJECT" != "null" ]; then
        ARCHIVE_DIR="play/archive/projects/$PARENT_PROJECT/playbooks"
        log_info "Project 配下の playbook を検出: $PARENT_PROJECT"
    else
        ARCHIVE_DIR="play/archive/standalone"
        log_info "単発 playbook を検出"
    fi

    echo ""
    echo "$SEP"
    echo "  Playbook 完了検出 → 自動処理開始"
    echo "$SEP"
    echo ""
    echo "  Playbook: $PLAYBOOK_ID"
    echo "  Status: 全 $TOTAL_PHASES Phase が done"
    echo "  Branch: $CURRENT_BRANCH"
    echo ""
fi

# ==============================================================================
# ステップ実行ヘルパー関数
# RESUME_FROM_CHECKPOINT が true の場合、RESUME_STEP 以降のみ実行
# ==============================================================================
should_run_step() {
    local step="$1"
    if [[ "$RESUME_FROM_CHECKPOINT" == true ]]; then
        if [[ "$step" -lt "$RESUME_STEP" ]]; then
            return 1  # スキップ
        fi
    fi
    return 0  # 実行
}

# ==============================================================================
# Step 1: 自動コミット
# ==============================================================================
if should_run_step 1; then
    echo "$SEP"
    echo "  Step 1: 自動コミット"
    echo "$SEP"

    update_checkpoint_start 1

    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        log_info "未コミット変更を検出。コミットします..."
        git add -A
        git commit -m "feat(${PLAYBOOK_NAME}): playbook 完了

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" || log_warn "コミットに失敗しました"
        log_info "コミット完了"
    else
        log_info "未コミット変更なし。スキップ。"
    fi

    update_checkpoint_complete 1
fi

# ==============================================================================
# Step 2: Push（PR 作成前に必要）
# ==============================================================================
if should_run_step 2; then
    echo ""
    echo "$SEP"
    echo "  Step 2: Push"
    echo "$SEP"

    update_checkpoint_start 2

    if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
        if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' &> /dev/null; then
            git push -u origin "$CURRENT_BRANCH" 2>&1 || log_warn "push に失敗しました"
        else
            git push 2>&1 || log_warn "push に失敗しました"
        fi
        log_info "Push 完了"
    else
        log_info "main ブランチのため push スキップ"
    fi

    update_checkpoint_complete 2
fi

# ==============================================================================
# Step 3: PR 作成
# ==============================================================================
if should_run_step 3; then
    echo ""
    echo "$SEP"
    echo "  Step 3: PR 作成"
    echo "$SEP"

    update_checkpoint_start 3

    CREATE_PR_SCRIPT="$SKILLS_DIR/git-workflow/handlers/create-pr.sh"
    if [ -x "$CREATE_PR_SCRIPT" ]; then
        bash "$CREATE_PR_SCRIPT" || log_warn "PR 作成に失敗しました（既存の可能性あり）"
    else
        log_warn "create-pr.sh が見つかりません: $CREATE_PR_SCRIPT"
    fi

    update_checkpoint_complete 3
fi

# ==============================================================================
# Step 4: バックグラウンドタスク クリーンアップ（M088）
# ==============================================================================
if should_run_step 4; then
    echo ""
    echo "$SEP"
    echo "  Step 4: バックグラウンドタスク クリーンアップ"
    echo "$SEP"

    update_checkpoint_start 4

    # playbook 完了時は全 phase のタスクをクリーンアップ
    cleanup_background_tasks_for_phase "all"

    update_checkpoint_complete 4
fi

# ==============================================================================
# Step 5: Playbook アーカイブ
# ==============================================================================
if should_run_step 5; then
    echo ""
    echo "$SEP"
    echo "  Step 5: Playbook アーカイブ"
    echo "$SEP"

    update_checkpoint_start 5

    mkdir -p "$ARCHIVE_DIR"
    if [[ -n "$PLAYBOOK_DIR" ]] && [[ -d "$PLAYBOOK_DIR" ]]; then
        # アーカイブ先に既に存在するかチェック
        if [[ -d "$ARCHIVE_DIR/$PLAYBOOK_NAME" ]]; then
            log_info "既にアーカイブ済み: $ARCHIVE_DIR/$PLAYBOOK_NAME"
        elif mv "$PLAYBOOK_DIR" "$ARCHIVE_DIR/" 2>/dev/null; then
            log_info "アーカイブ完了: $ARCHIVE_DIR/$PLAYBOOK_NAME"
        else
            log_error "アーカイブに失敗しました"
        fi
    else
        log_info "playbook ディレクトリが見つかりません（既にアーカイブ済みの可能性）"
    fi

    update_checkpoint_complete 5
fi

# ==============================================================================
# Step 6: アーカイブのコミット（playbook 移動のみ）
# ==============================================================================
if should_run_step 6; then
    echo ""
    echo "$SEP"
    echo "  Step 6: アーカイブのコミット"
    echo "$SEP"

    update_checkpoint_start 6

    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        git add -A
        git commit -m "chore: archive ${PLAYBOOK_NAME}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" || log_warn "アーカイブコミットに失敗しました"
        log_info "アーカイブコミット完了"
    else
        log_info "変更なし。スキップ。"
    fi

    update_checkpoint_complete 6
fi

# ==============================================================================
# Step 7: Push（アーカイブ分）
# ==============================================================================
if should_run_step 7; then
    echo ""
    echo "$SEP"
    echo "  Step 7: Push（アーカイブ分）"
    echo "$SEP"

    update_checkpoint_start 7

    if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
        git push 2>&1 || log_warn "アーカイブ push に失敗しました"
        log_info "アーカイブ Push 完了"
    fi

    update_checkpoint_complete 7
fi

# ==============================================================================
# Step 8: state.md 更新（playbook + goal セクション両方をリセット）
# ==============================================================================
if should_run_step 8; then
    echo ""
    echo "$SEP"
    echo "  Step 8: state.md 更新"
    echo "$SEP"

    update_checkpoint_start 8

    STATE_FILE="state.md"
    if [ -f "$STATE_FILE" ]; then
        # === playbook セクション ===
        sed -i '' 's/^active: .*/active: null/' "$STATE_FILE" 2>/dev/null || true
        sed -i '' 's/^parent_project: .*/parent_project: null/' "$STATE_FILE" 2>/dev/null || true
        sed -i '' 's/^current_phase: .*/current_phase: null/' "$STATE_FILE" 2>/dev/null || true
        sed -i '' 's/^branch: .*/branch: null/' "$STATE_FILE" 2>/dev/null || true
        sed -i '' "s|^last_archived: .*|last_archived: $ARCHIVE_DIR/$PLAYBOOK_NAME|" "$STATE_FILE" 2>/dev/null || true

        # === project 進捗更新（M090: playbook 完了を project.json に反映）===
        if [ -n "$PARENT_PROJECT" ] && [ "$PARENT_PROJECT" != "null" ]; then
            PROJECT_FILE="play/projects/$PARENT_PROJECT/project.json"
            if [ -f "$PROJECT_FILE" ]; then
                # project.json の該当 playbook を done に更新
                jq --arg pb_id "$PLAYBOOK_ID" '
                    .milestones |= map(
                        .playbooks |= map(
                            if .id == $pb_id then .status = "done" else . end
                        )
                    ) |
                    .progress.completed_playbooks += 1 |
                    .progress.current_playbook = null
                ' "$PROJECT_FILE" > "$PROJECT_FILE.tmp" && mv "$PROJECT_FILE.tmp" "$PROJECT_FILE"
                log_info "project.json 更新完了: $PROJECT_FILE"
            fi
        fi

        # === goal セクション（neutral 状態にリセット）===
        sed -i '' 's/^self_complete: .*/self_complete: false/' "$STATE_FILE" 2>/dev/null || true
        sed -i '' 's/^milestone: .*/milestone: null/' "$STATE_FILE" 2>/dev/null || true
        sed -i '' 's/^phase: .*/phase: null/' "$STATE_FILE" 2>/dev/null || true
        sed -i '' 's/^status: .*/status: idle/' "$STATE_FILE" 2>/dev/null || true
        # done_criteria を空配列にリセット（複数行対応）
        awk '
            /^done_criteria:/ { in_dc = 1; print "done_criteria: []"; next }
            in_dc && /^[a-z_]+:/ { in_dc = 0 }
            in_dc && /^  - / { next }
            { print }
        ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

        log_info "state.md 更新完了（playbook + goal セクション）"
    else
        log_warn "state.md が見つかりません"
    fi

    update_checkpoint_complete 8
fi

# ==============================================================================
# Step 9: state.md 更新のコミット
# ==============================================================================
if should_run_step 9; then
    echo ""
    echo "$SEP"
    echo "  Step 9: state.md 更新のコミット"
    echo "$SEP"

    update_checkpoint_start 9

    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        git add -A
        git commit -m "chore: reset state.md after archive ${PLAYBOOK_NAME}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" || log_warn "state.md コミットに失敗しました"
        log_info "state.md コミット完了"
    else
        log_info "変更なし。スキップ。"
    fi

    update_checkpoint_complete 9
fi

# ==============================================================================
# Step 10: Push（state.md 分）
# ==============================================================================
if should_run_step 10; then
    echo ""
    echo "$SEP"
    echo "  Step 10: Push（state.md 分）"
    echo "$SEP"

    update_checkpoint_start 10

    if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
        git push 2>&1 || log_warn "state.md push に失敗しました"
        log_info "state.md Push 完了"
    fi

    update_checkpoint_complete 10
fi

# ==============================================================================
# Step 11: PR マージ
# ==============================================================================
if should_run_step 11; then
    echo ""
    echo "$SEP"
    echo "  Step 11: PR マージ"
    echo "$SEP"

    update_checkpoint_start 11

    MERGE_PR_SCRIPT="$SKILLS_DIR/git-workflow/handlers/merge-pr.sh"
    if [ -x "$MERGE_PR_SCRIPT" ]; then
        bash "$MERGE_PR_SCRIPT" || log_warn "PR マージに失敗しました（手動で実行してください）"
    else
        log_warn "merge-pr.sh が見つかりません: $MERGE_PR_SCRIPT"
    fi

    update_checkpoint_complete 11
fi

# ==============================================================================
# Step 12: main 同期（強制的に main へ checkout）
# ==============================================================================
if should_run_step 12; then
    echo ""
    echo "$SEP"
    echo "  Step 12: main 同期"
    echo "$SEP"

    update_checkpoint_start 12

    git fetch origin main 2>/dev/null || true
    CURRENT_AFTER=$(git branch --show-current 2>/dev/null || echo "")

    # main でない場合は checkout する
    if [ "$CURRENT_AFTER" != "main" ] && [ "$CURRENT_AFTER" != "master" ]; then
        # 未コミット変更があるかチェック
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
            log_error "未コミット変更があります。main への checkout をブロックします。"
            log_error "変更をコミットしてから再度実行してください。"
            # ブロックせず警告のみ（アーカイブ処理は続行）
        else
            log_info "ブランチを main に切り替えます..."
            if git checkout main 2>/dev/null; then
                log_info "main へ checkout 完了"
            else
                log_warn "main への checkout に失敗しました"
            fi
        fi
    fi

    # main/master なら pull
    CURRENT_AFTER=$(git branch --show-current 2>/dev/null || echo "")
    if [ "$CURRENT_AFTER" = "main" ] || [ "$CURRENT_AFTER" = "master" ]; then
        git pull origin main 2>/dev/null || log_warn "main 同期に失敗しました"
        log_info "main 同期完了"
    else
        log_warn "main への切り替えに失敗しました。現在: $CURRENT_AFTER"
    fi

    update_checkpoint_complete 12
fi

# ==============================================================================
# Step 13: pending ファイル作成
# ==============================================================================
if should_run_step 13; then
    echo ""
    echo "$SEP"
    echo "  Step 13: pending ファイル作成"
    echo "$SEP"

    update_checkpoint_start 13

    mkdir -p "$SESSION_STATE_DIR"
    cat > "$PENDING_FILE" << PENDINGEOF
{
  "playbook": "$PLAYBOOK_NAME",
  "archived_at": "$(date -Iseconds)",
  "status": "$OVERALL_STATUS",
  "branch": "$CURRENT_BRANCH"
}
PENDINGEOF
    log_info "pending ファイル作成完了: $PENDING_FILE (status: $OVERALL_STATUS)"

    update_checkpoint_complete 13
fi

# ==============================================================================
# Step 14: Project 完了チェック（M090 連携）
# ==============================================================================
if should_run_step 14; then
    echo ""
    echo "$SEP"
    echo "  Step 14: Project 完了チェック"
    echo "$SEP"

    update_checkpoint_start 14

    if [ -n "$PARENT_PROJECT" ] && [ "$PARENT_PROJECT" != "null" ]; then
        PROJECT_FILE="play/projects/$PARENT_PROJECT/project.json"

        if [ -f "$PROJECT_FILE" ]; then
            # 残り playbook をチェック
            REMAINING=$(jq '[.milestones[].playbooks[] | select(.status != "done")] | length' "$PROJECT_FILE" 2>/dev/null || echo "-1")

            if [ "$REMAINING" = "0" ]; then
                log_info "全 playbook 完了。Project をアーカイブします..."
                ARCHIVE_PROJECT_SCRIPT="$SKILLS_DIR/playbook-gate/workflow/archive-project.sh"

                if [ -x "$ARCHIVE_PROJECT_SCRIPT" ]; then
                    bash "$ARCHIVE_PROJECT_SCRIPT" "$PARENT_PROJECT" || log_warn "Project アーカイブに失敗しました"
                else
                    log_warn "archive-project.sh が見つからないか実行権限がありません: $ARCHIVE_PROJECT_SCRIPT"
                fi
            elif [ "$REMAINING" = "-1" ]; then
                log_warn "project.json の解析に失敗しました"
            else
                log_info "残り playbook: $REMAINING 件（Project は継続）"
            fi
        else
            log_info "Project 配下ですが project.json が見つかりません: $PROJECT_FILE"
        fi
    else
        log_info "単発 playbook のため Project チェックをスキップ"
    fi

    update_checkpoint_complete 14
fi

# 正常完了時にチェックポイント削除
cleanup_checkpoint

# ==============================================================================
# 完了メッセージ（Claude への systemMessage として出力）
# ==============================================================================
# PostToolUse hook の出力は Claude に渡される
# JSON 形式で systemMessage を出力し、Claude に post-loop 呼び出しを指示

if [ "$OVERALL_STATUS" = "success" ]; then
    STATUS_MSG="自動処理完了（全ステップ成功）"
else
    STATUS_MSG="自動処理完了（一部警告あり）"
fi

cat << SYSTEMEOF
{
  "status": "$OVERALL_STATUS",
  "message": "$STATUS_MSG",
  "systemMessage": "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n  Playbook アーカイブ完了\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n  【必須アクション】\\n  今すぐ Skill(skill='post-loop') を呼び出すこと。\\n\\n  post-loop が実行する処理:\\n    1. pending ファイル削除\\n    2. 次タスクの導出\\n\\n  ユーザーに指示を求めずに自動実行すること\\n\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
SYSTEMEOF

exit 0
