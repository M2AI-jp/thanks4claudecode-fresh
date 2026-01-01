---
description: playbook + コードレビューを実行。reviewer/critic SubAgent に委譲。
allowed-tools: Read, Bash, Task
---

# /review - レビュー自動ループ

> **この処理は reviewer/critic SubAgent に委譲される。直接レビューを実行してはならない。**

---

## アーキテクチャ

```
Skill(/review)
    │
    ├─→ [playbook review] reviewer SubAgent
    │        ↓
    │   PASS/FAIL 判定
    │
    └─→ [code review] critic SubAgent + coderabbit
             ↓
        PASS/FAIL 判定
```

---

## 使用方法

```bash
# playbook レビューのみ
/review playbook

# コードレビューのみ
/review code

# 両方（デフォルト）
/review
/review all
```

---

## 実行手順

### Step 1: レビュー対象を判定

```yaml
mode:
  playbook: reviewer SubAgent を呼び出し
  code: critic SubAgent + coderabbit を呼び出し
  all: 両方を順次実行
```

### Step 2a: Playbook Review（mode = playbook or all）

```
Task:
  subagent_type: reviewer
  prompt: |
    現在の playbook をレビューしてください。

    対象: state.md の playbook.active
    基準: .claude/frameworks/playbook-review-criteria.md

    手順:
    1. 4QV+ フレームワークでレビュー
    2. PASS/FAIL を判定
    3. FAIL の場合は修正点を報告
```

### Step 2b: Code Review（mode = code or all）

```
Task:
  subagent_type: critic
  prompt: |
    現在の Phase のコード変更をレビューしてください。

    対象: git diff で変更されたファイル
    基準: .claude/frameworks/done-criteria-validation.md

    手順:
    1. 3点検証（technical/consistency/completeness）
    2. PASS/FAIL を判定
    3. FAIL の場合は修正点を報告
```

### Step 3: ループ制御

```yaml
max_iterations: 3

flow:
  1: レビュー実行
  2: FAIL なら修正して再レビュー
  3: 3回 FAIL でユーザー確認

on_max_fail:
  action: ask_user
  options:
    - label: "強制終了"
      description: "レビューを打ち切る（非推奨）"
    - label: "継続"
      description: "さらに修正を試みる"
    - label: "スキップ"
      description: "レビューをスキップして次へ"
```

---

## 禁止事項

```yaml
禁止:
  - reviewer/critic SubAgent を呼ばずに自分でレビューする
  - 証拠なしに PASS と判定する
  - max_iterations を超えて無限ループする

必須:
  - SubAgent への委譲
  - 3点検証（technical/consistency/completeness）
  - 証拠ベースの判定
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| .claude/skills/quality-assurance/agents/reviewer.md | reviewer SubAgent 定義 |
| .claude/skills/reward-guard/agents/critic.md | critic SubAgent 定義 |
| .claude/frameworks/playbook-review-criteria.md | playbook レビュー基準 |
| .claude/frameworks/done-criteria-validation.md | コードレビュー基準 |
