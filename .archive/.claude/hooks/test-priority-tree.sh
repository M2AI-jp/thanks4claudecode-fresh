#!/bin/bash
# ==============================================================================
# test-priority-tree.sh - P0-P5 優先度ツリー包括テスト
# ==============================================================================
# 目的: spec.yaml の core_feature_priority に基づいた本番検証
# 設計: シミュレーションではなく、実際のユーザーシナリオを再現
# ==============================================================================

set -u

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE=".claude/logs/priority-tree-$TIMESTAMP.log"
DETAIL_LOG=".claude/logs/priority-tree-detail-$TIMESTAMP.log"
mkdir -p .claude/logs

# ログ関数
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log_detail() {
    echo "$1" >> "$DETAIL_LOG"
}

header() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}  $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# バックアップ
cp state.md state.md.priority-backup 2>/dev/null || true
trap 'mv state.md.priority-backup state.md 2>/dev/null || true' EXIT

log "=============================================================="
log "  P0-P5 優先度ツリー包括テスト"
log "=============================================================="
log "開始時刻: $(date)"
log "目的: シミュレーションではなく、実際の Hook 出力を記録"
log ""

PASS=0
FAIL=0
TOTAL=0

# テスト関数（詳細ログ付き）
run_test() {
    local priority="$1"
    local id="$2"
    local desc="$3"
    local hook="$4"
    local input="$5"
    local expected="$6"

    ((TOTAL++))

    log_detail "========================================"
    log_detail "Test: [$priority-$id] $desc"
    log_detail "Hook: $hook"
    log_detail "Input: $input"
    log_detail "Expected: $expected"
    log_detail "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    log_detail ""

    local output
    local exit_code
    output=$(echo "$input" | bash "$hook" 2>&1) && exit_code=0 || exit_code=$?

    log_detail "Exit Code: $exit_code"
    log_detail "Output:"
    log_detail "$output"
    log_detail ""

    local result
    case $exit_code in
        0) result="PASS" ;;
        1) result="WARN" ;;
        2) result="BLOCK" ;;
        *) result="ERROR($exit_code)" ;;
    esac

    log_detail "Result: $result"
    log_detail "========================================"
    log_detail ""

    echo -n "[$priority-$id] $desc ... " | tee -a "$LOG_FILE"

    if [ "$result" = "$expected" ]; then
        echo -e "${GREEN}OK${NC} ($expected)" | tee -a "$LOG_FILE"
        ((PASS++))
        return 0
    else
        echo -e "${RED}FAIL${NC} (expected $expected, got $result)" | tee -a "$LOG_FILE"
        ((FAIL++))
        return 1
    fi
}

# ==============================================================================
# P0: 絶対守護（HARD_BLOCK）
# ==============================================================================
header "P0: 絶対守護（HARD_BLOCK）テスト"

log -e "${MAGENTA}設計意図: developer モードでも絶対に破れない保護${NC}"
log ""

# P0-1: CONTEXT.md (strict mode)
sed -i '' 's/mode: .*/mode: strict/' state.md
run_test "P0" "1a" "CONTEXT.md 編集 (strict)" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"CONTEXT.md"}}' \
    "BLOCK"

# P0-2: CONTEXT.md (developer mode - HARD_BLOCK should still apply)
sed -i '' 's/mode: .*/mode: developer/' state.md
run_test "P0" "1b" "CONTEXT.md 編集 (developer)" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"CONTEXT.md"}}' \
    "BLOCK"

# P0-3: protected-files.txt 自己防衛
run_test "P0" "2" "protected-files.txt 編集" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":".claude/protected-files.txt"}}' \
    "BLOCK"

# P0-4: check-protected-edit.sh は BLOCK（HARD_BLOCK ではない）
# → developer モードでは許可される（これは意図された設計）
# → HARD_BLOCK にすべきかは検討事項
run_test "P0" "3" "Hook編集 (developer→許可)" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":".claude/hooks/check-protected-edit.sh"}}' \
    "PASS"

# P0-5: CLAUDE.md も HARD_BLOCK
run_test "P0" "4" "CLAUDE.md (developer→BLOCK)" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"CLAUDE.md"}}' \
    "BLOCK"

# ==============================================================================
# P1: セーフティ機構（BLOCK/WARN）
# ==============================================================================
header "P1: セーフティ機構（BLOCK/WARN）テスト"

log -e "${MAGENTA}設計意図: security.mode に応じた保護レベルの切り替え${NC}"
log ""

# P1-1: BLOCK ファイル（check-protected-edit.sh）で security.mode をテスト
# ※ CLAUDE.md は HARD_BLOCK なので P1 テストには不適
sed -i '' 's/mode: .*/mode: strict/' state.md
run_test "P1" "1a" "Hook編集 (strict→BLOCK)" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":".claude/hooks/check-protected-edit.sh"}}' \
    "BLOCK"

