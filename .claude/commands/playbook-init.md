---
description: 新しい playbook を作成する。pm SubAgent に委譲する。
allowed-tools: Read, Bash, Task
---

# /playbook-init

> **正規ソース: `.claude/skills/playbook-init/SKILL.md`**
>
> このコマンドは上記 Skill のエントリーポイントです。
> 詳細な仕様は正規ソースを参照してください。

---

## 概要

```
Hook(prompt.sh) → Skill(playbook-init) → pm SubAgent
                                              ↓
                                         understanding-check
                                              ↓
                                         playbook 作成
                                              ↓
                                         reviewer 検証
```

---

## 実行手順

### Step 0: 前提チェック（このコマンド/Skill が実行）

```bash
echo "=== 前提チェック ===" && \
ls plan/playbook-*.md 2>/dev/null | head -3 || echo "(playbook なし)" && \
git status --short && \
git branch --show-current
```

| 条件 | 対応 |
|------|------|
| main ブランチにいる | 作業ブランチを作成 |
| 未コミット変更がある | ユーザーに確認 |
| 既存 playbook あり | ユーザーに上書き確認 |

### Step 1: pm SubAgent に委譲（必須）

**ここから先は自分で実行してはならない。**

```
Task(
  subagent_type='pm',
  prompt='''
  ユーザーの要求: {$ARGUMENTS}
  ブランチ: {現在のブランチ名}

  以下を実行:
  1. understanding-check（5W1H 分析 + ユーザー承認）
  2. playbook 作成（context セクション含む）
  3. reviewer 検証（PASS まで）
  4. state.md 更新
  '''
)
```

---

## 禁止事項

- pm に委譲せずに自分で playbook を作成
- understanding-check をスキップ
- reviewer 検証をスキップ

---

## 参照

| ファイル | 役割 |
|----------|------|
| `.claude/skills/playbook-init/SKILL.md` | **正規ソース** |
| `.claude/skills/golden-path/agents/pm.md` | pm SubAgent |
| `.claude/skills/understanding-check/SKILL.md` | 理解確認 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-24 | V6: 正規ソースへの参照方式に変更。重複を排除。 |
| 2025-12-24 | V5: pm SubAgent 委譲方式に全面改訂。 |
