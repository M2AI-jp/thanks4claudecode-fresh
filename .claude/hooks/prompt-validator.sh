#!/bin/bash
# prompt-validator.sh - 全ユーザープロンプトを project.md と照合
#
# UserPromptSubmit フックとして実行される。
# stdin からユーザープロンプトを受け取り、project.md との整合性をチェック。
#
# 設計思想:
#   - 全プロンプトで発火（例外なし）
#   - project.md の done_when と照合
#   - DRIFT 検出時は警告を出力（ブロックはしない）

set -e

# パス定義
PROJECT_FILE="plan/project.md"
STATE_FILE="state.md"

# 色定義
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# stdin からプロンプトを読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# プロンプト内容を取得
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')

# プロンプトが空なら終了
if [ -z "$PROMPT" ] || [ "$PROMPT" = "null" ]; then
    exit 0
fi

# project.md が存在しない場合はスキップ（setup 中）
if [ ! -f "$PROJECT_FILE" ]; then
    exit 0
fi

# session を確認（discussion なら軽量チェックのみ）
SESSION="task"
if [ -f "$STATE_FILE" ]; then
    SESSION_LINE=$(grep -A 2 "^## focus" "$STATE_FILE" 2>/dev/null | grep "session:" | head -1 || echo "")
    if [ -n "$SESSION_LINE" ]; then
        SESSION=$(echo "$SESSION_LINE" | sed 's/.*session:[[:space:]]*//' | sed 's/#.*//' | tr -d ' ')
    fi
fi

# project.md から done_when を抽出
DONE_WHEN=""
if [ -f "$PROJECT_FILE" ]; then
    # done_when セクションを抽出（簡易版）
    DONE_WHEN=$(grep -A 50 "^## done_when" "$PROJECT_FILE" 2>/dev/null | grep -E "^\s+\w+:" | head -5 || echo "")
fi

# プロンプトの内容を簡易分析
# キーワード抽出（日本語対応は限定的）
PROMPT_LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# 出力: プロンプト検証リマインダー
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${CYAN}[PROMPT_VALIDATION]${NC} プロンプト検証"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  受信プロンプト: ${PROMPT:0:50}..."
echo ""
echo "  project.md の主要ゴール:"
if [ -n "$DONE_WHEN" ]; then
    echo "$DONE_WHEN" | head -3 | while read -r line; do
        echo "    - ${line}"
    done
else
    echo "    (done_when 未定義)"
fi
echo ""
echo -e "  ${YELLOW}>>> plan-guard ロジックで整合性を判定せよ <<<${NC}"
echo ""
echo "  判定結果を宣言すること:"
echo "    - PROJECT_ALIGNED: 続行"
echo "    - EXTENSION: scope 拡張を提案"
echo "    - DRIFT: 乖離を報告"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit 0
