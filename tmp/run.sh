#!/bin/bash
#
# run.sh - 複数言語パイプラインオーケストレーター
#
# Python -> TypeScript の順で処理を実行し、最終結果を出力する。
# オーケストレーション練習用のメインエントリーポイント。
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 入力データ（デフォルト値）
INPUT_JSON='{"input": "orchestration demo", "source": "run.sh"}'

# コマンドライン引数があれば使用
if [[ $# -gt 0 ]]; then
    INPUT_JSON="$1"
fi

echo "=== Multi-Language Pipeline ===" >&2
echo "Input: $INPUT_JSON" >&2
echo "" >&2

# Step 1: Python 処理
echo "[Step 1] Running Python processor..." >&2
PYTHON_OUTPUT=$(printf '%s' "$INPUT_JSON" | python3 "$SCRIPT_DIR/process.py")
echo "[Step 1] Python completed." >&2
echo "" >&2

# Step 2: TypeScript 処理（後で追加）
# transform.ts が存在する場合のみ実行
if [[ -f "$SCRIPT_DIR/transform.ts" ]]; then
    echo "[Step 2] Running TypeScript transformer..." >&2
    FINAL_OUTPUT=$(printf '%s' "$PYTHON_OUTPUT" | npx ts-node "$SCRIPT_DIR/transform.ts")
    echo "[Step 2] TypeScript completed." >&2
else
    echo "[Step 2] TypeScript transformer not found, skipping..." >&2
    FINAL_OUTPUT="$PYTHON_OUTPUT"
fi

echo "" >&2
echo "=== Final Result ===" >&2

# 最終結果を stdout に出力
echo "$FINAL_OUTPUT"
