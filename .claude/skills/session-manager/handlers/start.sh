#!/bin/bash
# start.sh - LLMの自己認識を形成し、LOOPを開始させる
# Note: 旧 .claude/hooks/session-start.sh の機能を統合（cleanup_stale_pending 含む）
#
# 設計方針（8.5 Hooks 設計ガイドライン準拠）:
#   - 軽量な出力のみ（1KB 目標）
#   - state.md, playbook は LLM に Read させる
#   - OOM 防止のため全文出力は禁止
#
# 自動更新機能:
#   - state.md の session_tracking.last_start を自動更新
#   - LLM の行動に依存しない
#
# トリガー対応:
#   - startup: 通常のセッション開始
#   - resume: セッション再開
#   - clear: /clear 後の再初期化
#   - compact: auto-compact 後の復元

set -e

# ==============================================================================
# Cleanup stale pending file from previous session (prevents deadlock)
# See: fix/post-loop-pending-deadlock, fix/pb27-cleanup-stale-pending-refix
# Reason: pending's lifetime is session-scoped, not cross-session
# MUST be called before any other operations to prevent deadlock
# ==============================================================================
cleanup_stale_pending() {
    local pending_file=".claude/session-state/post-loop-pending"

    if [ -f "$pending_file" ]; then
        echo "[SessionStart] Cleaning up stale post-loop-pending file"
        echo "  (Previous session did not complete post-loop)"
        rm -f "$pending_file"
        echo "  Removed: $pending_file"
        echo ""
    fi
}

# First: cleanup stale pending to prevent deadlock
cleanup_stale_pending

# ==============================================================================
# state-schema.sh を source して state.md のスキーマを参照
# ==============================================================================
source .claude/schema/state-schema.sh

