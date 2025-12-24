#!/bin/bash
# playbook-guard.sh - Edit/Write 時に playbook=null ならブロック
#
# 目的: playbook なしでのコード変更を構造的に防止
# トリガー: PreToolUse(Edit), PreToolUse(Write)
#
# 設計思想（アクションベース Guards）:
#   - プロンプトの「意図」ではなく「アクション」を制御
#   - Read/Grep/WebSearch 等は常に許可
#   - Edit/Write のみ playbook チェック
#
# ブートストラップ例外 (M-bootstrap):
#   - playbook=null でも playbook ファイル自体の作成は許可
#   - これがないと /playbook-init が動作しない（デッドロック）

set -euo pipefail

STATE_FILE="${STATE_FILE:-state.md}"

# state.md が存在しない場合はパス
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# --------------------------------------------------
# M079: コア契約は回避不可
# --------------------------------------------------
# security モードに関係なく playbook 必須チェックは維持
# CLAUDE.md Core Contract: "Playbook Gate" は常に有効
SECURITY=$(grep -A3 "^## config" "$STATE_FILE" 2>/dev/null | grep "security:" | head -1 | sed 's/security: *//' | tr -d ' ')
# 特権モードでも playbook チェックは維持（コア契約）

# stdin から JSON を読み込む
INPUT=$(cat)

# jq がない場合はスキップ
if ! command -v jq &> /dev/null; then
    exit 0
fi

# ファイルパスを取得
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# --------------------------------------------------
# 常に許可するファイル（デッドロック回避）
# --------------------------------------------------

# state.md への編集は常に許可
if [[ "$FILE_PATH" == *"state.md" ]]; then
    exit 0
fi

# --------------------------------------------------
# ブートストラップ例外: playbook ファイル自体の作成/編集は許可
# /playbook-init や pm が新規 playbook を作成できるようにする
# --------------------------------------------------
if [[ "$FILE_PATH" == *"plan/playbook-"*.md ]] || \
   [[ "$FILE_PATH" == *"plan/active/playbook-"*.md ]]; then
    exit 0
fi

# --------------------------------------------------
# playbook チェック
# --------------------------------------------------

# focus.current を取得
FOCUS=$(grep -A6 "^## focus" "$STATE_FILE" | grep "^current:" | head -1 | sed 's/current: *//' | sed 's/ *#.*//' | tr -d ' ')

# playbook セクションから active を取得
PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')

# playbook が null または空なら ブロック
if [[ -z "$PLAYBOOK" || "$PLAYBOOK" == "null" ]]; then
    # 失敗を記録（学習ループ用）
    if [[ -f ".claude/hooks/failure-logger.sh" ]]; then
        echo '{"hook": "playbook-guard", "context": "playbook=null", "action": "Edit/Write blocked"}' | bash .claude/hooks/failure-logger.sh 2>/dev/null || true
    fi

    cat >&2 << 'EOF'
========================================
  ⛔ playbook 必須
========================================

  Edit/Write には playbook が必要です。

  対処法（いずれかを実行）:

    [推奨] playbook-init Skill を呼び出す:
      Skill(skill='playbook-init')

    または /playbook-init を実行:
      /playbook-init

  現在の状態:
EOF
    echo "    focus: $FOCUS" >&2
    echo "    playbook: null" >&2
    echo "" >&2
    echo "========================================" >&2
    exit 2
fi

# playbook ファイルが存在するか確認
# M-integrity: state.md に設定されているが実ファイルがない場合はブロック
if [[ ! -f "$PLAYBOOK" ]]; then
    # 失敗を記録（学習ループ用）
    if [[ -f ".claude/hooks/failure-logger.sh" ]]; then
        echo '{"hook": "playbook-guard", "context": "playbook file not found", "action": "Edit/Write blocked"}' | bash .claude/hooks/failure-logger.sh 2>/dev/null || true
    fi

    cat >&2 << EOF
========================================
  ⛔ playbook ファイルが存在しません
========================================

  state.md に設定されている playbook:
    $PLAYBOOK

  このファイルが存在しません。
  state.md の設定と実ファイルの整合性が取れていません。

  対処法:
    1. Skill(skill='playbook-init') で正しく playbook を作成
    2. または state.md の playbook.active を null にリセット

========================================
EOF
    exit 2
fi

# reviewed フラグを取得
REVIEWED=$(grep -E "^\s*reviewed:" "$PLAYBOOK" 2>/dev/null | head -1 | sed 's/.*reviewed: *//' | sed 's/ *#.*//' | tr -d ' ')

# context セクションの存在確認
HAS_CONTEXT=$(grep -E "^context:" "$PLAYBOOK" 2>/dev/null | head -1 || echo "")

# reviewed: false または context セクションがない場合はブロック
if [[ "$REVIEWED" == "false" ]] || [[ -z "$HAS_CONTEXT" ]]; then
    # 失敗を記録（学習ループ用）
    if [[ -f ".claude/hooks/failure-logger.sh" ]]; then
        echo '{"hook": "playbook-guard", "context": "reviewed=false or no context", "action": "Edit/Write blocked"}' | bash .claude/hooks/failure-logger.sh 2>/dev/null || true
    fi

    cat >&2 << 'EOF'
========================================
  ⛔ playbook 未承認
========================================

  reviewed: false または context セクションがありません。
  実装を開始する前に以下が必要です：

  1. 理解確認（Step 1.5）:
     - 5W1H 分析を実行
     - AskUserQuestion でユーザー承認を取得
     - context セクションに記録

  2. Reviewer 検証（Step 6）:
     - Task(subagent_type='reviewer') を呼び出し
     - PASS 後に reviewed: true に更新

  対処法:
    Skill(skill='playbook-init') を再実行

========================================
EOF
    exit 2
fi

# playbook があり、reviewed: true かつ context ありならパス
exit 0
