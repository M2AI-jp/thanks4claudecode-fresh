#!/bin/bash
# subagent-stop.sh - SubAgent 終了時の後処理
#
# 目的: SubAgent 終了時にクリーンアップを実行
# トリガー: SubagentStop イベント
#
# 設計思想:
#   - SubAgent がバックグラウンドで残存することを防止
#   - ログ記録で問題発生時のデバッグを支援

set -euo pipefail

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# SubAgent 情報を取得
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# ログディレクトリ
LOG_DIR=".claude/logs"
mkdir -p "$LOG_DIR"

# 終了ログを記録
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] SubAgent stopped: $AGENT_ID (session: $SESSION_ID)" >> "$LOG_DIR/subagent.log"

# 正常終了
exit 0