# ==============================================================================
# repository-map.yaml 差分チェック関数
# 実ファイル数と repository-map.yaml の count を比較し、乖離を検出
# ==============================================================================
check_repository_map_drift() {
    local REPO_MAP="docs/repository-map.yaml"

    # repository-map.yaml が存在しない場合はスキップ
    [ ! -f "$REPO_MAP" ] && return 0

    # 実際のファイル数をカウント
    local ACTUAL_HOOKS=$(find .claude/hooks -maxdepth 1 -name "*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')
    local ACTUAL_AGENTS=$(find .claude/skills/*/agents -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    local ACTUAL_SKILLS=$(find .claude/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    local ACTUAL_COMMANDS=$(find .claude/commands -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

    # repository-map.yaml の count を取得（各セクションの構造に応じて適切な行数を検索）
    local EXPECTED_HOOKS=$(grep -A3 "^hooks:" "$REPO_MAP" | grep "count:" | head -1 | sed 's/.*: *//')
    local EXPECTED_AGENTS=$(grep -A3 "^agents:" "$REPO_MAP" | grep "count:" | head -1 | sed 's/.*: *//')
    local EXPECTED_SKILLS=$(grep -A6 "^skills:" "$REPO_MAP" | grep "count:" | head -1 | sed 's/.*: *//')
    local EXPECTED_COMMANDS=$(grep -A5 "^commands:" "$REPO_MAP" | grep "count:" | head -1 | sed 's/.*: *//')

    # 乖離チェック
    local DRIFT=false
    local DRIFT_DETAILS=""

    if [ "$ACTUAL_HOOKS" != "$EXPECTED_HOOKS" ]; then
        DRIFT=true
        DRIFT_DETAILS="hooks: $EXPECTED_HOOKS → $ACTUAL_HOOKS"
    fi
    if [ "$ACTUAL_AGENTS" != "$EXPECTED_AGENTS" ]; then
        DRIFT=true
        [ -n "$DRIFT_DETAILS" ] && DRIFT_DETAILS="$DRIFT_DETAILS, "
        DRIFT_DETAILS="${DRIFT_DETAILS}agents: $EXPECTED_AGENTS → $ACTUAL_AGENTS"
    fi
    if [ "$ACTUAL_SKILLS" != "$EXPECTED_SKILLS" ]; then
        DRIFT=true
        [ -n "$DRIFT_DETAILS" ] && DRIFT_DETAILS="$DRIFT_DETAILS, "
        DRIFT_DETAILS="${DRIFT_DETAILS}skills: $EXPECTED_SKILLS → $ACTUAL_SKILLS"
    fi
    if [ "$ACTUAL_COMMANDS" != "$EXPECTED_COMMANDS" ]; then
        DRIFT=true
        [ -n "$DRIFT_DETAILS" ] && DRIFT_DETAILS="$DRIFT_DETAILS, "
        DRIFT_DETAILS="${DRIFT_DETAILS}commands: $EXPECTED_COMMANDS → $ACTUAL_COMMANDS"
    fi

    if [ "$DRIFT" = true ]; then
        echo ""
        echo "[DRIFT] repository-map.yaml に乖離あり"
        echo "  詳細: $DRIFT_DETAILS"
        echo "  対応: bash .claude/hooks/generate-repository-map.sh を実行してください"
        echo ""
    fi
}

# ==============================================================================
# ARCHITECTURE.md 同期チェック関数
# architecture-sync.yaml が存在する場合、ARCHITECTURE_SYNC_REQUIRED メッセージを出力
# ==============================================================================
check_architecture_sync() {
    local SYNC_FILE=".claude/.session-init/architecture-sync.yaml"

    # architecture-sync.yaml が存在しない場合はスキップ
    [ ! -f "$SYNC_FILE" ] && return 0

    # YAML パースを試行（破損している場合はスキップ）
    if ! grep -q "drift_detected: true" "$SYNC_FILE" 2>/dev/null; then
        return 0
    fi

    # 変更内容を抽出（affected_sections の前まで）
    local CHANGES=$(sed -n '/^changes:/,/^affected_sections:/p' "$SYNC_FILE" | grep "^  - " | sed 's/^  - "//' | sed 's/"$//' | head -10)

    # 影響セクションを抽出
    local SECTIONS=$(grep -A100 "^affected_sections:" "$SYNC_FILE" | grep "^  - " | sed 's/^  - "//' | sed 's/"$//' | head -20)

    # ARCHITECTURE_SYNC_REQUIRED メッセージを出力
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ⚠️ ARCHITECTURE_SYNC_REQUIRED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  repository-map.yaml が変更されました。"
    echo "  docs/ARCHITECTURE.md の更新が必要です。"
    echo ""
    echo "  【変更内容】"
    while IFS= read -r change; do
        [ -z "$change" ] && continue
        echo "    - $change"
    done <<< "$CHANGES"
    echo ""
    echo "  【影響セクション】"
    while IFS= read -r section; do
        [ -z "$section" ] && continue
        echo "    - $section"
    done <<< "$SECTIONS"
    echo ""
    echo "  → docs/ARCHITECTURE.md を更新してください"
    echo ""
}

# ==============================================================================
# verify_hooks - settings.json の Hook 存在・実行権限を検証・自動修復
# settings.json に登録された全 Hook の存在・実行権限をチェックし、
# 実行権限がない場合は自動修復（chmod +x）を行う
# ==============================================================================
verify_hooks() {
    local SETTINGS_FILE=".claude/settings.json"
    local ISSUES_FOUND=false
    local FIXED_COUNT=0
    local WARN_COUNT=0

    # settings.json が存在しない場合はスキップ
    if [ ! -f "$SETTINGS_FILE" ]; then
        return 0
    fi

    # jq がインストールされているか確認
    if ! command -v jq &> /dev/null; then
        echo "[WARN] jq がインストールされていません。Hook 検証をスキップします。"
        return 0
    fi

    # settings.json から全 Hook のコマンドを抽出
    # 構造: .hooks.{EventType}[].hooks[].command
    local HOOK_COMMANDS=$(jq -r '
        .hooks // {} |
        to_entries[] |
        .value[]? |
        .hooks[]? |
        .command // empty
    ' "$SETTINGS_FILE" 2>/dev/null)

    # Hook コマンドがない場合はスキップ
    [ -z "$HOOK_COMMANDS" ] && return 0

    # 各 Hook コマンドを検証
    while IFS= read -r CMD; do
        [ -z "$CMD" ] && continue

        # "bash path/to/script.sh" 形式からパスを抽出
        local HOOK_PATH=$(echo "$CMD" | sed -n 's/^bash \([^ ]*\).*/\1/p')
        [ -z "$HOOK_PATH" ] && continue

        # ファイル存在チェック
        if [ ! -f "$HOOK_PATH" ]; then
            ISSUES_FOUND=true
            WARN_COUNT=$((WARN_COUNT + 1))
            echo "[WARN] Hook ファイルが存在しません: $HOOK_PATH"
            echo "  → settings.json から削除するか、ファイルを作成してください"
            continue
        fi

        # 実行権限チェック
        if [ ! -x "$HOOK_PATH" ]; then
            ISSUES_FOUND=true
            # 自動修復を試行
            if chmod +x "$HOOK_PATH" 2>/dev/null; then
                FIXED_COUNT=$((FIXED_COUNT + 1))
                echo "[AUTO-FIX] 実行権限を付与しました: $HOOK_PATH"
            else
                WARN_COUNT=$((WARN_COUNT + 1))
                echo "[WARN] 実行権限を付与できません: $HOOK_PATH"
                echo "  → chmod +x $HOOK_PATH を手動で実行してください"
            fi
        fi
    done <<< "$HOOK_COMMANDS"

    # サマリー出力（問題があった場合のみ）
    if [ "$ISSUES_FOUND" = true ]; then
        echo ""
        if [ $FIXED_COUNT -gt 0 ] || [ $WARN_COUNT -gt 0 ]; then
            echo "[Hook 検証] 完了: 自動修復 $FIXED_COUNT 件, 要対応 $WARN_COUNT 件"
        fi
    fi
}

# === stdin から JSON を読み込み、trigger を検出 ===
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "startup"' 2>/dev/null || echo "startup")

# === state.md の session_tracking を自動更新 ===
if [ -f "state.md" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # last_start を更新（sed -i はmacOSでは -i '' が必要）
    if grep -q "last_start:" state.md; then
        sed -i '' "s/last_start: .*/last_start: $TIMESTAMP/" state.md 2>/dev/null || \
        sed -i "s/last_start: .*/last_start: $TIMESTAMP/" state.md 2>/dev/null || true
    fi

    # 前回 last_end が null でないか確認（正常終了判定）
    LAST_END=$(grep "last_end:" state.md | head -1 | sed 's/.*last_end: *//' | sed 's/ *#.*//')
    if [ "$LAST_END" = "null" ] || [ -z "$LAST_END" ]; then
        # 前回のセッションが正常終了していない可能性
        PREV_START=$(grep "last_start:" state.md | head -1 | sed 's/.*last_start: *//' | sed 's/ *#.*//')
        if [ "$PREV_START" != "null" ] && [ -n "$PREV_START" ]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  ⚠️ 前回のセッションが正常終了していません"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  last_start: $PREV_START"
            echo "  last_end: (未設定)"
            echo ""
            echo "  → 前回の作業状態を確認してください"
            echo ""
        fi
    fi
fi

# === 共通変数 ===
SEP="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
WS="$(pwd)"

# === 初期化ペンディングフラグの設定 ===
# init-guard.sh が必須ファイル Read 完了まで他ツールをブロックするために使用
INIT_DIR=".claude/.session-init"
mkdir -p "$INIT_DIR"
# user-intent.md は保持（compact 後の復元に必要）、セッション管理ファイルのみリセット
rm -f "$INIT_DIR/pending" "$INIT_DIR/required_playbook" 2>/dev/null || true
touch "$INIT_DIR/pending"

# === state.md から情報抽出 ===
[ ! -f "state.md" ] && echo "[WARN] state.md not found" && exit 0

# playbook 情報は state.md から直接取得
PHASE=$(grep -A5 "## goal" state.md | grep "phase:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//')
CRITERIA=$(awk '/## goal/,/^## [^g]/' state.md | grep -A20 "done_criteria:" | grep "^  -" | head -6)
BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# playbook 取得（## playbook セクションから active を読み取り）
PLAYBOOK=$(awk '/## playbook/,/^---/' state.md | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//')
[ -z "$PLAYBOOK" ] && PLAYBOOK="null"

# init-guard.sh 用に playbook パスを記録
echo "$PLAYBOOK" > "$INIT_DIR/required_playbook"

# === Hook 検証（settings.json の全 Hook を自動検証） ===
verify_hooks

# === repository-map.yaml 差分チェック ===
check_repository_map_drift

# === ARCHITECTURE.md 同期チェック ===
check_architecture_sync
