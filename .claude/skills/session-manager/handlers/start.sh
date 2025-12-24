#!/bin/bash
# session-start.sh - LLMの自己認識を形成し、LOOPを開始させる
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
    local ACTUAL_AGENTS=$(find .claude/agents -maxdepth 1 -name "*.md" -type f ! -name "CLAUDE.md" 2>/dev/null | wc -l | tr -d ' ')
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
# restore_from_snapshot - compact 後の状態復元
# snapshot.json が存在する場合、前回の作業状態を表示して復元
# ==============================================================================
restore_from_snapshot() {
    local SNAPSHOT_FILE=".claude/.session-init/snapshot.json"
    local SNAPSHOT_ARCHIVE_DIR=".claude/.session-init/archive"

    # snapshot.json が存在しない場合は何もしない
    [ ! -f "$SNAPSHOT_FILE" ] && return 0

    # JSON パースを試行（破損している場合はスキップ）
    if ! jq -e '.' "$SNAPSHOT_FILE" >/dev/null 2>&1; then
        echo "[WARN] snapshot.json が破損しています。スキップします。"
        rm -f "$SNAPSHOT_FILE" 2>/dev/null || true
        return 0
    fi

    # snapshot から情報を抽出
    local SNAP_FOCUS=$(jq -r '.focus // "unknown"' "$SNAPSHOT_FILE" 2>/dev/null)
    local SNAP_PLAYBOOK=$(jq -r '.playbook // "null"' "$SNAPSHOT_FILE" 2>/dev/null)
    local SNAP_PHASE=$(jq -r '.current_phase // "unknown"' "$SNAPSHOT_FILE" 2>/dev/null)
    local SNAP_INTENTS=$(jq -r '.user_intents // ""' "$SNAPSHOT_FILE" 2>/dev/null)
    local SNAP_TIMESTAMP=$(jq -r '.timestamp // ""' "$SNAPSHOT_FILE" 2>/dev/null)
    local SNAP_BRANCH=$(jq -r '.branch // ""' "$SNAPSHOT_FILE" 2>/dev/null)

    # 復元メッセージを表示
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  [COMPACT 復元] 前回の作業状態を復元しました"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  📍 focus: $SNAP_FOCUS"
    echo "  📋 playbook: $SNAP_PLAYBOOK"
    echo "  🔄 phase: $SNAP_PHASE"
    echo "  🌿 branch: $SNAP_BRANCH"
    echo "  ⏰ snapshot 時刻: $SNAP_TIMESTAMP"
    echo ""

    # user_intents が存在する場合は表示
    if [ -n "$SNAP_INTENTS" ] && [ "$SNAP_INTENTS" != "\"\"" ] && [ "$SNAP_INTENTS" != "" ]; then
        echo "  📝 ユーザー意図（最新）:"
        echo "$SNAP_INTENTS" | head -20 | sed 's/^/    /'
        echo ""
    fi

    echo "  → この意図に沿って作業を継続してください"
    echo ""

    # snapshot.json を削除（二重復元防止）
    # オプション: archive に保存する場合
    # mkdir -p "$SNAPSHOT_ARCHIVE_DIR"
    # mv "$SNAPSHOT_FILE" "$SNAPSHOT_ARCHIVE_DIR/snapshot-$(date +%Y%m%d-%H%M%S).json" 2>/dev/null || true
    rm -f "$SNAPSHOT_FILE" 2>/dev/null || true

    return 0
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

FOCUS=$(grep -A5 "## focus" state.md | grep "current:" | sed 's/.*: *//' | sed 's/ *#.*//')
PHASE=$(grep -A5 "## goal" state.md | grep "phase:" | head -1 | sed 's/.*: *//' | sed 's/ *#.*//')
CRITERIA=$(awk '/## goal/,/^## [^g]/' state.md | grep -A20 "done_criteria:" | grep "^  -" | head -6)
BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# playbook 取得（## playbook セクションから active を読み取り）
PLAYBOOK=$(awk '/## playbook/,/^---/' state.md | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//')
[ -z "$PLAYBOOK" ] && PLAYBOOK="null"

# init-guard.sh 用に playbook パスを記録
echo "$PLAYBOOK" > "$INIT_DIR/required_playbook"

# === compact 後の状態復元（snapshot.json が存在する場合のみ） ===
restore_from_snapshot

# === repository-map.yaml 差分チェック ===
check_repository_map_drift
