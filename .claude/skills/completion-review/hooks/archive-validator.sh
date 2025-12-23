#!/bin/bash
# ==============================================================================
# archive-validator.sh - playbook 完了時の検証とアーカイブ提案（強化版）
# ==============================================================================
# 目的: playbook の全 Phase が done になったらアーカイブ前検証を実行
# トリガー: PostToolUse(Edit)
#
# 設計思想:
#   - 全 Phase done を自動検出
#   - p_final の完了を必須化（exit 2 でブロック）
#   - 全 subtask 完了を必須化（exit 2 でブロック）
#   - 検証 PASS 時のみアーカイブを提案
#
# 検証項目:
#   1. 全 Phase が done
#   2. 全 subtask が完了（- [x]）
#   3. final_tasks が完了（存在する場合）
#   4. p_final が完了（done_when 検証済み）
#
# 参照: docs/archive-operation-rules.md
# ==============================================================================

set -e

# state.md が存在しない場合はスキップ
if [ ! -f "state.md" ]; then
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

# playbook ファイル以外は無視
if [[ "$FILE_PATH" != *playbook*.md ]]; then
    exit 0
fi

# playbook ファイルが存在しない場合はスキップ
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# ==============================================================================
# Phase 完了チェック
# ==============================================================================

TOTAL_PHASES=$(grep -c '^\*\*status\*\*:' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
DONE_PHASES=$(grep -c '^\*\*status\*\*: done' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
TOTAL_PHASES=${TOTAL_PHASES:-0}
DONE_PHASES=${DONE_PHASES:-0}

# Phase がない場合はスキップ
if [ "$TOTAL_PHASES" -eq 0 ]; then
    exit 0
fi

# 全 Phase が done でない場合はスキップ
if [ "$DONE_PHASES" -ne "$TOTAL_PHASES" ]; then
    exit 0
fi

# ==============================================================================
# subtask 完了チェック（必須）
# ==============================================================================

CHECKED_COUNT=$(grep -c '\- \[x\]' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
UNCHECKED_COUNT=$(grep -c '\- \[ \]' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
CHECKED_COUNT=${CHECKED_COUNT:-0}
UNCHECKED_COUNT=${UNCHECKED_COUNT:-0}
TOTAL_CHECKBOX=$((CHECKED_COUNT + UNCHECKED_COUNT))

if [ "$TOTAL_CHECKBOX" -gt 0 ] && [ "$UNCHECKED_COUNT" -gt 0 ]; then
    cat >&2 << EOF
========================================
  [archive-validator] subtask 未完了
========================================

  アーカイブをブロックします。

  完了: $CHECKED_COUNT / 未完了: $UNCHECKED_COUNT

  全ての subtask を完了させてください:
    - [ ] → - [x] に変更
    - validations を追加
    - validated タイムスタンプを追加

  参照: .claude/skills/completion-review/frameworks/completion-criteria.md

========================================
EOF
    exit 2
fi

# ==============================================================================
# final_tasks チェック（存在する場合）
# ==============================================================================

if grep -q "^## final_tasks" "$FILE_PATH" 2>/dev/null; then
    TOTAL_FINAL_TASKS=$(grep -A 100 "^## final_tasks" "$FILE_PATH" | grep -c '\- \[.\] \*\*ft' 2>/dev/null || echo "0")
    DONE_FINAL_TASKS=$(grep -A 100 "^## final_tasks" "$FILE_PATH" | grep -c '\- \[x\] \*\*ft' 2>/dev/null || echo "0")

    if [ "$TOTAL_FINAL_TASKS" -gt 0 ] && [ "$DONE_FINAL_TASKS" -lt "$TOTAL_FINAL_TASKS" ]; then
        cat >&2 << EOF
========================================
  [archive-validator] final_tasks 未完了
========================================

  警告: final_tasks が未完了です。

  完了: $DONE_FINAL_TASKS / $TOTAL_FINAL_TASKS

  final_tasks を全て完了してからアーカイブしてください。

========================================
EOF
        # 警告のみ（ブロックしない）
    fi
fi

# ==============================================================================
# p_final チェック（必須）
# ==============================================================================

DONE_WHEN_SECTION=$(sed -n '/^done_when:/,/^[a-z_]*:/p' "$FILE_PATH" 2>/dev/null | grep "^  - " | head -10)
DONE_WHEN_COUNT=$(echo "$DONE_WHEN_SECTION" | grep -c "^  - " 2>/dev/null) || DONE_WHEN_COUNT=0

if [ "$DONE_WHEN_COUNT" -gt 0 ]; then
    if ! grep -q "p_final" "$FILE_PATH" 2>/dev/null; then
        cat >&2 << EOF
========================================
  [archive-validator] p_final 未存在
========================================

  警告: p_final（完了検証フェーズ）が存在しません。

  done_when: $DONE_WHEN_COUNT 項目

  playbook に p_final フェーズを追加してください。
  参照: plan/template/playbook-format.md

========================================
EOF
    fi

    # p_final セクションの subtask チェック
    P_FINAL_SECTION=$(grep -A 100 "p_final" "$FILE_PATH" 2>/dev/null | head -100)
    INCOMPLETE_SUBTASKS=$(echo "$P_FINAL_SECTION" | grep -c '\- \[ \]' 2>/dev/null) || INCOMPLETE_SUBTASKS=0

    if [ "$INCOMPLETE_SUBTASKS" -gt 0 ]; then
        cat >&2 << EOF
========================================
  [archive-validator] p_final 未完了
========================================

  アーカイブをブロックします。

  p_final の未完了 subtask: $INCOMPLETE_SUBTASKS 個

  全ての p_final subtasks を完了させてください。
  → validations（3点検証）が全て PASS である必要があります。

  参照: .claude/skills/completion-review/frameworks/completion-criteria.md

========================================
EOF
        exit 2
    fi
fi

# ==============================================================================
# アーカイブ提案
# ==============================================================================

RELATIVE_PATH="${FILE_PATH#$(pwd)/}"
PLAYBOOK_NAME=$(basename "$FILE_PATH")
ARCHIVE_DIR="plan/archive"
ARCHIVE_PATH="$ARCHIVE_DIR/$PLAYBOOK_NAME"

cat << EOF

========================================
  [archive-validator] アーカイブ準備完了
========================================

  Playbook: $RELATIVE_PATH
  Status: 全 $TOTAL_PHASES Phase が done
  Subtasks: 全 $CHECKED_COUNT 件完了

  アーカイブを推奨します:
    mkdir -p $ARCHIVE_DIR
    mv $RELATIVE_PATH $ARCHIVE_PATH

  アーカイブ後:
    1. state.md の playbook.active を null に更新
    2. 新しい playbook を作成（必要に応じて）

========================================
EOF

exit 0
