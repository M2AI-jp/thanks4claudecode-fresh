---
description: done_criteria の達成状況を CRITIQUE する。critic SubAgent に委譲。
allowed-tools: Read, Bash, Task
---

# /crit - done_criteria の達成状況チェック

> **この処理は critic SubAgent に委譲される。直接 CRITIQUE を実行してはならない。**

---

## アーキテクチャ

```
Skill(/crit) → critic SubAgent → lint-checker/test-runner Skills
                    ↓
              CRITIQUE 結果出力
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

---

## 禁止事項

```yaml
禁止:
  - critic SubAgent を呼ばずに自分で CRITIQUE する
  - 証拠なしに PASS と判定する
  - Skills（lint-checker, test-runner）をスキップする

必須:
  - critic SubAgent への委譲
  - 3点検証（technical/consistency/completeness）
  - 証拠ベースの判定
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| .claude/skills/reward-guard/agents/critic.md | critic SubAgent 定義 |
| .claude/frameworks/done-criteria-validation.md | 評価フレームワーク |
