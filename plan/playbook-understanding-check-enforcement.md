# playbook-understanding-check-enforcement.md

> **理解確認（5W1H）を全プロンプトで必須化する**

---

## meta

```yaml
project: understanding-check-enforcement
branch: feat/understanding-check-enforcement
created: 2025-12-24
issue: null
reviewed: true
roles:
  worker: claudecode  # Shell スクリプト修正のみ、claudecode で十分
```

---

## goal

```yaml
summary: 理解確認（5W1H分析）を全プロンプトで強制し、スキップ防止の構造的ガードを実装する
done_when:
  - prompt.sh が UserPromptSubmit 時に理解確認強制メッセージを注入している
  - pm.md が理解確認結果なしに playbook 作成を進めない構造を持つ
  - understanding-check Skill の SKILL.md が更新されている
```

---

## phases

### p1: prompt.sh の理解確認メッセージ強化

**goal**: UserPromptSubmit Hook で理解確認を強制するメッセージを注入する

#### subtasks

- [ ] **p1.1**: prompt.sh が全プロンプトに理解確認必須メッセージを注入している
  - executor: claudecode
  - validations:
    - technical: "bash .claude/hooks/prompt.sh を実行し、出力に理解確認メッセージが含まれることを確認"
    - consistency: "playbook=null の場合も playbook ありの場合も同じメッセージが注入されることを確認"
    - completeness: "メッセージに 5W1H、スキップ条件、understanding-check Skill 参照が含まれていることを確認"

- [ ] **p1.2**: 注入メッセージが理解確認の構造的強制を明示している
  - executor: claudecode
  - validations:
    - technical: "grep で 'Phase 途中でも' 'スキップ不可' のキーワードが含まれることを確認"
    - consistency: "SKILL.md の skip_conditions と整合していることを確認"
    - completeness: "ユーザーが明示的にスキップ要求した場合のみ許可することが明記されていることを確認"

**status**: pending
**max_iterations**: 5

---

### p2: pm.md の理解確認ゲート強化

**goal**: pm SubAgent が理解確認なしに playbook 作成を進めないよう構造的に強制する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: pm.md に「理解確認_絶対ルール」セクションが存在し、全プロンプトで必須であることが明記されている
  - executor: claudecode
  - validations:
    - technical: "grep -A10 '理解確認_絶対ルール' で内容を確認"
    - consistency: "SKILL.md の triggers/skip_conditions と整合していることを確認"
    - completeness: "Phase 途中でも例外なく実施することが明記されていることを確認"

- [ ] **p2.2**: playbook 作成フロー（step 1.5）に理解確認が「絶対必須」として記載されている
  - executor: claudecode
  - validations:
    - technical: "grep -A5 'step_0.5\\|1.5' で内容を確認"
    - consistency: "フロー全体で理解確認がスキップ不可であることが整合していることを確認"
    - completeness: "ユーザー承認を得てから次のステップに進むことが明記されていることを確認"

- [ ] **p2.3**: スキップ可能条件が「ユーザーの明示的要求のみ」に限定されている
  - executor: claudecode
  - validations:
    - technical: "grep -E 'スキップ|skip' で該当箇所を確認"
    - consistency: "全ての箇所で同じ条件が記載されていることを確認"
    - completeness: "旧条件（単純な質問、Phase 途中）が廃止されていることを確認"

**status**: pending
**max_iterations**: 5

---

### p3: SKILL.md の更新

**goal**: understanding-check Skill のドキュメントを最新の必須化仕様に更新する

**depends_on**: [p1, p2]

#### subtasks

- [ ] **p3.1**: SKILL.md の triggers セクションが「全プロンプトで必須」に更新されている
  - executor: claudecode
  - validations:
    - technical: "grep -A10 'triggers:' で内容を確認"
    - consistency: "pm.md の記載と整合していることを確認"
    - completeness: "Phase 途中でも実行することが明記されていることを確認"

- [ ] **p3.2**: skip_conditions が「ユーザーの明示的要求のみ」に限定されている
  - executor: claudecode
  - validations:
    - technical: "grep -A5 'skip_conditions' で内容を確認"
    - consistency: "pm.md の記載と整合していることを確認"
    - completeness: "旧条件（単純な質問、Phase 途中）がコメントで廃止と記載されていることを確認"

- [ ] **p3.3**: Integration with pm.md セクションが更新されている
  - executor: claudecode
  - validations:
    - technical: "grep -A15 'Integration with pm.md' で内容を確認"
    - consistency: "pm.md の playbook 作成フローと整合していることを確認"
    - completeness: "理解確認_絶対ルールの全項目が反映されていることを確認"

**status**: pending
**max_iterations**: 5

---

### p_final: 完了検証

**goal**: done_when の全項目が実際に満たされていることを検証する

**depends_on**: [p1, p2, p3]

#### subtasks

- [ ] **p_final.1**: prompt.sh が理解確認強制メッセージを注入している
  - executor: claudecode
  - validations:
    - technical: "echo '{}' | bash .claude/hooks/prompt.sh を実行し、出力に理解確認メッセージを確認"
    - consistency: "メッセージ内容が SKILL.md と整合していることを確認"
    - completeness: "playbook=null と playbook あり両方のケースで注入されていることを確認"

- [ ] **p_final.2**: pm.md が理解確認なしに playbook 作成を進めない構造を持つ
  - executor: claudecode
  - validations:
    - technical: "grep -c '理解確認_絶対ルール\\|絶対必須' .claude/skills/golden-path/agents/pm.md が 2 以上であることを確認"
    - consistency: "フロー全体で理解確認が必須であることが整合していることを確認"
    - completeness: "スキップ条件が明示的に限定されていることを確認"

- [ ] **p_final.3**: SKILL.md が全プロンプトで必須であることを明記している
  - executor: claudecode
  - validations:
    - technical: "grep -c '全プロンプトで必須\\|全てのユーザープロンプト' .claude/skills/understanding-check/SKILL.md が 2 以上であることを確認"
    - consistency: "pm.md と prompt.sh と整合していることを確認"
    - completeness: "skip_conditions が正しく限定されていることを確認"

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
