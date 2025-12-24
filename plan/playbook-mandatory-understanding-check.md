# playbook-mandatory-understanding-check.md

> **全ユーザープロンプトに対して理解確認（5W1H分析）を必須化する**

## meta

```yaml
project: thanks4claudecode
branch: feat/mandatory-understanding-check
created: 2025-12-24
issue: null
reviewed: true
```

## goal

```yaml
summary: ユーザープロンプトに対して必ず理解確認（5W1H分析）が実行される仕組みを実装する
done_when:
  - prompt.sh が理解確認の強制メッセージを注入している
  - pm.md が理解確認なしに playbook 作成を進めない構造的ルールを持つ
  - understanding-check Skill のスキップ条件が「ユーザー明示要求のみ」に更新されている
```

## phases

### p1: prompt.sh に理解確認強制メッセージを追加

**goal**: State Injection に理解確認の必須性を追加し、全プロンプトで発火させる

#### subtasks

- [ ] **p1.1**: prompt.sh が理解確認強制メッセージを含む State Injection を出力している
  - executor: claudecode
  - validations:
    - technical: "bash -n prompt.sh でシンタックスエラーがない"
    - consistency: "既存の State Injection 構造と整合性がある"
    - completeness: "playbook=null と playbook 存在時の両方で理解確認メッセージが含まれる"

**status**: pending
**max_iterations**: 5

---

### p2: pm.md の理解確認ルールを厳格化

**goal**: pm SubAgent が理解確認なしに playbook 作成を進めないよう構造的ルールを追加

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: pm.md に「理解確認は全プロンプトで必須」のルールが明記されている
  - executor: claudecode
  - validations:
    - technical: "grep で理解確認必須ルールの存在を確認"
    - consistency: "既存の playbook 作成フローと整合性がある"
    - completeness: "スキップ条件が明確に定義されている"

- [ ] **p2.2**: pm.md の playbook 作成フローに理解確認ステップが強制ステップとして追加されている
  - executor: claudecode
  - validations:
    - technical: "Step 1.5 が必須ステップとして明記されている"
    - consistency: "フロー全体の順序が正しい"
    - completeness: "Phase 途中でも理解確認が発動することが明記されている"

**status**: pending
**max_iterations**: 5

---

### p3: understanding-check Skill のスキップ条件を更新

**goal**: Skill のスキップ条件を「ユーザー明示要求のみ」に限定する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: SKILL.md のスキップ条件が「ユーザー明示要求のみ」に更新されている
  - executor: claudecode
  - validations:
    - technical: "grep でスキップ条件を確認"
    - consistency: "pm.md のルールと整合性がある"
    - completeness: "Phase 途中でも実行することが明記されている"

**status**: pending
**max_iterations**: 3

---

### p_final: 完了検証（必須）

**goal**: 全ての done_when が実際に満たされているか最終検証

**depends_on**: [p3]

#### subtasks

- [ ] **p_final.1**: prompt.sh が理解確認の強制メッセージを注入している
  - executor: claudecode
  - validations:
    - technical: "prompt.sh を実行して出力に理解確認メッセージが含まれることを確認"
    - consistency: "playbook=null と playbook 存在時の両方で確認"
    - completeness: "メッセージ内容が understanding-check Skill の実行を促す形式である"

- [ ] **p_final.2**: pm.md が理解確認なしに playbook 作成を進めない構造的ルールを持つ
  - executor: claudecode
  - validations:
    - technical: "pm.md に理解確認必須ルールが存在することを確認"
    - consistency: "playbook 作成フローの Step 1.5 が必須ステップである"
    - completeness: "スキップ条件が明確に「ユーザー明示要求のみ」と定義されている"

- [ ] **p_final.3**: understanding-check Skill のスキップ条件が「ユーザー明示要求のみ」に更新されている
  - executor: claudecode
  - validations:
    - technical: "SKILL.md のスキップ条件を確認"
    - consistency: "pm.md と整合性がある"
    - completeness: "単純質問・Phase 途中もスキップしないことが明記されている"

**status**: pending
**max_iterations**: 3

---

## final_tasks

- [ ] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: pending

- [ ] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: pending

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending
