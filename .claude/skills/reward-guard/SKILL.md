# reward-guard Skill

> **Core Contract #3: Reward Fraud Prevention**
>
> 報酬詐欺（証拠なしの done 宣言）を防止する

---

## 責務

```yaml
core_contract: "#3 Reward Fraud Prevention"
rule: playbook は reviewer の PASS なしに確定しない
warn: reviewed: false の playbook には警告を表示
```

このSkillは以下を担当:
1. state: done への変更前チェック
2. subtask 完了時の 3 検証強制（technical/consistency/completeness）
3. スコープクリープの検出
4. state-playbook 整合性チェック
5. critic SubAgent による最終検証

---

## ディレクトリ構造

```
reward-guard/
├── SKILL.md              ← このファイル
├── guards/
│   ├── critic-guard.sh       ← state: done 変更前チェック
│   ├── subtask-guard.sh      ← subtask 完了時 3検証強制
│   ├── scope-guard.sh        ← スコープ変更検出
│   └── coherence.sh          ← state-playbook 整合性チェック
└── agents/
    └── critic.md             ← critic SubAgent（done_when 検証）
```

---

## 発火条件

- state: done に変更しようとした時
- subtask を完了（[x]）にしようとした時
- done_criteria/done_when を変更しようとした時
- playbook の Phase status を done に変更しようとした時
- pre-tool.sh（導火線）から呼び出される

---

## ガード一覧

| ガード | 役割 | ブロック時の動作 |
|--------|------|------------------|
| critic-guard.sh | done 変更前に critic 検証を強制 | 未検証なら BLOCK |
| subtask-guard.sh | subtask 完了時に validations 記入を強制 | 空なら BLOCK |
| scope-guard.sh | done_when/done_criteria の変更を検出 | 警告表示 |
| coherence.sh | state.md と playbook の整合性チェック | 不整合なら WARN |

---

## critic SubAgent

```yaml
role: done_when の証拠ベース検証
location: .claude/skills/reward-guard/agents/critic.md
invocation: Task(subagent_type='critic', prompt='Phase X の done_when を検証')
output:
  - judgment: PASS/FAIL
  - evidence: 各項目の検証結果
  - missing: 不足している証拠
```

---

## 使用方法

### 導火線から自動呼び出し
pre-tool.sh が Edit 検出時に state.md 変更をチェック

### 手動で critic を呼び出し
```
/crit
```

---

## 関連

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | Core Contract 定義 |
| state.md | goal.phase の確認元 |
| play/<id>/plan.json | done_when/subtasks の確認元 |
| play/<id>/progress.json | validations/evidence の確認元 |