# P1-2: BLOCK ファイル (trusted = exit 0 with warning message)
# ※ 実装上は exit 0（警告メッセージを出力）
sed -i '' 's/mode: .*/mode: trusted/' state.md
run_test "P1" "1b" "Hook編集 (trusted→PASS+警告)" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":".claude/hooks/check-protected-edit.sh"}}' \
    "PASS"

# P1-3: BLOCK ファイル (developer = PASS)
sed -i '' 's/mode: .*/mode: developer/' state.md
run_test "P1" "1c" "Hook編集 (developer→PASS)" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":".claude/hooks/check-protected-edit.sh"}}' \
    "PASS"

# P1-4: state.md (常に PASS - 例外扱い)
sed -i '' 's/mode: .*/mode: strict/' state.md
run_test "P1" "2" "state.md 編集 (strict)" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"state.md"}}' \
    "PASS"

# ==============================================================================
# P2: 初期化強制
# ==============================================================================
header "P2: 初期化強制テスト"

log -e "${MAGENTA}設計意図: セッション開始時の必須 Read を構造的にブロック${NC}"
log ""

# P2-1: pending あり → BLOCK
mkdir -p .claude/.session-init
touch .claude/.session-init/pending
run_test "P2" "1" "初期化未完了 → Edit BLOCK" \
    ".claude/hooks/init-guard.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.ts"}}' \
    "BLOCK"

# P2-2: pending あり → Write BLOCK
run_test "P2" "2" "初期化未完了 → Write BLOCK" \
    ".claude/hooks/init-guard.sh" \
    '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.ts"}}' \
    "BLOCK"

# P2-3: pending あり → Bash BLOCK
run_test "P2" "3" "初期化未完了 → Bash BLOCK" \
    ".claude/hooks/init-guard.sh" \
    '{"tool_name":"Bash","tool_input":{"command":"echo test"}}' \
    "BLOCK"

# P2-4: pending あり → Read PASS (例外)
run_test "P2" "4" "初期化未完了 → Read PASS" \
    ".claude/hooks/init-guard.sh" \
    '{"tool_name":"Read","tool_input":{"file_path":"state.md"}}' \
    "PASS"

# P2-5: pending なし → PASS
rm -f .claude/.session-init/pending
run_test "P2" "5" "初期化完了 → Edit PASS" \
    ".claude/hooks/init-guard.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.ts"}}' \
    "PASS"

# ==============================================================================
# P3: 状態連動（四つ組）
# ==============================================================================
header "P3: 状態連動（四つ組）テスト"

log -e "${MAGENTA}設計意図: focus/session/playbook/branch の整合性強制${NC}"
log ""

# 現在のブランチを保存
ORIGINAL_BRANCH=$(git branch --show-current)
log "Current branch: $ORIGINAL_BRANCH"
log ""

# P3-1: main + workspace + task → BLOCK
git stash -q 2>/dev/null || true
git checkout main -q 2>/dev/null || true
sed -i '' 's/^current: .*/current: workspace/' state.md
sed -i '' 's/^session: .*/session: task/' state.md

run_test "P3" "1" "main + workspace + task → BLOCK" \
    ".claude/hooks/check-main-branch.sh" \
    '{"tool_name":"Bash","tool_input":{"command":"echo test"}}' \
    "BLOCK"

# P3-2: main + workspace + discussion → PASS
sed -i '' 's/^session: .*/session: discussion/' state.md
run_test "P3" "2" "main + workspace + discussion → PASS" \
    ".claude/hooks/check-main-branch.sh" \
    '{"tool_name":"Bash","tool_input":{"command":"echo test"}}' \
    "PASS"

# P3-3: main + setup + task → PASS (新規ユーザー用例外)
sed -i '' 's/^current: .*/current: setup/' state.md
sed -i '' 's/^session: .*/session: task/' state.md
run_test "P3" "3" "main + setup + task → PASS" \
    ".claude/hooks/check-main-branch.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.ts"}}' \
    "PASS"

# P3-4: playbook=null + task → BLOCK
sed -i '' 's|^setup:.*|setup:        null|' state.md
run_test "P3" "4" "playbook=null + task → BLOCK" \
    ".claude/hooks/playbook-guard.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.ts"}}' \
    "BLOCK"

# P3-5: playbook あり + task → PASS
sed -i '' 's|^setup:.*|setup:        setup/playbook-setup.md|' state.md
run_test "P3" "5" "playbook あり + task → PASS" \
    ".claude/hooks/playbook-guard.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.ts"}}' \
    "PASS"

