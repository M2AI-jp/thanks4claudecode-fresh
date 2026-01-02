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
# 処理順序:
#   1. 自動コミット（未コミット変更がある場合）
#   2. push（PR 作成前に必要）
#   3. PR 作成（create-pr.sh - playbook.active が必要）
#   4. playbook アーカイブ（plan/archive/ へ移動）
#   5. state.md 更新（playbook.active = null）
#   6. アーカイブのコミット
#   7. push（追加コミット）
#   8. PR マージ（merge-pr.sh）
#   9. main 同期
#   10. pending ファイル作成
#
# 参照: docs/archive-operation-rules.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
SESSION_STATE_DIR=".claude/session-state"
PENDING_FILE="$SESSION_STATE_DIR/post-loop-pending"
BG_TASKS_FILE="$SESSION_STATE_DIR/background-tasks.json"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ステータス追跡
OVERALL_STATUS="success"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; OVERALL_STATUS="partial"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; OVERALL_STATUS="partial"; }

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

# state.md が存在しない場合はスキップ
if [ ! -f "state.md" ]; then
    exit 0
fi

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# 編集対象ファイルを取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# playbook ファイル以外は無視
if [[ "$FILE_PATH" != *playbook*.md ]]; then
    exit 0
fi

# playbook ファイルが存在しない場合はスキップ
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# playbook 内の Phase status を確認
# 全ての status: が done であるかチェック
# M085 修正: Markdown bold 形式（**status**: done）に対応
TOTAL_PHASES=$(grep -c '^\*\*status\*\*:' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
DONE_PHASES=$(grep -c '^\*\*status\*\*: done' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
# 空の場合は 0 に設定
TOTAL_PHASES=${TOTAL_PHASES:-0}
DONE_PHASES=${DONE_PHASES:-0}

# Phase がない場合はスキップ
if [ "$TOTAL_PHASES" -eq 0 ]; then
    exit 0
fi

# 全 Phase が done でない場合はスキップ
if [ "$DONE_PHASES" -ne "$TOTAL_PHASES" ]; then
    exit 0
fi

# ==============================================================================
# V12: チェックボックス形式の完了判定（報酬詐欺防止強化）
# ==============================================================================
CHECKED_COUNT=$(grep -c '\- \[x\]' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
UNCHECKED_COUNT=$(grep -c '\- \[ \]' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
CHECKED_COUNT=${CHECKED_COUNT:-0}
UNCHECKED_COUNT=${UNCHECKED_COUNT:-0}
TOTAL_CHECKBOX=$((CHECKED_COUNT + UNCHECKED_COUNT))

if [ "$TOTAL_CHECKBOX" -gt 0 ]; then
    if [ "$UNCHECKED_COUNT" -gt 0 ]; then
        echo "" >&2
        echo "$SEP" >&2
        echo "  ⛔ BLOCKED: 未完了の subtask があります" >&2
        echo "$SEP" >&2
        echo "  完了: $CHECKED_COUNT / 未完了: $UNCHECKED_COUNT" >&2
        echo "" >&2
        # Phase 単位で未完了 subtask を表示
        echo "  【未完了 subtask 一覧（Phase 別）】" >&2
        current_phase=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^###\ (p[0-9_a-z]+): ]]; then
                current_phase="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^\-\ \[\ \]\ \*\*([^*]+)\*\* ]]; then
                subtask_id="${BASH_REMATCH[1]}"
                echo "    - ${current_phase}: ${subtask_id}" >&2
            fi
        done < "$FILE_PATH"
        echo "" >&2
        echo "  【必要な対応】" >&2
        echo "    1. 各 subtask の作業を完了する" >&2
        echo "    2. Skill(skill='crit') または /crit で検証" >&2
        echo "    3. チェックボックスを [x] に変更" >&2
        echo "    4. validations と validated を記入" >&2
        echo "" >&2
        echo "  アーカイブは全 subtask 完了後に自動実行されます。" >&2
        echo "$SEP" >&2
        exit 2  # 未完了があればブロック
    fi
fi

# M019: final_tasks チェック
if grep -q "^## final_tasks" "$FILE_PATH" 2>/dev/null; then
    TOTAL_FINAL_TASKS=$(grep -A 100 "^## final_tasks" "$FILE_PATH" | grep -c '\- \[.\] \*\*ft' 2>/dev/null || echo "0")
    DONE_FINAL_TASKS=$(grep -A 100 "^## final_tasks" "$FILE_PATH" | grep -c '\- \[x\] \*\*ft' 2>/dev/null || echo "0")

    if [ "$TOTAL_FINAL_TASKS" -eq 0 ]; then
        TOTAL_FINAL_TASKS=$(awk '/^final_tasks:/,/^[a-z_]+:/' "$FILE_PATH" | grep -c "^ *- " 2>/dev/null || echo "0")
        DONE_FINAL_TASKS=$(awk '/^final_tasks:/,/^[a-z_]+:/' "$FILE_PATH" | grep -c "status: done" 2>/dev/null || echo "0")
    fi

    if [ "$TOTAL_FINAL_TASKS" -gt 0 ] && [ "$DONE_FINAL_TASKS" -lt "$TOTAL_FINAL_TASKS" ]; then
        echo ""
        echo "$SEP"
        echo "  ⚠️ final_tasks が未完了です"
        echo "$SEP"
        echo "  完了: $DONE_FINAL_TASKS / $TOTAL_FINAL_TASKS"
        echo "  → final_tasks を全て完了してからアーカイブしてください"
        echo "$SEP"
        exit 0
    fi
fi

# M056: done_when 再検証（報酬詐欺防止）
DONE_WHEN_SECTION=$(sed -n '/^done_when:/,/^[a-z_]*:/p' "$FILE_PATH" 2>/dev/null | grep "^  - " | head -10)
DONE_WHEN_COUNT=$(echo "$DONE_WHEN_SECTION" | grep -c "^  - " 2>/dev/null) || DONE_WHEN_COUNT=0

if [ "$DONE_WHEN_COUNT" -gt 0 ]; then
    # p_final Phase の status チェック
    P_FINAL_STATUS=$(grep -A 30 "p_final" "$FILE_PATH" 2>/dev/null | grep "^\*\*status\*\*:" | head -1 | sed 's/\*\*status\*\*: *//')
    if [ -n "$P_FINAL_STATUS" ] && [ "$P_FINAL_STATUS" != "done" ]; then
        echo ""
        echo "$SEP"
        echo "  ❌ p_final（完了検証）が未完了です"
        echo "$SEP"
        echo "  done_when の検証: status = $P_FINAL_STATUS"
        echo "  p_final を完了させてからアーカイブしてください。"
        echo "$SEP"
        exit 2  # done_when 未検証でブロック
    fi

    # p_final の subtask 完了チェック
    P_FINAL_SECTION=$(grep -A 100 "p_final" "$FILE_PATH" 2>/dev/null | head -100)
    INCOMPLETE_SUBTASKS=$(echo "$P_FINAL_SECTION" | grep -c '\- \[ \]' 2>/dev/null) || INCOMPLETE_SUBTASKS=0

    if [ "$INCOMPLETE_SUBTASKS" -gt 0 ]; then
        echo ""
        echo "$SEP"
        echo "  ❌ p_final の subtasks が未完了です"
        echo "$SEP"
        echo "  アーカイブをブロックします。"
        echo "$SEP"
        exit 2
    fi
fi

# ==============================================================================
# ここから自動処理開始
# ==============================================================================

PLAYBOOK_NAME=$(basename "$FILE_PATH")
ARCHIVE_DIR="plan/archive"
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

echo ""
echo "$SEP"
echo "  📦 Playbook 完了検出 → 自動処理開始"
echo "$SEP"
echo ""
echo "  Playbook: $FILE_PATH"
echo "  Status: 全 $TOTAL_PHASES Phase が done"
echo "  Branch: $CURRENT_BRANCH"
echo ""

# ==============================================================================
# Step 1: 自動コミット
# ==============================================================================
echo "$SEP"
echo "  Step 1: 自動コミット"
echo "$SEP"

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    log_info "未コミット変更を検出。コミットします..."
    git add -A
    git commit -m "feat(${PLAYBOOK_NAME%.md}): playbook 完了

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" || log_warn "コミットに失敗しました"
    log_info "コミット完了"
else
    log_info "未コミット変更なし。スキップ。"
fi

# ==============================================================================
# Step 2: Push（PR 作成前に必要）
# ==============================================================================
echo ""
echo "$SEP"
echo "  Step 2: Push"
echo "$SEP"

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

# ==============================================================================
# Step 3: PR 作成
# ==============================================================================
echo ""
echo "$SEP"
echo "  Step 3: PR 作成"
echo "$SEP"

CREATE_PR_SCRIPT="$SKILLS_DIR/git-workflow/handlers/create-pr.sh"
if [ -x "$CREATE_PR_SCRIPT" ]; then
    bash "$CREATE_PR_SCRIPT" || log_warn "PR 作成に失敗しました（既存の可能性あり）"
else
    log_warn "create-pr.sh が見つかりません: $CREATE_PR_SCRIPT"
fi

# ==============================================================================
# Step 3.5: バックグラウンドタスク クリーンアップ（M088）
# ==============================================================================
echo ""
echo "$SEP"
echo "  Step 3.5: バックグラウンドタスク クリーンアップ"
echo "$SEP"

# playbook 完了時は全 phase のタスクをクリーンアップ
cleanup_background_tasks_for_phase "all"

# ==============================================================================
# Step 4: Playbook アーカイブ
# ==============================================================================
echo ""
echo "$SEP"
echo "  Step 4: Playbook アーカイブ"
echo "$SEP"

mkdir -p "$ARCHIVE_DIR"
if mv "$FILE_PATH" "$ARCHIVE_DIR/" 2>/dev/null; then
    log_info "アーカイブ完了: $ARCHIVE_DIR/$PLAYBOOK_NAME"
else
    log_error "アーカイブに失敗しました"
fi

# ==============================================================================
# Step 5: state.md 更新
# ==============================================================================
echo ""
echo "$SEP"
echo "  Step 5: state.md 更新"
echo "$SEP"

STATE_FILE="state.md"
if [ -f "$STATE_FILE" ]; then
    # playbook.active を null に
    sed -i '' 's/^active: .*/active: null/' "$STATE_FILE" 2>/dev/null || true
    # playbook.branch を null に
    sed -i '' 's/^branch: .*/branch: null/' "$STATE_FILE" 2>/dev/null || true
    # last_archived を更新
    sed -i '' "s|^last_archived: .*|last_archived: $ARCHIVE_DIR/$PLAYBOOK_NAME|" "$STATE_FILE" 2>/dev/null || true
    log_info "state.md 更新完了"
else
    log_warn "state.md が見つかりません"
fi

# ==============================================================================
# Step 6: アーカイブのコミット
# ==============================================================================
echo ""
echo "$SEP"
echo "  Step 6: アーカイブのコミット"
echo "$SEP"

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    git add -A
    git commit -m "chore: archive ${PLAYBOOK_NAME%.md}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" || log_warn "アーカイブコミットに失敗しました"
    log_info "アーカイブコミット完了"
else
    log_info "変更なし。スキップ。"
fi

# ==============================================================================
# Step 7: Push（追加コミット）
# ==============================================================================
echo ""
echo "$SEP"
echo "  Step 7: Push（追加コミット）"
echo "$SEP"

if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    git push 2>&1 || log_warn "追加 push に失敗しました"
    log_info "追加 Push 完了"
fi

# ==============================================================================
# Step 8: PR マージ
# ==============================================================================
echo ""
echo "$SEP"
echo "  Step 8: PR マージ"
echo "$SEP"

MERGE_PR_SCRIPT="$SKILLS_DIR/git-workflow/handlers/merge-pr.sh"
if [ -x "$MERGE_PR_SCRIPT" ]; then
    bash "$MERGE_PR_SCRIPT" || log_warn "PR マージに失敗しました（手動で実行してください）"
else
    log_warn "merge-pr.sh が見つかりません: $MERGE_PR_SCRIPT"
fi

# ==============================================================================
# Step 9: main 同期
# ==============================================================================
echo ""
echo "$SEP"
echo "  Step 9: main 同期"
echo "$SEP"

git fetch origin main 2>/dev/null || true
CURRENT_AFTER=$(git branch --show-current 2>/dev/null || echo "")
if [ "$CURRENT_AFTER" = "main" ] || [ "$CURRENT_AFTER" = "master" ]; then
    git pull origin main 2>/dev/null || log_warn "main 同期に失敗しました"
    log_info "main 同期完了"
else
    log_info "現在 $CURRENT_AFTER ブランチ。main 同期はマージ完了後に実行されます。"
fi

# ==============================================================================
# Step 10: pending ファイル作成
# ==============================================================================
echo ""
echo "$SEP"
echo "  Step 10: pending ファイル作成"
echo "$SEP"

mkdir -p "$SESSION_STATE_DIR"
cat > "$PENDING_FILE" << EOF
{
  "playbook": "$PLAYBOOK_NAME",
  "archived_at": "$(date -Iseconds)",
  "status": "$OVERALL_STATUS",
  "branch": "$CURRENT_BRANCH"
}
EOF
log_info "pending ファイル作成完了: $PENDING_FILE (status: $OVERALL_STATUS)"

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

cat << EOF
{
  "status": "$OVERALL_STATUS",
  "message": "$STATUS_MSG",
  "systemMessage": "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n  ✅ Playbook アーカイブ完了\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\\n\\n  【必須アクション】\\n  今すぐ Skill(skill='post-loop') を呼び出すこと。\\n\\n  post-loop が実行する処理:\\n    1. pending ファイル削除\\n    2. 次タスクの導出\\n\\n  ⚠️ ユーザーに指示を求めずに自動実行すること\\n\\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
EOF

exit 0
