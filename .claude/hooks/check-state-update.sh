#!/bin/bash
#
# check-state-update.sh
# git commit 前に state.md の更新をチェックする Hook
#
# 設計思想（アクションベース Guards）:
#   - コミット時に state.md が staged されているかをチェック
#   - state.md の更新を促すことで、作業状態の追跡を強制
#
# 動作:
#   - state.md が staged されていない場合、警告を出す
#   - ブロックはしない（警告のみ）

set -e

STATE_FILE="state.md"

# state.md が存在しない場合はスキップ
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# state.md が staged されているかチェック
if ! git diff --cached --name-only 2>/dev/null | grep -q "state.md"; then
    echo "" >&2
    echo "========================================" >&2
    echo " WARNING: state.md が更新されていません" >&2
    echo "========================================" >&2
    echo "" >&2
    echo " commit 前に state.md を更新することを推奨します。" >&2
    echo "" >&2
    echo " 対処法:" >&2
    echo "   1. state.md を更新してステージング" >&2
    echo "   2. または、このまま続行（非推奨）" >&2
    echo "" >&2
    # 警告のみ、ブロックはしない
fi

exit 0
