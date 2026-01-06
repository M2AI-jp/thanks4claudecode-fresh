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

# stdin から JSON を読み込む（タイムアウト付き）
# Hook タイムアウト（10秒）の半分を使用し、残りを処理に充てる
if ! INPUT=$(timeout 5 cat 2>/dev/null); then
    echo "[WARN] stdin read timeout - skipping check" >&2
    exit 0
fi

# jq がない場合はブロック（Fail-closed）
if ! command -v jq &> /dev/null; then
    cat >&2 << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⛔ jq 未インストール - セキュリティチェック不可
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
jq はセキュリティガードに必須です。
Install: brew install jq
EOF
    exit 2
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

# playbook v2 (JSON) の作成/更新は playbook=null でも許可
# pm が plan/progress を生成できるようにする（デッドロック回避）
if [[ "$FILE_PATH" == *"/play/"*"/plan.json" ]]; then
    TARGET_DIR=$(dirname "$FILE_PATH")
    OTHER_PLAYBOOKS=$(find play -maxdepth 2 -name "plan.json" \
        ! -path "*/archive/*" ! -path "*/template/*" \
        ! -path "$TARGET_DIR/plan.json" 2>/dev/null | head -5)

    if [[ -n "$OTHER_PLAYBOOKS" ]]; then
        cat >&2 << EOF
========================================
  ⚠️ 既存 playbook が残っています
========================================

  新規 playbook を作成しようとしていますが、
  play/ に他の playbook が残っています:

$(echo "$OTHER_PLAYBOOKS" | sed 's/^/    /')

  これらは以下のいずれかを実行してください:
    1. 完了させてからアーカイブ（play/archive/ へ移動）
    2. 不要であれば手動で削除/退避

  → 作成は許可しますが、orphan を放置しないでください。

========================================
EOF
    fi
    exit 0
fi

if [[ "$FILE_PATH" == *"/play/"*"/progress.json" ]]; then
    exit 0
fi

# --------------------------------------------------
# legacy playbook (plan/playbook-*.md) は禁止
# --------------------------------------------------
if [[ "$FILE_PATH" == *"plan/playbook-"*.md ]]; then
    cat >&2 << 'EOF'
========================================
  ⛔ legacy playbook は使用禁止
========================================

  旧 plan/playbook-*.md は廃止されています。
  play/<id>/plan.json + progress.json を使用してください。

  対処法:
    Skill(skill='playbook-init') で playbook v2 を生成

========================================
EOF
    exit 2
fi

# --------------------------------------------------
# playbook チェック
# --------------------------------------------------

# playbook セクションから active を取得
PLAYBOOK=$(grep -A6 "^## playbook" "$STATE_FILE" | grep "^active:" | head -1 | sed 's/active: *//' | sed 's/ *#.*//' | tr -d ' ')

# playbook が null または空なら ブロック
if [[ -z "$PLAYBOOK" || "$PLAYBOOK" == "null" ]]; then
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
    echo "    playbook: null" >&2
    echo "" >&2
    echo "========================================" >&2
    exit 2
fi

# playbook ファイルが存在するか確認
# M-integrity: state.md に設定されているが実ファイルがない場合はブロック
if [[ ! -f "$PLAYBOOK" ]]; then
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

# JSON playbook (v2) の場合は jq で検証
if [[ "$PLAYBOOK" == *.json ]]; then
    if ! command -v jq &> /dev/null; then
        cat >&2 << 'EOF'
========================================
  ⛔ jq 未インストール - playbook 検証不可
========================================

JSON playbook の検証に jq が必要です。
Install: brew install jq

========================================
EOF
        exit 2
    fi

    if ! jq -e . "$PLAYBOOK" >/dev/null 2>&1; then
        cat >&2 << EOF
========================================
  ⛔ playbook JSON が不正
========================================

  playbook: $PLAYBOOK
  JSON として解析できません。

========================================
EOF
        exit 2
    fi

    REVIEWED=$(jq -r '.meta.reviewed // false' "$PLAYBOOK")
    HAS_CONTEXT=$(jq -e '.context' "$PLAYBOOK" >/dev/null && echo "true" || echo "")
    REVIEWED_BY=$(jq -r '.meta.reviewed_by // ""' "$PLAYBOOK")

    if [[ "$REVIEWED" != "true" ]] || [[ -z "$HAS_CONTEXT" ]]; then
        cat >&2 << 'EOF'
========================================
  ⛔ playbook 未承認
========================================

  meta.reviewed: true と context が必要です。
  実装を開始する前に以下が必要です：

  1. 理解確認（Step 1.5）:
     - 5W1H 分析を実行
     - AskUserQuestion でユーザー承認を取得
     - context に記録

  2. Reviewer 検証（Step 6）:
     - Task(subagent_type='reviewer') を呼び出し
     - PASS 後に meta.reviewed: true に更新

  対処法:
    Skill(skill='playbook-init') を再実行

========================================
EOF
        exit 2
    fi

    # reviewed_by が自己レビューに見える場合は警告のみ
    if [[ -z "$REVIEWED_BY" ]] || [[ "$REVIEWED_BY" == *"pm"* ]] || [[ "$REVIEWED_BY" == *"self"* ]]; then
        cat >&2 << EOF
[WARN] reviewed_by が独立レビューに見えません: "$REVIEWED_BY"
       reviewer SubAgent の結果で reviewed_by を更新してください。
EOF
    fi

    exit 0
fi

# reviewed フラグを取得（legacy markdown）
REVIEWED=$(grep -E "^\s*reviewed:" "$PLAYBOOK" 2>/dev/null | head -1 | sed 's/.*reviewed: *//' | sed 's/ *#.*//' | tr -d ' ')

# context セクションの存在確認
HAS_CONTEXT=$(grep -E "^## context" "$PLAYBOOK" 2>/dev/null | head -1 || echo "")

# reviewed: false または context セクションがない場合はブロック
if [[ "$REVIEWED" == "false" ]] || [[ -z "$HAS_CONTEXT" ]]; then
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
