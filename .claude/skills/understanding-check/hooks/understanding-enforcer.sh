#!/bin/bash
# ==============================================================================
# understanding-enforcer.sh - 理解確認スキップ検出 Hook
# ==============================================================================
# 目的: 理解確認なしでの実装開始を検出・警告
# トリガー: PreToolUse(Edit/Write)
#
# 設計思想:
#   - playbook 作成直後、理解確認なしで実装を開始することを検出
#   - Task(subagent_type='Explore') での理解確認を推奨
#   - 現在は警告のみ（将来的にブロック可能）
#
# 検出ロジック:
#   1. playbook が存在する
#   2. playbook の Phase が p0/p1
#   3. 理解確認の証跡がない（understanding_confirmed: true がない）
#   4. 実装ファイルへの Edit/Write
#
# 参照: .claude/skills/understanding-check/SKILL.md
# ==============================================================================

set -euo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

# state.md が存在しない場合はパス
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# ファイルパスを取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# --------------------------------------------------
# 対象外ファイルのフィルタリング
# --------------------------------------------------

# playbook, state.md, plan/, docs/ への変更は対象外
if [[ "$FILE_PATH" == *"playbook-"* ]] || \
   [[ "$FILE_PATH" == *"state.md" ]] || \
   [[ "$FILE_PATH" == *"plan/"* ]] || \
   [[ "$FILE_PATH" == *"docs/"* ]] || \
   [[ "$FILE_PATH" == *".claude/"* ]]; then
    exit 0
fi

# --------------------------------------------------
# playbook の存在と Phase チェック
# --------------------------------------------------

PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')

# playbook が null または空ならパス
if [[ -z "$PLAYBOOK" || "$PLAYBOOK" == "null" ]]; then
    exit 0
fi

# playbook ファイルが存在しない場合はパス
if [[ ! -f "$PLAYBOOK" ]]; then
    exit 0
fi

# --------------------------------------------------
# Phase チェック（初期 Phase のみ警告）
# --------------------------------------------------

CURRENT_PHASE=$(grep -A6 "^## goal" "$STATE_FILE" 2>/dev/null | grep "^phase:" | head -1 | sed 's/phase: *//' | sed 's/ *#.*//' | tr -d ' ')

# p0, p1, p2 の場合のみチェック
case "$CURRENT_PHASE" in
    p0|p1|p2)
        ;;
    *)
        exit 0
        ;;
esac

# --------------------------------------------------
# 理解確認の証跡チェック
# --------------------------------------------------

# playbook に understanding_confirmed: true があれば OK
if grep -q "understanding_confirmed: true" "$PLAYBOOK" 2>/dev/null; then
    exit 0
fi

# state.md に understanding_confirmed: true があれば OK
if grep -q "understanding_confirmed: true" "$STATE_FILE" 2>/dev/null; then
    exit 0
fi

# --------------------------------------------------
# 警告出力
# --------------------------------------------------

echo "" >&2
echo "=========================================" >&2
echo "  [understanding-enforcer] 理解確認推奨" >&2
echo "=========================================" >&2
echo "" >&2
echo "  Phase: $CURRENT_PHASE で実装を開始しようとしています。" >&2
echo "" >&2
echo "  理解確認を実施しましたか？" >&2
echo "" >&2
echo "  推奨アクション:" >&2
echo "    Task(subagent_type='Explore'," >&2
echo "         prompt='関連コードを調査して理解を確認')" >&2
echo "" >&2
echo "  確認済みの場合:" >&2
echo "    playbook に understanding_confirmed: true を追加" >&2
echo "" >&2
echo "=========================================" >&2

# 警告のみ（exit 0）- 将来的に exit 2 に変更可能
exit 0
