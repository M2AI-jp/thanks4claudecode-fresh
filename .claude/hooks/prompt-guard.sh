#!/bin/bash
# prompt-guard.sh - UserPromptSubmit Hook
#
# 確認事項対応:
#   #1: 全ユーザープロンプトが同一ワークフローで処理される
#   #10: 構造的にプロンプト拒否が可能
#   #NEW: ユーザープロンプトを保存し、コンテキスト消失を防止
#   #M005: State Injection - 常に state/project/playbook 情報を systemMessage に注入
#
# 設計思想:
#   - 全プロンプトで plan-guard ロジックを構造的に強制
#   - スコープ外プロンプトには警告またはブロック
#   - plan との整合性を構造的にチェック
#   - 全プロンプトを user-intent.md に保存（compact 対策）
#   - **常に state 情報を systemMessage で注入**（LLM が Read しなくても情報が届く）
#
# 入力: { "prompt": "ユーザー入力" }
# 出力:
#   - 常に: exit 0 + systemMessage（State Injection）
#   - 警告: systemMessage に警告を追加
#   - ブロック: exit 2 + stderr

set -e

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# prompt を取得
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')

# プロンプトが空の場合はスキップ
if [ -z "$PROMPT" ]; then
    exit 0
fi

# ==============================================================================
# State Injection - 常に state/project/playbook 情報を収集
# ==============================================================================
STATE_FILE="state.md"
PROJECT_FILE="plan/project.md"
WARNINGS=""

# state.md から情報抽出
if [ -f "$STATE_FILE" ]; then
    SI_FOCUS=$(grep -A5 "## focus" "$STATE_FILE" 2>/dev/null | grep "current:" | head -1 | sed 's/.*current: *//' | sed 's/ *#.*//')
    SI_MILESTONE=$(grep -A10 "## goal" "$STATE_FILE" 2>/dev/null | grep "milestone:" | head -1 | sed 's/.*milestone: *//' | sed 's/ *#.*//')
    SI_PHASE=$(grep -A10 "## goal" "$STATE_FILE" 2>/dev/null | grep "phase:" | head -1 | sed 's/.*phase: *//' | sed 's/ *#.*//')
    SI_PLAYBOOK=$(awk '/## playbook/,/^---/' "$STATE_FILE" 2>/dev/null | grep "active:" | head -1 | sed 's/.*active: *//' | sed 's/ *#.*//')
    SI_BRANCH=$(awk '/## playbook/,/^---/' "$STATE_FILE" 2>/dev/null | grep "branch:" | head -1 | sed 's/.*branch: *//' | sed 's/ *#.*//')

    # done_criteria は State Injection から削除（ユーザー指示）
    # 理由: LLM は playbook を直接読むべき。Hook での二重出力は不要。
    SI_CRITERIA=""
else
    SI_FOCUS="(state.md not found)"
    SI_MILESTONE="null"
    SI_PHASE="null"
    SI_PLAYBOOK="null"
    SI_BRANCH="unknown"
    SI_CRITERIA=""
fi

# project.md から情報抽出
if [ -f "$PROJECT_FILE" ]; then
    SI_PROJECT_GOAL=$(grep -A5 "## vision" "$PROJECT_FILE" 2>/dev/null | grep "goal:" | head -1 | sed 's/.*goal: *//' | sed 's/"//g')
    # 残り milestone 数をカウント（not_started + in_progress）
    SI_REMAINING_MS=$(grep -E "status: (not_started|in_progress)" "$PROJECT_FILE" 2>/dev/null | wc -l | tr -d ' ')
else
    SI_PROJECT_GOAL="(project.md not found)"
    SI_REMAINING_MS="?"
fi

# last_critic を取得（最新の p*-test-results.md から）
LOGS_DIR=".claude/logs"
if [ -d "$LOGS_DIR" ]; then
    LATEST_CRITIC=$(ls -t "$LOGS_DIR"/p*-test-results.md 2>/dev/null | head -1)
    if [ -n "$LATEST_CRITIC" ] && grep -q "ALL PASS" "$LATEST_CRITIC" 2>/dev/null; then
        SI_LAST_CRITIC="PASS"
    elif [ -n "$LATEST_CRITIC" ] && grep -q "FAIL" "$LATEST_CRITIC" 2>/dev/null; then
        SI_LAST_CRITIC="FAIL"
    else
        SI_LAST_CRITIC="null"
    fi
else
    SI_LAST_CRITIC="null"
fi

