#!/bin/bash
# ==============================================================================
# stop-summary.sh - Stop Hook: Phase 状態サマリー出力
# ==============================================================================
# 確認事項対応:
#   #9: Phase 終了時の構造的出力（LLM 依存なく出力）
#
# 設計思想:
#   - エージェント停止試行時に現在の Phase 状態をサマリー出力
#   - LLM に依存せず、構造的にサマリーを提供
#   - ブロックはしない（情報提供のみ）
#
# 発火: Stop イベント（エージェント停止試行時）
# 入力: { "stop_hook_active": boolean }
# 出力: exit 0（通過）+ stdout にサマリー
# ==============================================================================

set -e

# stdin から JSON を読み込む
INPUT=$(cat)

STATE_FILE="state.md"
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# focus.current を取得
FOCUS=$(grep -A5 "## focus" "$STATE_FILE" 2>/dev/null | grep "current:" | head -1 | sed 's/.*current: *//' | sed 's/ *#.*//')

# active_playbooks から playbook を取得
PLAYBOOK=$(awk '/## active_playbooks/,/^---/' "$STATE_FILE" | grep "^${FOCUS}:" | head -1 | sed "s/${FOCUS}: *//" | sed 's/ *#.*//')

# playbook がない場合はスキップ
if [ -z "$PLAYBOOK" ] || [ "$PLAYBOOK" = "null" ] || [ ! -f "$PLAYBOOK" ]; then
    exit 0
fi

# 現在の Phase を取得
CURRENT_PHASE=$(grep -E "status: in_progress" "$PLAYBOOK" -B20 2>/dev/null | grep -E "^## p[0-9]" | tail -1 | sed 's/## //')
PHASE_STATUS=$(grep -E "status: in_progress" "$PLAYBOOK" 2>/dev/null | head -1 | sed 's/.*status: *//')

# Phase 名（goal）を取得
PHASE_GOAL=$(grep -E "status: in_progress" "$PLAYBOOK" -A5 2>/dev/null | grep "goal:" | head -1 | sed 's/.*goal: *//')

# done_criteria をカウント
TOTAL_CRITERIA=$(grep -E "^  - " "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')
DONE_CRITERIA=$(grep -E "✅" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')

# verification.self_complete を取得
SELF_COMPLETE=$(grep "self_complete:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*self_complete: *//' | sed 's/ *#.*//')

# Phase の done/pending/in_progress をカウント
PHASE_DONE=$(grep -E "status: done" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')
PHASE_PENDING=$(grep -E "status: pending" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')
PHASE_IN_PROGRESS=$(grep -E "status: in_progress" "$PLAYBOOK" 2>/dev/null | wc -l | tr -d ' ')

# サマリー出力
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│                    Phase 状態サマリー                       │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│                                                             │"
printf "│  Focus: %-50s │\n" "$FOCUS"
printf "│  Playbook: %-47s │\n" "$(basename "$PLAYBOOK")"
echo "│                                                             │"
echo "├─────────────────────────────────────────────────────────────┤"
printf "│  Current Phase: %-42s │\n" "${CURRENT_PHASE:-N/A}"
printf "│  Goal: %-52s │\n" "${PHASE_GOAL:-N/A}"
printf "│  Status: %-50s │\n" "${PHASE_STATUS:-N/A}"
echo "│                                                             │"
echo "├─────────────────────────────────────────────────────────────┤"
printf "│  Phases: done=%s / in_progress=%s / pending=%-15s │\n" "$PHASE_DONE" "$PHASE_IN_PROGRESS" "$PHASE_PENDING"
printf "│  Criteria: ✅ %s / total %-35s │\n" "$DONE_CRITERIA" "$TOTAL_CRITERIA"
printf "│  self_complete: %-43s │\n" "${SELF_COMPLETE:-N/A}"
echo "│                                                             │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""

# 次のアクション提案
if [ "$SELF_COMPLETE" = "true" ]; then
    echo "  ✅ critic PASS 済み。state: done への更新が可能です。"
elif [ "$SELF_COMPLETE" = "false" ]; then
    echo "  ⚠️  critic 未実行または FAIL。done 更新前に critic を呼び出してください。"
fi
echo ""

# 正常終了（ブロックしない）
exit 0
