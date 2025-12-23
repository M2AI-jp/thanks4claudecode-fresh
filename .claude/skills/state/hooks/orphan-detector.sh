#!/bin/bash
# ==============================================================================
# orphan-detector.sh - 孤立 playbook 検出 Hook
# ==============================================================================
# 目的: state.md と紐づかない playbook（孤立 playbook）を検出
# トリガー: SessionStart または手動実行
#
# 設計思想:
#   - plan/ 内に playbook があるのに state.md で参照されていない状態を検出
#   - 孤立 playbook はアーカイブまたは削除を推奨
#   - セッション開始時の状態確認に使用
#
# 検出ロジック:
#   1. plan/ 内の playbook-*.md を列挙
#   2. state.md の playbook.active と比較
#   3. 一致しない playbook があれば警告
#
# 参照: docs/archive-operation-rules.md
# ==============================================================================

set -euo pipefail

STATE_FILE="${STATE_FILE:-state.md}"
PLAN_DIR="${PLAN_DIR:-plan}"

# state.md が存在しない場合は警告
if [[ ! -f "$STATE_FILE" ]]; then
    echo "[orphan-detector] WARNING: state.md が存在しません"
    exit 0
fi

# --------------------------------------------------
# 現在のアクティブ playbook を取得
# --------------------------------------------------

ACTIVE_PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')

# null または空の場合は playbook なし
if [[ -z "$ACTIVE_PLAYBOOK" || "$ACTIVE_PLAYBOOK" == "null" ]]; then
    ACTIVE_PLAYBOOK=""
fi

# --------------------------------------------------
# plan/ 内の playbook を列挙
# --------------------------------------------------

ORPHAN_PLAYBOOKS=""
ORPHAN_COUNT=0

for pb in "$PLAN_DIR"/playbook-*.md; do
    # ファイルが存在しない場合（glob が展開されない場合）はスキップ
    if [[ ! -f "$pb" ]]; then
        continue
    fi

    # アクティブ playbook と比較
    if [[ "$pb" != "$ACTIVE_PLAYBOOK" ]]; then
        ORPHAN_PLAYBOOKS="$ORPHAN_PLAYBOOKS\n    - $pb"
        ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
    fi
done

# --------------------------------------------------
# 結果出力
# --------------------------------------------------

if [[ $ORPHAN_COUNT -gt 0 ]]; then
    echo ""
    echo "========================================="
    echo "  [orphan-detector] 孤立 playbook 検出"
    echo "========================================="
    echo ""
    echo "  以下の playbook は state.md と紐づいていません:"
    echo -e "$ORPHAN_PLAYBOOKS"
    echo ""
    echo "  推奨アクション:"
    echo "    1. アーカイブ: mv <playbook> plan/archive/"
    echo "    2. または削除（完了済みの場合）"
    echo ""
    echo "  アクティブ playbook: ${ACTIVE_PLAYBOOK:-null}"
    echo ""
    echo "========================================="

    # 警告のみ（exit 0）
    exit 0
fi

echo "[orphan-detector] OK: 孤立 playbook なし"
exit 0