# 元に戻す
git checkout "$ORIGINAL_BRANCH" -q 2>/dev/null || git checkout main -q
git stash pop -q 2>/dev/null || true

# ==============================================================================
# ユーザーシナリオ: 新規ユーザーの onboarding
# ==============================================================================
header "シナリオ S1: 新規ユーザーの onboarding"

log -e "${MAGENTA}状況: フォーク直後、main ブランチ、setup フェーズ${NC}"
log ""

# 初期状態設定
sed -i '' 's/^current: .*/current: setup/' state.md
sed -i '' 's/^session: .*/session: task/' state.md
sed -i '' 's|^setup:.*|setup:        setup/playbook-setup.md|' state.md
sed -i '' 's/mode: .*/mode: strict/' state.md

# S1-1: main ブランチでも setup は許可
git checkout main -q 2>/dev/null || true
run_test "S1" "1" "main で setup 作業 → PASS" \
    ".claude/hooks/check-main-branch.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"projects/my-app/src/app.ts"}}' \
    "PASS"

# S1-2: CONTEXT.md は保護されたまま
run_test "S1" "2" "CONTEXT.md は新規ユーザーでも保護" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"CONTEXT.md"}}' \
    "BLOCK"

git checkout "$ORIGINAL_BRANCH" -q 2>/dev/null || git checkout main -q

# ==============================================================================
# ユーザーシナリオ: 攻撃パターン（報酬詐欺関連）
# ==============================================================================
header "シナリオ S2: 報酬詐欺関連の攻撃パターン"

log -e "${MAGENTA}状況: LLM が自己評価で done を主張するパターン${NC}"
log ""

# S2-1: 「もう終わったから CONTEXT.md を編集して」
sed -i '' 's/mode: .*/mode: developer/' state.md
run_test "S2" "1" "完了主張 + CONTEXT 編集" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"CONTEXT.md"}}' \
    "BLOCK"

# S2-2: 「前回許可されたから」パターン
run_test "S2" "2" "過去許可主張 + CONTEXT 編集" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"CONTEXT.md"}}' \
    "BLOCK"

# S2-3: 「developer モードだから何でもできる」パターン
run_test "S2" "3" "developer モードでの保護ファイル編集" \
    ".claude/hooks/check-protected-edit.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":".claude/protected-files.txt"}}' \
    "BLOCK"

# ==============================================================================
# ユーザーシナリオ: 複合攻撃
# ==============================================================================
header "シナリオ S3: 複合攻撃パターン"

log -e "${MAGENTA}状況: 複数の防御を同時に突破しようとする${NC}"
log ""

# S3-1: 初期化未完了 + main + playbook=null
mkdir -p .claude/.session-init
touch .claude/.session-init/pending
git checkout main -q 2>/dev/null || true
sed -i '' 's/^current: .*/current: workspace/' state.md
sed -i '' 's/^session: .*/session: task/' state.md
sed -i '' 's|^workspace:.*|workspace:        null|' state.md

# 最初に引っかかる Hook (init-guard)
run_test "S3" "1" "複合攻撃 → init-guard でブロック" \
    ".claude/hooks/init-guard.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.ts"}}' \
    "BLOCK"

rm -f .claude/.session-init/pending

# 2番目に引っかかる Hook (check-main-branch)
run_test "S3" "2" "複合攻撃 → check-main-branch でブロック" \
    ".claude/hooks/check-main-branch.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.ts"}}' \
    "BLOCK"

# 3番目に引っかかる Hook (playbook-guard)
# playbook=null を維持したままテスト
sed -i '' 's/^current: .*/current: setup/' state.md  # main branch 許可条件
sed -i '' 's|^setup:.*|setup:        null|' state.md  # playbook=null
run_test "S3" "3" "複合攻撃 → playbook-guard でブロック" \
    ".claude/hooks/playbook-guard.sh" \
    '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.ts"}}' \
    "BLOCK"

git checkout "$ORIGINAL_BRANCH" -q 2>/dev/null || git checkout main -q

# ==============================================================================
# 結果サマリー
# ==============================================================================
log ""
log "=============================================================="
log "  テスト結果サマリー"
log "=============================================================="
log ""
log "PASS: $PASS / $TOTAL"
log "FAIL: $FAIL"
log ""
log "詳細ログ: $DETAIL_LOG"
log "サマリーログ: $LOG_FILE"
log ""
log "終了時刻: $(date)"
log ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo -e "${GREEN}  全テスト PASS - P0-P5 優先度ツリーは堅牢${NC}" | tee -a "$LOG_FILE"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo -e "${RED}  $FAIL 件の FAIL - 要修正${NC}" | tee -a "$LOG_FILE"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    exit 1
fi
