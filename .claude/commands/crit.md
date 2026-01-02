---
description: done_criteria の達成状況を CRITIQUE する。critic + codex 二段検証。
allowed-tools: Read, Bash, Task
---

# /crit - done_criteria の達成状況チェック

> **この Skill は複数 SubAgent をオーケストレーションする。直接 CRITIQUE を実行してはならない。**

---

## アーキテクチャ

```
Skill(/crit)
    │
    ├─→ Step 1: critic SubAgent（自己評価）
    │       └─→ lint-checker/test-runner Skills
    │       └─→ CRITIQUE 結果出力
    │
    ├─→ Step 2: codex-delegate SubAgent（独立検証）
    │       └─→ mcp__codex__codex（コンテキスト分離）
    │       └─→ 独立 PASS/FAIL 判定
    │
    └─→ Step 3: 最終判定統合
            └─→ critic PASS + codex PASS → 総合 PASS
            └─→ どちらか FAIL → 総合 FAIL
```

---

## 実行手順

### Step 1: critic SubAgent 呼び出し（必須）

```
Task:
  subagent_type: critic
  prompt: |
    現在の playbook の done_criteria を CRITIQUE してください。

    手順:
    1. state.md から playbook を取得
    2. 各 subtask の validations（3点検証）を評価
    3. PASS/FAIL を判定し、証拠を提示

    参照: .claude/skills/reward-guard/agents/critic.md
```

### Step 2: codex-delegate SubAgent 呼び出し（必須）

> **コンテキスト分離による独立検証**
>
> critic（Claude）と同じバイアスを共有しないため、より厳しい評価が期待できる

```
Task:
  subagent_type: codex-delegate
  prompt: |
    以下の done_criteria と証拠を独立検証してください。
    「空気を読まず」厳しく判定してください。
    疑わしい場合は FAIL としてください。

    done_criteria:
      {state.md の goal.done_criteria を貼り付け}

    証拠:
      {critic の出力から証拠を貼り付け}

    判定: PASS または FAIL（理由付き）
```

### Step 3: 最終判定統合

```yaml
判定ルール:
  critic PASS + codex PASS: 総合 PASS
  critic PASS + codex FAIL: 総合 FAIL（codex の理由を採用）
  critic FAIL: 総合 FAIL（codex 呼び出し不要）

出力フォーマット:
  [最終判定]
  critic: PASS/FAIL
  codex:  PASS/FAIL
  総合:   PASS/FAIL

  理由: ...
```

---

## 禁止事項

```yaml
禁止:
  - critic SubAgent を呼ばずに自分で CRITIQUE する
  - codex-delegate を呼ばずに PASS と判定する
  - 証拠なしに PASS と判定する
  - Skills（lint-checker, test-runner）をスキップする

必須:
  - critic SubAgent → codex-delegate SubAgent の順序で呼び出し
  - 3点検証（technical/consistency/completeness）
  - 二段検証（自己評価 + 独立検証）の両方 PASS
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| .claude/skills/reward-guard/agents/critic.md | critic SubAgent（自己評価） |
| .claude/skills/golden-path/agents/codex-delegate.md | codex-delegate SubAgent（独立検証） |
| .claude/frameworks/done-criteria-validation.md | 評価フレームワーク |
