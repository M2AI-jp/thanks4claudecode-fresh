# Event Unit Architecture

> **Event Unit は Hook の発火タイミングを 1 ユニットとする設計パターン**

---

## 概要

Claude Code の Hook を「いつ発火するか」を境界とし、各タイミングに必要な機能をユニット内に閉じ込める。

```yaml
event_unit:
  definition: Hook の発火タイミングを 1 ユニットとする
  purpose: 関心の分離と保守性向上
  principle: 各ユニットは独立して動作可能
```

---

## Event Unit 一覧

| Unit | Hook Trigger | 役割 |
|------|--------------|------|
| session-start | SessionStart | セッション初期化、状態復元 |
| user-prompt-submit | UserPromptSubmit | プロンプト分析、ルーティング |
| pre-tool-edit | PreToolUse(Edit/Write) | 編集操作のガード |
| pre-tool-bash | PreToolUse(Bash) | Bash コマンドのガード |
| post-tool-edit | PostToolUse(Edit) | 編集完了後の処理 |
| subagent-stop | SubagentStop | SubAgent 終了時の処理 |
| pre-compact | PreCompact | コンパクション前の保存 |
| notification | Notification | 通知処理 |
| stop | Stop | 停止前の処理 |
| session-end | SessionEnd | セッション終了、クリーンアップ |

---

## 標準構造

各 Event Unit は以下の構造を持つ：

```
.claude/events/{unit-name}/
├── chain.sh          # メインエントリーポイント（必須）
├── validator.sh      # 入力の検証と整形（推奨）
├── README.md         # ユニットのドキュメント（任意）
└── handlers/         # 個別ハンドラー（任意）
    ├── handler-a.sh
    └── handler-b.sh
```

### chain.sh（必須）

Hook から呼び出されるメインスクリプト。

```bash
#!/usr/bin/env bash
# chain.sh - {unit-name} event unit
#
# Hook: {HookName}
# Purpose: {What this unit does}
#

set -euo pipefail

UNIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common library
source "$UNIT_DIR/../../lib/common.sh" 2>/dev/null || true

# Main logic
main() {
    # Validate input
    if [[ -f "$UNIT_DIR/validator.sh" ]]; then
        source "$UNIT_DIR/validator.sh"
    fi

    # Execute handlers
    # ...
}

main "$@"
```

### validator.sh（推奨）

入力データの検証と整形を行う。

```bash
#!/usr/bin/env bash
# validator.sh - Input validation for {unit-name}
#

validate_input() {
    local input="$1"

    # Validation logic
    if [[ -z "$input" ]]; then
        echo "ERROR: Input is required" >&2
        return 1
    fi

    return 0
}
```

---

## 共有ライブラリ

Event Unit 間で共有されるユーティリティ：

```
.claude/events/lib/
├── telemetry.sh     # イベント記録・メトリクス
└── common.sh        # 共通ユーティリティ（.claude/lib/common.sh を参照）
```

### telemetry.sh

イベントの記録とメトリクス収集：

```bash
source .claude/events/lib/telemetry.sh

# イベント記録
log_event "session-start" "initialized"

# メトリクス記録
record_metric "execution_time" "$duration"
```

---

## 設計原則

```yaml
principles:
  1_single_responsibility:
    rule: 各ユニットは1つの Hook タイミングのみを担当
    reason: 関心の分離、デバッグ容易性

  2_fail_safe:
    rule: validator.sh が失敗しても chain.sh は継続可能
    reason: Hook 失敗がセッション全体を壊さない

  3_idempotent:
    rule: 同じ入力に対して同じ結果を返す
    reason: 再試行安全性

  4_observable:
    rule: telemetry.sh でイベントを記録
    reason: デバッグ、監視、分析

  5_isolated:
    rule: ユニット間の直接依存を避ける
    reason: 独立テスト、独立デプロイ
```

---

## Hook との関係

```
settings.json
    │
    ├─ hooks.UserPromptSubmit.command
    │     └─→ .claude/hooks/prompt.sh
    │           └─→ .claude/events/user-prompt-submit/chain.sh
    │
    ├─ hooks.PreToolUse.command
    │     └─→ .claude/hooks/pre-tool.sh
    │           ├─→ .claude/events/pre-tool-edit/chain.sh (Edit/Write)
    │           └─→ .claude/events/pre-tool-bash/chain.sh (Bash)
    │
    └─ hooks.PostToolUse.command
          └─→ .claude/hooks/post-tool.sh
                └─→ .claude/events/post-tool-edit/chain.sh
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | Core Contract（Event Unit の定義） |
| docs/core-feature-reclassification.md | Hook Unit 依存マップ |
| .claude/hooks/*.sh | Hook エントリーポイント |
