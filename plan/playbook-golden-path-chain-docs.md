# playbook-golden-path-chain-docs.md

## meta

```yaml
project: golden-path-chain-docs
branch: fix/golden-path-chain-docs
created: 2025-12-24
issue: null
reviewed: true
roles:
  worker: claudecode
```

---

## context

### 5W1H 分析

| 項目 | 内容 |
|------|------|
| What | Golden Path の Hook→Skill→SubAgent チェーン強制を正しくドキュメント化 |
| Why | CLAUDE.md の記述が誤解を招き、直接 Task(pm) を呼ぶ動作を誘発している |
| Who | Claude (LLM) がドキュメントを読んで正しい動作をするため |
| When | 今回のセッションで完了 |
| Where | CLAUDE.md, golden-path/SKILL.md, 4qv-architecture.md |
| How | 矛盾箇所を修正し、正しいフローを明記 |

### リスク分析

| リスク | 確率 | 影響 | 対策 |
|--------|------|------|------|
| CLAUDE.md 変更には Change Control が必要 | high | high | 手順に従う |
| 複数ファイルの整合性が崩れる | medium | medium | 全ファイルを同時に修正 |

### 確認事項

- 正となる期待動作: Hook → Skill(playbook-init) → pm SubAgent
- 禁止事項: Task(pm) を直接呼ぶ
- CLAUDE.md 修正には Change Control 必須

### ロールバック手順

1. `git revert` で該当コミットを取り消し
2. PROMPT_CHANGELOG.md に revert 理由を記録
3. Version 番号は変更しない（revert なので）

### 承認

```yaml
approved_at: 2025-12-24
approved_by: user (implicit - task request)
```

---

## goal

```yaml
summary: Golden Path ドキュメントの矛盾を解消し、Hook→Skill→SubAgent チェーンを正しく強制する
done_when:
  - CLAUDE.md Section 11 に "Skill(playbook-init)" の記述がある（grep で検証可能）
  - golden-path/SKILL.md に "Task(subagent_type='pm'" の直接呼び出し記述がない（grep で検証可能）
  - 4qv-architecture.md の "Task(subagent_type='pm') は動作しない" という誤った記述が削除または修正されている
  - governance/PROMPT_CHANGELOG.md に [1.2.0] エントリが存在する
```

---

## phases

### p1: Change Control 準備

**goal**: CLAUDE.md 変更のための Change Control 手順を実行

#### subtasks

- [ ] **p1.1**: governance/PROMPT_CHANGELOG.md に [1.2.0] エントリを追加
  - executor: claudecode
  - validations:
    - technical: "## [1.2.0] - 2025-12-24 セクションが存在する"
    - consistency: "Changed セクションに Section 11 の変更内容が記載されている"
    - completeness: "Rationale（理由）と Verification（検証方法）が含まれている"

**status**: pending
**max_iterations**: 3

---

### p2: CLAUDE.md 修正

**goal**: Section 11 の golden_path.action を修正

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: CLAUDE.md Section 11 の golden_path.action を修正
  - old: `Task(subagent_type='pm', prompt='playbook を作成')`
  - new: `Skill(skill='playbook-init')` を呼ぶ
  - executor: claudecode
  - validations:
    - technical: "CLAUDE.md に Skill(playbook-init) の記述がある"
    - consistency: "Hook→Skill→SubAgent チェーンが明記されている"
    - completeness: "直接 Task(pm) 禁止が明記されている"

- [ ] **p2.2**: CLAUDE.md Version を 1.2.0 に更新
  - executor: claudecode
  - validations:
    - technical: "Version: 1.2.0 が記載されている"
    - consistency: "Last Updated が今日の日付"
    - completeness: "Version History に新エントリがある"

**status**: pending
**max_iterations**: 5

---

### p3: 関連ドキュメント修正

**goal**: golden-path/SKILL.md と 4qv-architecture.md を修正

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: golden-path/SKILL.md の「SubAgent 経由」セクション削除/修正
  - executor: claudecode
  - validations:
    - technical: "Task(subagent_type='pm') の直接呼び出し記述がない"
    - consistency: "Skill 経由のフローが明記されている"
    - completeness: "発火条件が正しく記述されている"

- [ ] **p3.2**: 4qv-architecture.md の古い情報を更新
  - executor: claudecode
  - validations:
    - technical: "Task(subagent_type='pm') は動作しない記述が削除/修正されている"
    - consistency: "現在の SubAgent 一覧と整合している"
    - completeness: "Hook→Skill→SubAgent フローが正しく記述されている"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が満たされているか最終検証

**depends_on**: [p3]

#### subtasks

- [ ] **p_final.1**: CLAUDE.md が Skill 経由を明記している
  - executor: claudecode
  - validations:
    - technical: "grep で Skill(playbook-init) が見つかる"
    - consistency: "Section 11 の action が正しい"
    - completeness: "禁止事項も明記されている"

- [ ] **p_final.2**: 全ドキュメントの整合性確認
  - executor: claudecode
  - validations:
    - technical: "矛盾する記述がない"
    - consistency: "全ファイルが同じフローを記述している"
    - completeness: "Change Control 手順が完了している"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: lint_prompts.py を実行
  - command: `python3 scripts/lint_prompts.py CLAUDE.md`
  - status: pending

- [ ] **ft2**: repository-map.yaml を更新
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft3**: 変更をコミット
  - command: `git add -A && git status`
  - status: pending
