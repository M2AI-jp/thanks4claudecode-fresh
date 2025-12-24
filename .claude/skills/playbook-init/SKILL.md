---
name: playbook-init
description: タスク開始フローのエントリーポイント。pm SubAgent への委譲を強制し、Hook → Skill → SubAgent チェーンを実現する。
---

# playbook-init Skill

> **このSkillは pm SubAgent への委譲を強制する。自分で処理してはならない。**

---

## Purpose

Hook → Skill → SubAgent チェーンの Skill 層を担当。
ユーザーからのタスク依頼を受け、pm SubAgent に委譲する。

---

## When to Use

```yaml
triggers:
  - prompt.sh（導火線）から呼び出される
  - playbook=null の状態でタスク依頼を受けた時
  - "作って/実装して/修正して/追加して" 等のタスク要求パターン

invocation:
  - Skill(skill='playbook-init')
  - /playbook-init
```

---

## Required Action

**即座に以下を実行せよ。それ以外の行動は禁止。**

### Step 0: 前提チェック（自分で実行）

```bash
echo "=== 前提チェック ===" && \
echo "1. 既存 playbook:" && ls plan/playbook-*.md 2>/dev/null | head -3 || echo "(なし)" && \
echo "2. git 状態:" && git status --short && \
echo "3. ブランチ:" && git branch --show-current
```

| 条件 | 対応 |
|------|------|
| 未コミット変更がある | ユーザーに確認 |
| main ブランチにいる | 作業ブランチを作成 |
| 既存 playbook あり | ユーザーに上書き確認 |

### Step 1: pm SubAgent に委譲（必須）

```
Task(
  subagent_type='pm',
  prompt='''
  ユーザーの要求: {ユーザーの元のプロンプト}
  ブランチ: {現在のブランチ名}

  以下を実行してください:
  1. understanding-check（5W1H 分析 + ユーザー承認）
  2. playbook 作成（context セクション含む）
  3. reviewer 検証（PASS まで）
  4. state.md 更新
  '''
)
```

---

## Prohibited

```yaml
禁止:
  - pm SubAgent を呼ばずに自分で playbook を作成
  - understanding-check をスキップ
  - reviewer 検証をスキップ
  - Step 0 の前提チェックをスキップ

必須:
  - pm SubAgent への委譲
  - ユーザー承認の取得（understanding-check 内で）
```

---

## Chain Position

```
Hook(prompt.sh)
    │
    │ playbook=null を検出
    │ 「Skill(skill='playbook-init') を呼べ」と指示
    │
    ▼
Skill(playbook-init)  ← このファイル
    │
    │ 前提チェック後、pm SubAgent に委譲
    │
    ▼
pm SubAgent
    │
    ├─→ understanding-check（5W1H 分析）
    ├─→ playbook 作成
    ├─→ reviewer 検証
    └─→ state.md 更新
```

---

## Related Files

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | Core Contract 定義（Golden Path） |
| .claude/hooks/prompt.sh | 導火線（State Injection） |
| .claude/skills/golden-path/agents/pm.md | pm SubAgent |
| .claude/skills/understanding-check/SKILL.md | 理解確認フレームワーク |
| .claude/skills/quality-assurance/agents/reviewer.md | reviewer SubAgent |
