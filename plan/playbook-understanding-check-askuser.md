# playbook-understanding-check-askuser.md

> **pm SubAgent の理解確認結果を構造化データで返し、AskUserQuestion で選択肢形式のユーザー確認を実現する**

---

## meta

```yaml
project: understanding-check-askuser
branch: feat/understanding-check-askuser
created: 2025-12-25
issue: null
reviewed: true
roles:
  worker: claudecode  # この playbook はドキュメント・設定中心のため claudecode
```

---

## goal

```yaml
summary: pm SubAgent が構造化された選択肢データを返し、メイン Claude が AskUserQuestion で選択肢形式のユーザー確認を実現する
done_when:
  - .claude/skills/understanding-check/SKILL.md に選択肢フォーマット定義が存在する
  - pm SubAgent（pm.md）が構造化された選択肢データを返す仕様が記載されている
  - メイン Claude が AskUserQuestion で選択肢を提示するフローがドキュメント化されている
```

---

## phases

### p1: 選択肢フォーマット定義

**goal**: understanding-check Skill に選択肢出力フォーマットを定義する

#### subtasks

- [ ] **p1.1**: SKILL.md に選択肢フォーマット定義セクションが存在する
  - executor: claudecode
  - validations:
    - technical: "grep で 'Structured Output Format' セクションの存在を確認"
    - consistency: "既存の Output Template セクションと整合性がある"
    - completeness: "yes_no, single_choice, approval の3タイプが定義されている"

- [ ] **p1.2**: YAML 形式の選択肢フォーマットが定義されている
  - executor: claudecode
  - validations:
    - technical: "understanding_check.questions 構造が定義されている"
    - consistency: "既存の 5W1H フレームワークと統合されている"
    - completeness: "id, text, type, options の全フィールドが定義されている"

**status**: pending
**max_iterations**: 5

---

### p2: pm.md への選択肢返却仕様追加

**goal**: pm SubAgent が構造化された選択肢データを返すように仕様を追加する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: pm.md に選択肢フォーマット返却セクションが存在する
  - executor: claudecode
  - validations:
    - technical: "grep で 'Structured Question Output' セクションの存在を確認"
    - consistency: "SKILL.md の選択肢フォーマットと一致している"
    - completeness: "返却フォーマット、使用例、メイン Claude への指示が含まれている"

- [ ] **p2.2**: 理解確認フローに選択肢出力ステップが追加されている
  - executor: claudecode
  - validations:
    - technical: "理解確認結果に questions 配列が含まれる仕様になっている"
    - consistency: "既存の理解確認フローと整合性がある"
    - completeness: "不明点確認、実装方針選択、全体承認の3種類が含まれている"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p1, p2]

#### subtasks

- [ ] **p_final.1**: SKILL.md に選択肢フォーマット定義が存在し、3タイプ（yes_no, single_choice, approval）が定義されている
  - executor: claudecode
  - validations:
    - technical: "grep で各タイプの存在を確認"
    - consistency: "フォーマットが一貫している"
    - completeness: "全タイプが使用例付きで定義されている"

- [ ] **p_final.2**: pm.md に構造化された選択肢データを返す仕様が記載されている
  - executor: claudecode
  - validations:
    - technical: "grep で選択肢返却セクションの存在を確認"
    - consistency: "SKILL.md のフォーマットと一致している"
    - completeness: "メイン Claude への連携方法が明記されている"

- [ ] **p_final.3**: AskUserQuestion で選択肢を提示するフローがドキュメント化されている
  - executor: claudecode
  - validations:
    - technical: "AskUserQuestion への変換ロジックが記載されている"
    - consistency: "Claude Code の AskUserQuestion API と整合性がある"
    - completeness: "フロー図または手順が明記されている"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
