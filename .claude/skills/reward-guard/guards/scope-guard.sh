#!/bin/bash
# scope-guard.sh - done_criteria/done_when の無断変更を検出
#
# 目的: pm を経由せずにスコープを拡張することを防止
# トリガー: PreToolUse(Edit), PreToolUse(Write)
#
# 設計思想（アクションベース Guards）:
#   - Edit/Write 時に常にチェック
#   - playbook のスコープ変更を検出
#
# 検出対象:
#   - playbook ファイルの done_when/done_criteria セクション
#
# 動作:
#   - 該当セクションの編集を検出したら警告
#   - pm エージェント経由を促す

set -euo pipefail

# 環境変数で動作モードを制御
# STRICT_MODE=true: exit 2 でブロック
# STRICT_MODE=false (default): 警告のみ
STRICT_MODE="${STRICT_MODE:-false}"

STATE_FILE="${STATE_FILE:-state.md}"

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

# 相対パスに変換
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RELATIVE_PATH="${FILE_PATH#$PROJECT_DIR/}"

# playbook 以外は無視
IS_PLAYBOOK=false

if [[ "$RELATIVE_PATH" == plan/playbook-*.md ]] || [[ "$RELATIVE_PATH" == *playbook*.md ]]; then
    IS_PLAYBOOK=true
fi

if [[ "$IS_PLAYBOOK" == false ]]; then
    exit 0
fi

# 編集内容（old_string, new_string）を取得
OLD_STRING=$(echo "$INPUT" | jq -r '.tool_input.old_string // ""')
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // ""')

# done_when または done_criteria を含むか確認
MODIFYING_SCOPE=false

# 1. old_string に done_when/done_criteria が含まれている（既存の定義を変更）
if [[ "$OLD_STRING" == *"done_when"* ]] || [[ "$OLD_STRING" == *"done_criteria"* ]]; then
    MODIFYING_SCOPE=true
fi

# 2. new_string に done_when/done_criteria が追加されている（新規追加）
if [[ "$NEW_STRING" == *"done_when"* ]] || [[ "$NEW_STRING" == *"done_criteria"* ]]; then
    # old_string に含まれていない場合は追加
    if [[ "$OLD_STRING" != *"done_when"* ]] && [[ "$NEW_STRING" == *"done_when"* ]]; then
        MODIFYING_SCOPE=true
    fi
    if [[ "$OLD_STRING" != *"done_criteria"* ]] && [[ "$NEW_STRING" == *"done_criteria"* ]]; then
        MODIFYING_SCOPE=true
    fi
fi

# スコープ変更を検出したら警告（ブロックはしない）
if [[ "$MODIFYING_SCOPE" == true ]]; then
    cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⚠️ スコープ変更を検出
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  done_when または done_criteria を変更しようとしています。

  確認事項:
    - この変更はユーザーの承認を得ていますか？
    - pm エージェントを経由しましたか？
    - スコープクリープ（範囲の無断拡大）ではありませんか？

  正しい手順:
    1. ユーザーに変更理由を説明
    2. pm エージェントで playbook を更新
       Task(subagent_type='pm', prompt='スコープを変更したい')
    3. 承認を得てから編集

  スコープクリープの例（禁止）:
    × 「ついでに〇〇も追加しよう」
    × 「もっと良くするために△△も」
    × ユーザーに聞かずに done_criteria を追加

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    echo "  対象ファイル: $RELATIVE_PATH"
    echo ""

    if [[ "$STRICT_MODE" == "true" ]]; then
        echo "  🚫 STRICT_MODE=true: この変更はブロックされます"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        exit 2
    else
        echo "  ⚠️ 警告のみ（STRICT_MODE=true でブロック可能）"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
fi

exit 0
