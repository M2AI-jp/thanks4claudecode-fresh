---
description: セッション完全初期化。state.md + rules + playbook + toolstack を読み込む。
allowed-tools: Read, Bash, Grep
---

# /init - セッション完全初期化

> **新規セッション開始時の完全な状態復元コマンド**

---

## 目的

```yaml
purpose: |
  コンテキストリセット後に必要な情報を一括読み込み。
  手動で複数ファイルを Read する手間を省く。
```

---

## 実行手順

### Step 1: state.md 読み込み

```
Read: state.md

確認項目:
  - playbook.active
  - config.toolstack
  - config.roles
  - goal.phase
```

### Step 2: .claude/rules/ 読み込み

```yaml
順序:
  1: .claude/rules/README.md
  2: .claude/rules/coding.md
  3: .claude/rules/testing.md
  4: .claude/rules/operations.md
```

### Step 3: playbook 読み込み（存在する場合）

```
条件: state.md の playbook.active != null

Read: {playbook.active}

確認項目:
  - 現在の phase
  - 未完了の subtasks
  - done_criteria
```

### Step 4: toolstack 確認

```yaml
toolstack_check:
  A: claudecode only
  B: +codex
  C: +codex +coderabbit

role_resolution:
  A:
    worker: claudecode
    reviewer: claudecode
  B:
    worker: codex
    reviewer: claudecode
  C:
    worker: codex
    reviewer: coderabbit
```

### Step 5: 状態サマリー出力

```yaml
output:
  - 現在のブランチ
  - アクティブな playbook
  - 現在の phase
  - toolstack と roles
  - 次のアクション
```

---

## 使用例

```bash
# セッション開始時
/init

# コンテキストリセット後
/init

# 状態確認
/init --status
```

---

## 出力例

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [INIT] セッション初期化完了
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  📋 playbook: plan/playbook-ops-improvement.md
  🔄 phase: p1
  🌿 branch: feat/ops-improvement
  🛠️ toolstack: C (codex + coderabbit)

  📝 次のアクション:
    - p1.1: settings.json タイムアウト値調査

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| state.md | 現在状態（SSOT） |
| .claude/rules/ | 詳細ルール |
| CLAUDE.md | 憲法（Core Contract） |
