#!/bin/bash
# prompt-validator.sh - プロンプト分類をトリガー
#
# UserPromptSubmit フックとして実行される。
# 機械的に発火し、Claude に分類を指示する。
# 実際の分類は LLM の自然言語理解に任せる。
#
# 設計思想:
#   - Hook: 発火のみ（キーワード判定しない）
#   - LLM: NLU で分類（自然言語の強みを活かす）
#   - Guard: session を読んで強制（構造的制御）

set -e

# 色定義
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# state.md が存在しない場合はスキップ
if [ ! -f "state.md" ]; then
    exit 0
fi

# 現在の session を取得（リセット前の値を記録用に保持）
OLD_SESSION=$(grep -A 2 "^## focus" "state.md" 2>/dev/null | grep "session:" | head -1 | sed 's/.*session:[[:space:]]*//' | sed 's/#.*//' | tr -d ' ' || echo "QUESTION")

# ============================================================
# 構造的強制: session を TASK にリセット
# ============================================================
# 設計思想:
#   - デフォルト = TASK（最も厳しいモード、Guards 発動）
#   - Claude が NLU で CHAT/QUESTION/META と判断したら明示的に変更
#   - Claude が忘れても TASK として動作（安全側フォール）
#   - キーワード判定は一切しない（NLU に任せる）

# session を TASK にリセット（BSD/GNU 両対応）
if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' 's/^session: .*/session: TASK                # TASK | CHAT | QUESTION | META（Claude が NLU で判断）/' "state.md"
else
    sed -i 's/^session: .*/session: TASK                # TASK | CHAT | QUESTION | META（Claude が NLU で判断）/' "state.md"
fi

CURRENT_SESSION="TASK"

# ============================================================
# 出力: Claude への分類指示
# ============================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${CYAN}[SESSION: TASK にリセット済み]${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  前回: $OLD_SESSION → 現在: TASK"
echo ""
echo -e "  ${YELLOW}【NLU 判断】TASK 以外なら state.md を更新${NC}"
echo ""
echo "  TASK: そのまま（Guards 発動）"
echo "  CHAT: Edit で session: CHAT に変更"
echo "  QUESTION: Edit で session: QUESTION に変更"
echo "  META: Edit で session: META に変更"
echo ""
echo "  → 変更しなければ TASK として処理される"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit 0
