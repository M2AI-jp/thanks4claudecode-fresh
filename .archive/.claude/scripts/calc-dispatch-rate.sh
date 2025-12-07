#!/bin/bash
# calc-dispatch-rate.sh - subagent 発動率を計算
#
# 使用法: bash .claude/scripts/calc-dispatch-rate.sh [期間]
# 期間: today, week, all (default: all)

set -euo pipefail

LOG_FILE="${LOG_FILE:-.claude/logs/subagent-dispatch.log}"
PERIOD="${1:-all}"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "ログファイルが見つかりません: $LOG_FILE"
    exit 1
fi

# ヘッダー行を除外
log_lines() {
    grep -v "^#" "$LOG_FILE" | grep -v "^$"
}

# 期間フィルタ
filter_by_period() {
    case "$PERIOD" in
        today)
            today=$(date +%Y-%m-%d)
            grep "^$today"
            ;;
        week)
            # 過去7日
            for i in $(seq 0 6); do
                day=$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "$i days ago" +%Y-%m-%d)
                echo "$day"
            done | while read d; do grep "^$d" || true; done
            ;;
        all)
            cat
            ;;
        *)
            echo "不明な期間: $PERIOD (today, week, all のいずれか)"
            exit 1
            ;;
    esac
}

# 集計
echo "=== Subagent 発動率レポート ==="
echo "期間: $PERIOD"
echo ""

total=$(log_lines | filter_by_period | wc -l | tr -d ' ')

if [[ "$total" -eq 0 ]]; then
    echo "ログが見つかりません。"
    exit 0
fi

echo "総発動回数: $total"
echo ""

echo "=== エージェント別 ==="
log_lines | filter_by_period | cut -d'|' -f2 | sed 's/ //g' | sort | uniq -c | sort -rn | while read count agent; do
    rate=$((count * 100 / total))
    printf "  %-20s %3d回 (%3d%%)\n" "$agent" "$count" "$rate"
done

echo ""
echo "=== 結果別 ==="
log_lines | filter_by_period | cut -d'|' -f4 | sed 's/ //g' | sort | uniq -c | sort -rn | while read count result; do
    rate=$((count * 100 / total))
    printf "  %-10s %3d回 (%3d%%)\n" "$result" "$count" "$rate"
done
