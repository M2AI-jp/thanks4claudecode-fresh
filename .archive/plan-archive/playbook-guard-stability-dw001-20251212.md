# playbook-guard-stability-dw001.md

> **ガード系の安定化 - project.md永続化とバグ修正**

---

## meta

```yaml
project: "ガード系の安定化"
branch: research/context-management
created: 2025-12-12
issue: null
derives_from: dw1
reviewed: false
```

---

## goal

```yaml
summary: project.md永続化設計を導入し、init-guard/playbook-guardのバグを修正する
done_when:
  - project.mdが永続ファイルとして運用されている
  - init-guardがproject.md不在時に自動作成する
  - playbook-guardがファイル不在時にexit 2を返す
  - CLAUDE.mdに/cc案内とproject永続化ルールが反映されている
```

---

## phases

### Phase 1: init-guard.sh 修正

```yaml
- id: p1
  name: init-guard修正
  goal: project.md不在時に空テンプレートを自動作成し、デッドロックを解消
  tools:
    subagents: [critic]
    skills: [lint-checker]
  tasks:
    - id: t1-1
      name: init-guard.sh修正
      subtasks:
        - step: "init-guard.shにproject.md自動作成ロジックを追加"
          executor: claudecode
          criteria: "grep 'plan/active/project.md' .claude/hooks/init-guard.sh で自動作成コードが存在"
          status: "[ ]"
        - step: "ShellCheck で構文検証"
          executor: claudecode
          criteria: "shellcheck .claude/hooks/init-guard.sh が警告なし"
          status: "[ ]"
  test_method: |
    1. project.mdを削除して新しいセッションを開始
    2. init-guardがproject.mdを自動作成することを確認
    3. デッドロックが発生しないことを確認
  status: pending
```

### Phase 2: playbook-guard.sh 修正

```yaml
- id: p2
  name: playbook-guard修正
  goal: playbookファイルが存在しない場合にexit 2でブロックする
  depends_on: [p1]
  tools:
    subagents: [critic]
    skills: [lint-checker]
  tasks:
    - id: t2-1
      name: playbook-guard.sh修正
      subtasks:
        - step: "ファイル不在時にexit 0ではなくexit 2を返すよう修正"
          executor: claudecode
          criteria: "playbook-guard.shがファイル不在時にブロックする（exit 2）"
          status: "[ ]"
        - step: "ShellCheck で構文検証"
          executor: claudecode
          criteria: "shellcheck .claude/hooks/playbook-guard.sh が警告なし"
          status: "[ ]"
  test_method: |
    1. state.mdのplaybookを存在しないパスに設定
    2. Edit操作を試みる
    3. playbook-guardがブロックすることを確認
  status: pending
```

### Phase 3: CLAUDE.md 更新

```yaml
- id: p3
  name: CLAUDE.md更新
  goal: /cc案内とproject永続化ルールを反映
  depends_on: [p2]
  tools:
    subagents: [critic]
    skills: []
  tasks:
    - id: t3-1
      name: コンテキスト案内更新
      subtasks:
        - step: "/cc自動提案トリガーセクションを更新（LLMは/clear実行不可を明記）"
          executor: claudecode
          criteria: "grep 'LLM から実行不可' CLAUDE.md でヒット"
          status: "[ ]"
    - id: t3-2
      name: project永続化ルール追加
      subtasks:
        - step: "project.md永続化ルールを追加"
          executor: claudecode
          criteria: "grep '永続ファイル' CLAUDE.md でヒット"
          status: "[ ]"
  test_method: |
    1. CLAUDE.mdを読み、/cc案内が更新されていることを確認
    2. project永続化ルールが記載されていることを確認
  status: pending
```

### Phase 4: state.md 更新と検証

```yaml
- id: p4
  name: state.md更新と検証
  goal: state.mdを更新し、全体の動作を検証
  depends_on: [p3]
  tools:
    subagents: [critic]
    skills: []
  tasks:
    - id: t4-1
      name: state.md更新
      subtasks:
        - step: "state.mdのplaybookセクションを正しいパスに更新"
          executor: claudecode
          criteria: "state.mdのplaybook.activeが正しいパスを指している"
          status: "[ ]"
    - id: t4-2
      name: 動作検証
      subtasks:
        - step: "全体の動作を検証（Editが正常に動作すること）"
          executor: claudecode
          criteria: "Edit操作がブロックされずに実行できる"
          status: "[ ]"
  test_method: |
    1. state.mdを確認
    2. 実際にEdit操作を実行して動作確認
  status: pending
```

### Phase 5: コミットとPR

```yaml
- id: p5
  name: コミットとPR
  goal: 変更をコミットしてPRを作成
  depends_on: [p4]
  tools:
    subagents: [critic]
    skills: []
  tasks:
    - id: t5-1
      name: コミット
      subtasks:
        - step: "全変更をコミット"
          executor: claudecode
          criteria: "git log で新しいコミットが確認できる"
          status: "[ ]"
    - id: t5-2
      name: PR作成
      subtasks:
        - step: "PRを作成"
          executor: claudecode
          criteria: "gh pr view でPRが確認できる"
          status: "[ ]"
  test_method: |
    1. git log で確認
    2. gh pr view で確認
  status: pending
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-12 | 初版作成 |