# playbook から残り phase 数をカウント
if [ -n "$SI_PLAYBOOK" ] && [ "$SI_PLAYBOOK" != "null" ] && [ -f "$SI_PLAYBOOK" ]; then
    SI_REMAINING_PH=$(grep -E "status: (pending|in_progress)" "$SI_PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')
else
    SI_REMAINING_PH="?"
fi

# git 情報
SI_GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
SI_GIT_STATUS=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$SI_GIT_STATUS" = "0" ]; then
    SI_GIT_STATUS="clean"
else
    SI_GIT_STATUS="${SI_GIT_STATUS} modified"
fi

# ==============================================================================
# プロンプト保存機能（コンテキスト消失対策）
# ==============================================================================
INTENT_DIR=".claude/.session-init"
INTENT_FILE="$INTENT_DIR/user-intent.md"

# ディレクトリがなければ作成
mkdir -p "$INTENT_DIR"

# タイムスタンプ
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# user-intent.md が存在しなければヘッダー作成
if [ ! -f "$INTENT_FILE" ]; then
    cat > "$INTENT_FILE" << 'HEADER'
# User Intent Log

> **セッション中のユーザープロンプトを記録。compact 後も参照可能。**

---

HEADER
fi

# プロンプトを追記（最新が上）
{
    echo "## [$TIMESTAMP]"
    echo ""
    echo '```'
    echo "$PROMPT"
    echo '```'
    echo ""
    echo "---"
    echo ""
    cat "$INTENT_FILE"
} > "$INTENT_FILE.tmp"
mv "$INTENT_FILE.tmp" "$INTENT_FILE"

# ==============================================================================
# MISSION 整合性チェック（報酬詐欺防止）- 警告を収集
# ==============================================================================
MISSION_FILE="plan/mission.md"
if [ -f "$MISSION_FILE" ]; then
    # 報酬詐欺パターンの検出
    FRAUD_PATTERNS="(完了しました|終わりました|できました|done|finished|completed)"
    FORGET_MISSION_PATTERNS="(忘れて|無視して|気にしないで|それはいい|forget|ignore|never mind)"

    if echo "$PROMPT" | grep -iE "$FRAUD_PATTERNS" > /dev/null 2>&1; then
        WARNINGS="${WARNINGS}\\n\\n⚠️ 報酬詐欺パターン検出: critic PASS なしで done にしないこと。"
    fi

    if echo "$PROMPT" | grep -iE "$FORGET_MISSION_PATTERNS" > /dev/null 2>&1; then
        WARNINGS="${WARNINGS}\\n\\n🎯 MISSION リマインダー: ユーザープロンプトに引っ張られないでください。"
    fi
fi

# ==============================================================================
# スコープチェック処理 - 警告を収集
# ==============================================================================

# playbook 情報を使用（既に SI_PLAYBOOK で取得済み）
PLAYBOOK="$SI_PLAYBOOK"

# playbook が null または空の場合
if [ -z "$PLAYBOOK" ] || [ "$PLAYBOOK" = "null" ]; then
    WORK_PATTERNS="(作って|実装して|追加して|修正して|変更して|削除して|create|implement|add|fix|change|delete|update|edit|write)"

    if echo "$PROMPT" | grep -iE "$WORK_PATTERNS" > /dev/null 2>&1; then
        WARNINGS="${WARNINGS}\\n\\n🚨 playbook がありません。Edit/Write 時にブロックされます。"
    fi
fi

# playbook が存在する場合、スコープチェック
if [ -n "$PLAYBOOK" ] && [ "$PLAYBOOK" != "null" ] && [ -f "$PLAYBOOK" ]; then
    SCOPE_CREEP_PATTERNS="(ついでに|ちょっと|別の|他の|追加で|ほかにも|also|another|while you're at it)"

    if echo "$PROMPT" | grep -iE "$SCOPE_CREEP_PATTERNS" > /dev/null 2>&1; then
        WARNINGS="${WARNINGS}\\n\\n⚠️ スコープ拡張を検出。現在の phase に集中してください。"
    fi

    # 明確なスコープ外（ブロック）
    UNRELATED_PATTERNS="(天気|ニュース|レシピ|翻訳して|weather|news|recipe|translate)"

    if echo "$PROMPT" | grep -iE "$UNRELATED_PATTERNS" > /dev/null 2>&1; then
        echo "" >&2
        echo "========================================" >&2
        echo "  [prompt-guard] スコープ外のリクエスト" >&2
        echo "========================================" >&2
        echo "  このリクエストは開発作業と無関係です。" >&2
        echo "  現在の focus: $SI_FOCUS" >&2
        echo "========================================" >&2
        exit 2
    fi
fi

# ==============================================================================
# State Injection - 常に systemMessage を出力
# ==============================================================================

# JSON 用に特殊文字をエスケープ
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/	/\\t/g'
}

# systemMessage を構築（簡素化版）
SI_MESSAGE="━━━ State Injection ━━━\\n"
SI_MESSAGE="${SI_MESSAGE}focus: $(escape_json "$SI_FOCUS")\\n"
SI_MESSAGE="${SI_MESSAGE}milestone: $(escape_json "$SI_MILESTONE")\\n"

# playbook がある場合のみ詳細を出力
if [ -n "$SI_PLAYBOOK" ] && [ "$SI_PLAYBOOK" != "null" ]; then
    SI_MESSAGE="${SI_MESSAGE}phase: $(escape_json "$SI_PHASE")\\n"
    SI_MESSAGE="${SI_MESSAGE}playbook: $(escape_json "$SI_PLAYBOOK")\\n"
    SI_MESSAGE="${SI_MESSAGE}remaining: ${SI_REMAINING_PH} phases\\n"
    # done_criteria は出力しない（LLM は playbook を直接読む）
else
    SI_MESSAGE="${SI_MESSAGE}playbook: null\\n"
fi

SI_MESSAGE="${SI_MESSAGE}branch: $(escape_json "$SI_GIT_BRANCH")\\n"
SI_MESSAGE="${SI_MESSAGE}git: $(escape_json "$SI_GIT_STATUS")\\n"
SI_MESSAGE="${SI_MESSAGE}remaining_milestones: ${SI_REMAINING_MS}\\n"
SI_MESSAGE="${SI_MESSAGE}━━━━━━━━━━━━━━━━━━━━━━━━"

# 警告があれば追加
if [ -n "$WARNINGS" ]; then
    SI_MESSAGE="${SI_MESSAGE}\\n${WARNINGS}"
fi

# systemMessage を JSON で出力
cat <<EOF
{
  "systemMessage": "${SI_MESSAGE}"
}
EOF

exit 0
