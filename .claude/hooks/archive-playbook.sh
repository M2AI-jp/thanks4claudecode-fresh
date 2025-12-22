#!/bin/bash
# archive-playbook.sh - playbook 完了時の自動アーカイブ提案
#
# 発火条件: PostToolUse:Edit
# 目的: playbook の全 Phase が done になったら plan/archive/ に移動を提案
#
# 設計思想（2025-12-09 改善）:
#   - playbook 完了を自動検出
#   - 移動は提案のみ（自動実行しない）★安全側設計
#   - Claude が POST_LOOP で実行（CLAUDE.md 行動 0.5）
#   - 現在進行中の playbook（state.md playbook.active）はアーカイブ対象外
#
# 実行経路:
#   1. playbook を Edit → このスクリプト発火
#   2. 全 Phase done を検出 → 「アーカイブ推奨」を出力
#   3. Claude が POST_LOOP に入る
#   4. POST_LOOP 行動 0.5 で mv 実行
#
# 参照: docs/archive-operation-rules.md

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

# playbook 内の Phase status を確認
# 全ての status: が done であるかチェック
TOTAL_PHASES=$(grep -c "^  status:" "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
DONE_PHASES=$(grep "^  status: done" "$FILE_PATH" 2>/dev/null | wc -l | tr -d ' \n')
# 空の場合は 0 に設定
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
# V12: チェックボックス形式の完了判定
# ==============================================================================
# `- [x]` の数と `- [ ]` の数をカウントして完了率を確認
# ==============================================================================
CHECKED_COUNT=$(grep -c '\- \[x\]' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
UNCHECKED_COUNT=$(grep -c '\- \[ \]' "$FILE_PATH" 2>/dev/null | head -1 | tr -d ' \n' || echo "0")
# 空の場合は 0 に設定
CHECKED_COUNT=${CHECKED_COUNT:-0}
UNCHECKED_COUNT=${UNCHECKED_COUNT:-0}
TOTAL_CHECKBOX=$((CHECKED_COUNT + UNCHECKED_COUNT))

if [ "$TOTAL_CHECKBOX" -gt 0 ]; then
    if [ "$UNCHECKED_COUNT" -gt 0 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ⚠️ 未完了の subtask があります（V12 形式）"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  完了: $CHECKED_COUNT / 未完了: $UNCHECKED_COUNT"
        echo ""
        echo "  全ての subtask を完了させてください:"
        echo "  - [ ] → - [x] に変更"
        echo "  - validations を追加"
        echo "  - validated タイムスタンプを追加"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 0  # 未完了があれば提案しない
    fi
fi

# M019: final_tasks チェック（存在する場合のみ）
# playbook に final_tasks セクションがある場合、全て完了しているか確認
# V12 形式: `- [x] **ft1**` でチェック
if grep -q "^## final_tasks" "$FILE_PATH" 2>/dev/null; then
    # V12 形式: チェックボックスでカウント
    TOTAL_FINAL_TASKS=$(grep -A 100 "^## final_tasks" "$FILE_PATH" | grep -c '\- \[.\] \*\*ft' 2>/dev/null || echo "0")
    DONE_FINAL_TASKS=$(grep -A 100 "^## final_tasks" "$FILE_PATH" | grep -c '\- \[x\] \*\*ft' 2>/dev/null || echo "0")

    # V11 形式（フォールバック）: status: done でカウント
    if [ "$TOTAL_FINAL_TASKS" -eq 0 ]; then
        TOTAL_FINAL_TASKS=$(awk '/^final_tasks:/,/^[a-z_]+:/' "$FILE_PATH" | grep -c "^ *- " 2>/dev/null || echo "0")
        DONE_FINAL_TASKS=$(awk '/^final_tasks:/,/^[a-z_]+:/' "$FILE_PATH" | grep -c "status: done" 2>/dev/null || echo "0")
    fi

    if [ "$TOTAL_FINAL_TASKS" -gt 0 ] && [ "$DONE_FINAL_TASKS" -lt "$TOTAL_FINAL_TASKS" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ⚠️ final_tasks が未完了です"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  完了: $DONE_FINAL_TASKS / $TOTAL_FINAL_TASKS"
        echo "  → final_tasks を全て完了してからアーカイブしてください"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 0
    fi
fi

# 現在進行中の playbook（state.md playbook.active）かチェック
# 進行中ならアーカイブ提案しない（安全策）
ACTIVE_PLAYBOOK=$(grep -A 5 "^## playbook" state.md 2>/dev/null | grep "^active:" | head -1 | sed 's/active: *//' | tr -d ' ')
if [ -n "$ACTIVE_PLAYBOOK" ] && [ "$ACTIVE_PLAYBOOK" != "null" ]; then
    if echo "$ACTIVE_PLAYBOOK" | grep -q "$(basename "$FILE_PATH")"; then
        # 現在進行中なのでスキップ（完了後に再度発火する）
        exit 0
    fi
fi

# ==============================================================================
# M056: done_when 再検証（報酬詐欺防止）
# ==============================================================================
# playbook の goal.done_when を抽出し、p_final の validations が全て PASS か検証
# 全 PASS でなければアーカイブをブロック

DONE_WHEN_SECTION=$(sed -n '/^done_when:/,/^[a-z_]*:/p' "$FILE_PATH" 2>/dev/null | grep "^  - " | head -10)
# M086 修正: grep -c 失敗時のフォールバックを修正（二重出力防止）
DONE_WHEN_COUNT=$(echo "$DONE_WHEN_SECTION" | grep -c "^  - " 2>/dev/null) || DONE_WHEN_COUNT=0

if [ "$DONE_WHEN_COUNT" -gt 0 ]; then
    # p_final Phase の存在チェック
    if ! grep -q "p_final" "$FILE_PATH" 2>/dev/null; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ⚠️ p_final（完了検証フェーズ）が存在しません"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  done_when: $DONE_WHEN_COUNT 項目"
        echo ""
        echo "  playbook に p_final フェーズを追加してください。"
        echo "  参照: plan/template/playbook-format.md"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        # 警告のみ（ブロックしない）- 既存 playbook との互換性のため
    fi

    # p_final Phase の status チェック
    P_FINAL_STATUS=$(grep -A 30 "p_final" "$FILE_PATH" 2>/dev/null | grep "^status:" | head -1 | sed 's/status: *//')
    if [ -n "$P_FINAL_STATUS" ] && [ "$P_FINAL_STATUS" != "done" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ❌ p_final（完了検証）が未完了です"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  done_when の検証: status = $P_FINAL_STATUS"
        echo ""
        echo "  p_final を完了させてからアーカイブしてください。"
        echo "  → done_when の各項目が実際に満たされているか検証"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 2  # done_when 未検証でブロック
    fi

    # validations の PASS チェック（V15: validations ベース）
    # p_final セクション内の subtask が全て [x]（完了）になっているか確認
    P_FINAL_SECTION=$(grep -A 100 "p_final" "$FILE_PATH" 2>/dev/null | head -100)
    INCOMPLETE_SUBTASKS=$(echo "$P_FINAL_SECTION" | grep -c '\- \[ \]' 2>/dev/null || echo "0")
    COMPLETE_SUBTASKS=$(echo "$P_FINAL_SECTION" | grep -c '\- \[x\]' 2>/dev/null || echo "0")

    if [ "$INCOMPLETE_SUBTASKS" -gt 0 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  ❌ p_final の subtasks が未完了です"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  完了: $COMPLETE_SUBTASKS / 未完了: $INCOMPLETE_SUBTASKS"
        echo ""
        echo "  アーカイブをブロックします。"
        echo "  → 全ての p_final subtasks を完了させてください。"
        echo "  → validations（3点検証）が全て PASS である必要があります。"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 2  # subtasks 未完了でブロック
    fi
fi

# 相対パスに変換
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RELATIVE_PATH="${FILE_PATH#$PROJECT_DIR/}"

# playbook 名を取得
PLAYBOOK_NAME=$(basename "$FILE_PATH")

# アーカイブ先を決定
ARCHIVE_DIR="plan/archive"
ARCHIVE_PATH="$ARCHIVE_DIR/$PLAYBOOK_NAME"

# 全 Phase が done の場合、アーカイブを提案
cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📦 Playbook 完了検出
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Playbook: $RELATIVE_PATH
  Status: 全 $TOTAL_PHASES Phase が done

  アーカイブを推奨します:
    mkdir -p $ARCHIVE_DIR
    mv $RELATIVE_PATH $ARCHIVE_PATH

  アーカイブ後:
    1. state.md の playbook.active を null に更新
    2. 新しい playbook を作成（必要に応じて）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

# ==============================================================================
# M088: 全 milestone achieved 検知（project_complete workflow）
# ==============================================================================
# playbook 完了時に project.md を参照し、全 milestone が achieved なら
# project_complete メッセージを出力

PROJECT_FILE="plan/project.md"

if [ -f "$PROJECT_FILE" ]; then
    # milestone 総数と未達成数をカウント（より正確な方法）
    TOTAL_MILESTONES=$(grep -c "^- id: M" "$PROJECT_FILE" 2>/dev/null) || TOTAL_MILESTONES=0
    # pending または in_progress の milestone がないことを確認
    PENDING_MILESTONES=$(grep -c "status: pending\|status: in_progress" "$PROJECT_FILE" 2>/dev/null) || PENDING_MILESTONES=0

    # milestone が存在し、未達成がない場合 = 全 milestone achieved
    if [ "$TOTAL_MILESTONES" -gt 0 ] && [ "$PENDING_MILESTONES" -eq 0 ]; then
        cat << 'PROJECTCOMPLETE'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🎉 PROJECT COMPLETE - 全 Milestone 達成
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  全ての Milestone が achieved になりました。

  次のアクションを実行してください:

  1. PR をマージ:
     gh pr merge --merge --delete-branch

  2. main ブランチを pull:
     git checkout main && git pull

  3. GitHub にプッシュ（必要に応じて）:
     git push origin main

  4. state.md を neutral 状態に:
     playbook.active: null
     focus.current: null

  おめでとうございます！

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROJECTCOMPLETE
    fi
fi

exit 0
