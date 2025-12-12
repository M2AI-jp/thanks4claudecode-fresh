# playbook-explicit-tool-invocation.md

> **playbook に tools フィールドを追加して発火を確実にする**

---

## meta

```yaml
project: explicit-tool-invocation
branch: feat/explicit-tool-invocation
created: 2025-12-12
issue: null
derives_from: DW-001, DW-002, DW-003, DW-004
reviewed: false
```

---

## goal

```yaml
summary: playbook に tools フィールドを追加し、SubAgents/Skills の明示的発火を実現する
done_when:
  - playbook-format.md に tools フィールドが定義されている
  - pm.md に自動提案ロジックが記述されている
  - feature-map.md に新機能が説明されている
  - テストで発火が確認できている
```

---

## phases

### Phase 1: playbook-format.md に tools フィールドを追加

```yaml
- id: p1
  name: tools フィールド定義
  goal: playbook-format.md に tools フィールドの構造と使い方を追加
  tools:  # この playbook 自体が新機能を実践
    subagents: [critic]
    skills: [lint-checker]
  tasks:
    - id: t1-1
      name: tools フィールド構造を追加
      subtasks:
        - step: "playbook-format.md の subtask 構造に tools フィールドを追加"
          executor: claudecode
          criteria: "grep 'tools:' plan/template/playbook-format.md がヒットする"
          status: "[x]"
          tools:
            subagents: []
            skills: []
        - step: "Phase レベルの tools フィールドを追加"
          executor: claudecode
          criteria: "Phase 記述例に tools フィールドが含まれている"
          status: "[x]"
          tools:
            subagents: []
            skills: []
    - id: t1-2
      name: 記述ガイドを追加
      subtasks:
        - step: "tools フィールドの良い例/悪い例を追加"
          executor: claudecode
          criteria: "grep '良い例' plan/template/playbook-format.md で tools 関連がヒットする"
          status: "[x]"
          tools:
            subagents: []
            skills: []
  test_method: |
    1. grep 'tools:' plan/template/playbook-format.md
    2. grep 'subagents' plan/template/playbook-format.md
    3. grep 'skills' plan/template/playbook-format.md
  status: done
```

### Phase 2: pm.md に自動提案ロジックを追加

```yaml
- id: p2
  name: 自動提案ロジック追加
  goal: pm が playbook 作成時に executor から tools を自動推測するロジックを追加
  depends_on: [p1]
  tools:
    subagents: [critic]
    skills: [lint-checker]
  tasks:
    - id: t2-1
      name: 自動提案ルールを定義
      subtasks:
        - step: "executor → tools のマッピングルールを pm.md に追加"
          executor: claudecode
          criteria: "grep 'executor.*tools' .claude/agents/pm.md がヒットする"
          status: "[x]"
          tools:
            subagents: []
            skills: []
    - id: t2-2
      name: チェックリストを追加
      subtasks:
        - step: "playbook 作成時の tools チェックリストを追加"
          executor: claudecode
          criteria: "grep 'tools.*チェック' .claude/agents/pm.md がヒットする"
          status: "[x]"
          tools:
            subagents: []
            skills: []
  test_method: |
    1. grep 'tools' .claude/agents/pm.md
    2. pm.md の「自動提案ルール」セクションを確認
  status: done
```

### Phase 3: feature-map.md を更新

```yaml
- id: p3
  name: ドキュメント更新
  goal: feature-map.md に tools フィールドの説明を追加
  depends_on: [p1]
  tools:
    subagents: [critic]
    skills: []
  tasks:
    - id: t3-1
      name: tools フィールド説明を追加
      subtasks:
        - step: "feature-map.md に tools フィールドのセクションを追加"
          executor: claudecode
          criteria: "grep 'tools' docs/feature-map.md がヒットする"
          status: "[x]"
          tools:
            subagents: []
            skills: []
  test_method: |
    1. grep 'tools' docs/feature-map.md
    2. 「Explicit Tool Invocation」セクションの存在を確認
  status: done
```

### Phase 4: 発火テスト

```yaml
- id: p4
  name: 発火テスト
  goal: 実際に tools フィールドを含む playbook を実行し、発火を確認
  depends_on: [p1, p2, p3]
  tools:
    subagents: [critic]
    skills: [test-runner]
  tasks:
    - id: t4-1
      name: 発火確認
      subtasks:
        - step: "この playbook 自体の tools フィールドが正しく認識されることを確認"
          executor: claudecode
          criteria: "grep 'tools:' plan/active/playbook-explicit-tool-invocation.md で 10 件以上ヒットする"
          status: "[x]"
          tools:
            subagents: [critic]
            skills: []
        - step: "critic SubAgent を呼び出して検証"
          executor: claudecode
          criteria: "Task(subagent_type='critic') が PASS を返す"
          status: "[x]"
          tools:
            subagents: [critic]
            skills: []
  test_method: |
    1. この playbook の tools フィールドを読む
    2. 指定された SubAgent/Skill を呼び出す
    3. 発火ログを確認
  status: done
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-12 | 初版作成。tools フィールドを自己言及的に使用。 |
