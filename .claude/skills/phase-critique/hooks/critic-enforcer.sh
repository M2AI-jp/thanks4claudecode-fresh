#!/bin/bash
# ==============================================================================
# critic-enforcer.sh - Phase 完了への変更を構造的にブロック（強化版）
# ==============================================================================
# 目的: critic PASS なしで Phase を完了にすることを防止
# トリガー: PreToolUse(Edit)
#
# 設計思想:
#   - 自己報酬詐欺（証拠なしでの完了申告）を構造的に防止
#   - critic SubAgent による評価を強制
#   - Phase に critic_approved: true フラグで PASS を記録
#
# 動作:
#   1. 編集対象が playbook ファイルかチェック
#   2. new_string に "**status**: done" が含まれるかチェック
#   3. old_string が "**status**: pending" または "**status**: in_progress" かチェック
#   4. Phase に critic_approved: true がなければブロック（exit 2）
#
# 根拠: SKILL.md「Phase 完了時の critic 評価を強制する」
# ==============================================================================

set -uo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# tool_input から情報を取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
OLD_STRING=$(echo "$INPUT" | jq -r '.tool_input.old_string // ""')
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // ""')

# playbook ファイル以外は対象外
if [[ "$FILE_PATH" != *"/plan/playbook-"* ]]; then
    exit 0
fi

# "**status**: done" を含まない編集は対象外
if ! echo "$NEW_STRING" | grep -qE "\*\*status\*\*:[[:space:]]*done"; then
    exit 0
fi

# old_string が pending または in_progress から done への変更でなければ対象外
# （既に done だったものを再編集するのは許可）
if ! echo "$OLD_STRING" | grep -qE "\*\*status\*\*:[[:space:]]*(pending|in_progress)"; then
    exit 0
fi

# Phase の critic_approved: true が new_string に含まれるかチェック
# new_string 内に critic_approved: true があればOK（同時に追加するケース）
# パターン: "**critic_approved**: true" または "critic_approved: true"
if echo "$NEW_STRING" | grep -qE "(\*\*)?critic_approved(\*\*)?:[[:space:]]*true"; then
    # critic PASS 済み - 編集を許可
    exit 0
fi

# ファイルが存在する場合、既存の Phase に critic_approved があるかチェック
if [ -f "$FILE_PATH" ]; then
    # Phase メタデータ行のみをチェック（validation 内のテキストは除外）
    # パターン: 行頭から始まる "**critic_approved**: true" のみマッチ
    if grep -qE "^\*\*critic_approved\*\*:[[:space:]]*true" "$FILE_PATH" 2>/dev/null; then
        # critic PASS 済み（既存の Phase に承認がある）
        exit 0
    fi
fi

# ------------------------------------------------------------------
# ブロック: critic PASS なしで Phase を done に変更しようとしている
# ------------------------------------------------------------------

cat >&2 << 'EOF'
========================================
  [critic-enforcer] Phase 完了ブロック
========================================

  Phase の **status**: done への変更には critic PASS が必要です。

  対処法（順番に実行）:

    1. この Phase の全 subtask を完了させる
       - 各 subtask の validations (3点検証) を記入
       - チェックボックスを [x] に変更

    2. critic SubAgent を呼び出す:
       Task(subagent_type='critic',
            prompt='Phase の subtasks を評価。
            .claude/skills/phase-critique/frameworks/done-criteria-validation.md を参照')
       または /crit

    3. critic が PASS を返したら:
       Phase に critic_approved: true を追加
       例:
       **status**: done
       **critic_approved**: true

    4. 再度 **status**: done に変更

  評価基準（5項目）:
    1. 根拠の有無 - done_criteria の導出元が明確
    2. 検証可能性 - コマンドで確認可能
    3. 計画との整合性 - Phase の goal と整合
    4. 報酬詐欺の検出 - 証拠なしの完了申告を拒否
    5. 証拠の品質 - 具体的な実行結果を示す

  参照:
    - .claude/skills/phase-critique/SKILL.md
    - .claude/skills/phase-critique/frameworks/done-criteria-validation.md
    - .claude/skills/phase-critique/agents/critic.md

========================================
EOF

exit 2
