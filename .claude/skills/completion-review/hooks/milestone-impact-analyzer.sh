#!/bin/bash
# ==============================================================================
# milestone-impact-analyzer.sh - milestone 完了時の影響分析
# ==============================================================================
# 目的: milestone 完了時に他の milestone への影響を分析
# トリガー: PostToolUse(Edit) - project.md の milestone status 変更時
#
# 設計思想:
#   - milestone 間の依存関係を分析
#   - 完了 milestone に依存する milestone を検出
#   - ブロック解除された milestone を通知
#   - 逆影響（完了 milestone が壊れる可能性）を警告
#
# 分析項目:
#   1. depends_on 関係の確認
#   2. 依存 milestone のブロック解除
#   3. 関連 playbook の状態確認
#
# 参照: plan/project.md
# ==============================================================================

set -e

PROJECT_FILE="plan/project.md"

# project.md が存在しない場合はスキップ
if [ ! -f "$PROJECT_FILE" ]; then
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

# project.md 以外は無視
if [[ "$FILE_PATH" != *"project.md" ]]; then
    exit 0
fi

# 変更内容を取得
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // ""')

# status: achieved への変更を検出
if ! echo "$NEW_STRING" | grep -qE "status:[[:space:]]*achieved"; then
    exit 0
fi

# ==============================================================================
# milestone ID を抽出
# ==============================================================================

# 変更された milestone ID を推定（new_string から id: M{N} を探す）
MILESTONE_ID=$(echo "$NEW_STRING" | grep -oE "id: M[0-9]+" | head -1 | sed 's/id: //')

if [ -z "$MILESTONE_ID" ]; then
    # 直接 ID が見つからない場合、name から推定
    exit 0
fi

# ==============================================================================
# 影響分析
# ==============================================================================

echo ""
echo "========================================="
echo "  [milestone-impact-analyzer] 影響分析"
echo "========================================="
echo ""
echo "  完了 Milestone: $MILESTONE_ID"
echo ""

# この milestone に依存している他の milestone を検出
DEPENDENT_MILESTONES=$(grep -B 10 "depends_on:.*$MILESTONE_ID" "$PROJECT_FILE" 2>/dev/null | grep "id: M" | sed 's/.*id: //' | tr '\n' ', ' || echo "")

if [ -n "$DEPENDENT_MILESTONES" ]; then
    echo "  依存 Milestone（ブロック解除）:"
    echo "    $DEPENDENT_MILESTONES"
    echo ""
    echo "  これらの milestone は $MILESTONE_ID の完了により"
    echo "  着手可能になりました。"
else
    echo "  依存 Milestone: なし"
fi

echo ""

# 全 milestone の状態サマリー
TOTAL_MILESTONES=$(grep -c "^- id: M" "$PROJECT_FILE" 2>/dev/null) || TOTAL_MILESTONES=0
ACHIEVED_MILESTONES=$(grep -c "status: achieved" "$PROJECT_FILE" 2>/dev/null) || ACHIEVED_MILESTONES=0
PENDING_MILESTONES=$(grep -c "status: pending" "$PROJECT_FILE" 2>/dev/null) || PENDING_MILESTONES=0
IN_PROGRESS_MILESTONES=$(grep -c "status: in_progress" "$PROJECT_FILE" 2>/dev/null) || IN_PROGRESS_MILESTONES=0

echo "  Milestone サマリー:"
echo "    達成: $ACHIEVED_MILESTONES / $TOTAL_MILESTONES"
echo "    進行中: $IN_PROGRESS_MILESTONES"
echo "    保留: $PENDING_MILESTONES"
echo ""

# 全 milestone achieved の場合
if [ "$TOTAL_MILESTONES" -gt 0 ] && [ "$PENDING_MILESTONES" -eq 0 ] && [ "$IN_PROGRESS_MILESTONES" -eq 0 ]; then
    echo "  🎉 PROJECT COMPLETE - 全 Milestone 達成！"
    echo ""
    echo "  次のアクションを推奨:"
    echo "    1. PR をマージ"
    echo "    2. main ブランチを pull"
    echo "    3. state.md を neutral 状態に"
fi

echo ""
echo "========================================="

exit 0
