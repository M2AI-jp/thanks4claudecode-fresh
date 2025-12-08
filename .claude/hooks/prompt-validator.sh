#!/bin/bash
# prompt-validator.sh - プロンプトを自動分類し session を更新
#
# UserPromptSubmit フックとして実行される。
# stdin からユーザープロンプトを受け取り、キーワードで TASK/CHAT/QUESTION/META を判定。
# 判定結果を state.md の session に自動書き込み。
#
# 設計思想:
#   - 全プロンプトで発火（例外なし）
#   - Claude に依存しない自動判定
#   - 後続の Hooks が session を参照して動作を変える

set -e

# デバッグログ（発火確認用）
LOG_FILE=".claude/logs/prompt-validator.log"
mkdir -p "$(dirname "$LOG_FILE")"

# パス定義
STATE_FILE="state.md"

# 色定義
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

# stdin からプロンプトを読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# プロンプト内容を取得（jq parse error を明示的にハンドリング）
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null) || {
    # jq parse error: 不正な JSON の場合は silent skip
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: jq parse failed, skipping" >> "$LOG_FILE"
    exit 0
}

# プロンプトが空なら終了
if [ -z "$PROMPT" ] || [ "$PROMPT" = "null" ]; then
    exit 0
fi

# state.md が存在しない場合はスキップ
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# ============================================================
# キーワード判定ロジック
# state.md の session_definition に基づく
# ============================================================

# プロンプトを小文字化（英語キーワード用）
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# デフォルト値
SESSION_TYPE="QUESTION"

# TASK キーワード判定（日本語）
if echo "$PROMPT" | grep -qE "(作って|実装|追加して|修正|直して|書いて|削除|変更して|作成|リファクタ)"; then
    SESSION_TYPE="TASK"
# TASK キーワード判定（英語）
elif echo "$PROMPT_LOWER" | grep -qE "(create|implement|add|fix|write|delete|change|build|make|refactor)"; then
    SESSION_TYPE="TASK"
# CHAT キーワード判定（日本語）
elif echo "$PROMPT" | grep -qE "^(こんにちは|ありがとう|お疲れ|おはよう|さようなら|よろしく)"; then
    SESSION_TYPE="CHAT"
# CHAT キーワード判定（英語）
elif echo "$PROMPT_LOWER" | grep -qE "^(hello|hi|thanks|thank you|bye|good morning|good evening)"; then
    SESSION_TYPE="CHAT"
# META キーワード判定（日本語）
elif echo "$PROMPT" | grep -qE "(ついでに|別の|計画|scope|予定|変更したい|あと|追加で)"; then
    SESSION_TYPE="META"
# META キーワード判定（英語）
elif echo "$PROMPT_LOWER" | grep -qE "(also|another|plan|scope|schedule|btw|additionally)"; then
    SESSION_TYPE="META"
# QUESTION キーワード判定（日本語）
elif echo "$PROMPT" | grep -qE "(？|何|どう|ですか|って|どこ|いつ|なぜ|教えて)"; then
    SESSION_TYPE="QUESTION"
# QUESTION キーワード判定（英語）
elif echo "$PROMPT_LOWER" | grep -qE "(\?|what|how|where|when|why|which|can you|does|is it)"; then
    SESSION_TYPE="QUESTION"
fi
# それ以外はデフォルト（QUESTION）

# ログに記録
echo "[$(date '+%Y-%m-%d %H:%M:%S')] session=$SESSION_TYPE prompt=${PROMPT:0:50}..." >> "$LOG_FILE"

# ============================================================
# state.md の session を更新
# ============================================================

# 現在の session を取得
CURRENT_SESSION=""
if [ -f "$STATE_FILE" ]; then
    CURRENT_SESSION=$(grep -A 2 "^## focus" "$STATE_FILE" 2>/dev/null | grep "session:" | head -1 | sed 's/.*session:[[:space:]]*//' | sed 's/#.*//' | tr -d ' ' || echo "")
fi

# session が変わる場合のみ更新
if [ "$SESSION_TYPE" != "$CURRENT_SESSION" ]; then
    # sed で session 行を更新（macOS 対応）
    if sed --version 2>/dev/null | grep -q GNU; then
        # GNU sed
        sed -i "s/^session: .*/session: $SESSION_TYPE            # TASK | CHAT | QUESTION | META（Hook が自動更新）/" "$STATE_FILE"
    else
        # BSD sed (macOS)
        sed -i '' "s/^session: .*/session: $SESSION_TYPE            # TASK | CHAT | QUESTION | META（Hook が自動更新）/" "$STATE_FILE"
    fi
fi

# ============================================================
# 出力: session 判定結果
# ============================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${CYAN}[SESSION]${NC} $SESSION_TYPE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

case "$SESSION_TYPE" in
    TASK)
        echo -e "  ${GREEN}作業モード${NC}: playbook 必須、guard 発動"
        ;;
    CHAT)
        echo -e "  ${GREEN}雑談モード${NC}: guard スキップ、簡潔に応答"
        ;;
    QUESTION)
        echo -e "  ${GREEN}質問モード${NC}: guard スキップ、調査可能"
        ;;
    META)
        echo -e "  ${YELLOW}計画変更モード${NC}: plan-guard で整合性確認"
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit 0
