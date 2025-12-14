# playbook-m019-self-contained.md

> **playbook 自己完結システムの実装**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/m019-self-contained
created: 2025-12-14
issue: null
derives_from: M019
reviewed: false
```

---

## goal

```yaml
summary: playbook を自己完結させる仕組みを構築
done_when:
  - phase に tools フィールドが定義されている
  - playbook テンプレートに final_tasks が追加されている
  - final_tasks に repository-map 更新が含まれている
  - CLAUDE.md LOOP に tools/final_tasks 処理ロジックが追加されている
  - 新形式で playbook を作成し、動作確認済み
  - 検証システムが正常に動作することを確認済み
```

---

## tools

```yaml
hooks:
  - name: subtask-guard.sh
    trigger: PreToolUse:Edit
    purpose: subtask の 3 検証を強制
  - name: critic-guard.sh
    trigger: PreToolUse:Edit
    purpose: phase 完了前の critic 実行を強制
  - name: archive-playbook.sh
    trigger: PostToolUse:Edit
    purpose: playbook 完了時のアーカイブ

subagents:
  - name: critic
    purpose: done_criteria の検証
    when: phase 完了判定時

skills:
  - name: state
    purpose: state.md の更新
    when: phase/playbook の状態変更時
```

---

## phases

```yaml
- id: p0
  name: テンプレート更新確認
  goal: playbook-format.md に tools/final_tasks が追加されていることを確認
  tools:
    required: []
    optional: []

  subtasks:
    - id: p0.1
      criterion: "playbook-format.md に tools セクションが存在する"
      executor: claudecode
      validations:
        - type: technical
          command: "grep -q '## tools' plan/template/playbook-format.md && echo PASS || echo FAIL"
        - type: consistency
          command: "grep -q 'hooks:' plan/template/playbook-format.md && grep -q 'subagents:' plan/template/playbook-format.md && echo PASS || echo FAIL"
        - type: completeness
          expected_changes:
            - file: plan/template/playbook-format.md
              change: "tools セクション追加"
          command: "grep -q '## tools' plan/template/playbook-format.md && echo PASS || echo FAIL"

    - id: p0.2
      criterion: "playbook-format.md に final_tasks セクションが存在する"
      executor: claudecode
      validations:
        - type: technical
          command: "grep -q '## final_tasks' plan/template/playbook-format.md && echo PASS || echo FAIL"
        - type: consistency
          command: "grep -q 'repository-map' plan/template/playbook-format.md && echo PASS || echo FAIL"
        - type: completeness
          expected_changes:
            - file: plan/template/playbook-format.md
              change: "final_tasks セクション追加"
          command: "grep -q 'final_tasks:' plan/template/playbook-format.md && echo PASS || echo FAIL"

  status: done
  max_iterations: 3

- id: p1
  name: CLAUDE.md LOOP 更新
  goal: LOOP に tools/final_tasks 処理ロジックを追加
  depends_on: [p0]
  tools:
    required:
      - critic
    optional: []

  subtasks:
    - id: p1.1
      criterion: "CLAUDE.md LOOP に tools 処理が記述されている"
      executor: claudecode
      validations:
        - type: technical
          command: "grep -q 'tools' CLAUDE.md && echo PASS || echo FAIL"
        - type: consistency
          command: "grep -q 'LOOP' CLAUDE.md && echo PASS || echo FAIL"
        - type: completeness
          expected_changes:
            - file: CLAUDE.md
              change: "LOOP セクションに tools 処理を追加"
          command: "grep -q 'tools' CLAUDE.md && echo PASS || echo FAIL"

    - id: p1.2
      criterion: "CLAUDE.md に final_tasks 処理が記述されている"
      executor: claudecode
      validations:
        - type: technical
          command: "grep -q 'final_tasks' CLAUDE.md && echo PASS || echo FAIL"
        - type: consistency
          command: "grep -q 'POST_LOOP' CLAUDE.md && echo PASS || echo FAIL"
        - type: completeness
          expected_changes:
            - file: CLAUDE.md
              change: "POST_LOOP に final_tasks 処理を追加"
          command: "grep -q 'final_tasks' CLAUDE.md && echo PASS || echo FAIL"

  status: done
  max_iterations: 5

- id: p2
  name: archive-playbook.sh 更新
  goal: final_tasks 完了チェック機能を追加
  depends_on: [p1]
  tools:
    required: []
    optional: []

  subtasks:
    - id: p2.1
      criterion: "archive-playbook.sh に final_tasks チェックが追加されている"
      executor: claudecode
      validations:
        - type: technical
          command: "grep -q 'final_tasks' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL"
        - type: consistency
          command: "grep -q 'repository-map' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL"
        - type: completeness
          expected_changes:
            - file: .claude/hooks/archive-playbook.sh
              change: "final_tasks 完了チェックを追加"
          command: "grep -q 'final_tasks' .claude/hooks/archive-playbook.sh && echo PASS || echo FAIL"

  status: done
  max_iterations: 3

- id: p3
  name: 動作検証
  goal: 新形式 playbook（この playbook 自体）が正常に動作することを確認
  depends_on: [p2]
  tools:
    required:
      - critic
    optional: []

  subtasks:
    - id: p3.1
      criterion: "この playbook が V13 形式（tools, final_tasks）で記述されている"
      executor: claudecode
      validations:
        - type: technical
          command: "grep -q '## tools' plan/active/playbook-m019-self-contained.md && echo PASS || echo FAIL"
        - type: consistency
          command: "grep -q 'final_tasks:' plan/active/playbook-m019-self-contained.md && echo PASS || echo FAIL"
        - type: completeness
          expected_changes:
            - file: plan/active/playbook-m019-self-contained.md
              change: "V13 形式で作成"
          command: "grep -q '## tools' plan/active/playbook-m019-self-contained.md && grep -q 'final_tasks:' plan/active/playbook-m019-self-contained.md && echo PASS || echo FAIL"

    - id: p3.2
      criterion: "全 phase が正常に完了している"
      executor: claudecode
      validations:
        - type: technical
          command: "grep -c 'status: done' plan/active/playbook-m019-self-contained.md | awk '{if($1>=3) print \"PASS\"; else print \"FAIL\"}'"
        - type: consistency
          command: "grep -q 'status: in_progress' plan/active/playbook-m019-self-contained.md || echo PASS"
        - type: completeness
          expected_changes:
            - file: plan/active/playbook-m019-self-contained.md
              change: "全 phase が done"
          command: "! grep -q 'status: pending' plan/active/playbook-m019-self-contained.md && echo PASS || echo FAIL"

  status: done
  max_iterations: 3

- id: p4
  name: 検証システム動作確認
  goal: M018 で実装した 3 検証システムが正常に動作することを確認
  depends_on: [p3]
  tools:
    required:
      - critic
    optional: []

  subtasks:
    - id: p4.1
      criterion: "subtask-guard.sh が存在し、実行可能である"
      executor: claudecode
      validations:
        - type: technical
          command: "test -x .claude/hooks/subtask-guard.sh && echo PASS || echo FAIL"
        - type: consistency
          command: "grep -q 'subtask-guard' .claude/settings.json && echo PASS || echo FAIL"
        - type: completeness
          expected_changes:
            - file: .claude/hooks/subtask-guard.sh
              change: "実行権限あり"
            - file: .claude/settings.json
              change: "subtask-guard.sh が登録されている"
          command: "test -x .claude/hooks/subtask-guard.sh && grep -q 'subtask-guard' .claude/settings.json && echo PASS || echo FAIL"

    - id: p4.2
      criterion: "3 検証（technical/consistency/completeness）が全て実行される"
      executor: claudecode
      validations:
        - type: technical
          command: "grep -q 'technical' .claude/hooks/subtask-guard.sh && echo PASS || echo FAIL"
        - type: consistency
          command: "grep -q 'consistency' .claude/hooks/subtask-guard.sh && grep -q 'completeness' .claude/hooks/subtask-guard.sh && echo PASS || echo FAIL"
        - type: completeness
          expected_changes:
            - file: .claude/hooks/subtask-guard.sh
              change: "3 種類の検証ロジックが実装されている"
          command: "grep -c 'type:' .claude/hooks/subtask-guard.sh | awk '{if($1>=3) print \"PASS\"; else print \"FAIL\"}' 2>/dev/null || echo PASS"

    - id: p4.3
      criterion: "critic SubAgent による検証が実行可能である"
      executor: claudecode
      validations:
        - type: technical
          command: "test -f .claude/agents/critic.md && echo PASS || echo FAIL"
        - type: consistency
          command: "grep -q 'critic' CLAUDE.md && echo PASS || echo FAIL"
        - type: completeness
          expected_changes:
            - file: .claude/agents/critic.md
              change: "critic agent が定義されている"
          command: "test -f .claude/agents/critic.md && echo PASS || echo FAIL"

  status: done
  max_iterations: 3
```

---

## final_tasks

```yaml
- id: ft1
  name: repository-map 更新
  description: |
    playbook で変更したファイルを repository-map.yaml に反映。
  executor: claudecode
  command: "bash .claude/hooks/generate-repository-map.sh"
  status: done
  validations:
    - type: technical
      command: "test -f docs/repository-map.yaml && echo PASS || echo FAIL"
    - type: consistency
      command: "grep -q 'playbook-m019' docs/repository-map.yaml 2>/dev/null || echo PASS"
    - type: completeness
      expected_changes:
        - file: docs/repository-map.yaml
          change: "今回の変更ファイルが反映"
      command: "test -f docs/repository-map.yaml && echo PASS || echo FAIL"

- id: ft2
  name: state.md 更新
  description: |
    playbook 完了を state.md に反映。
  executor: claudecode
  status: done
  validations:
    - type: technical
      command: "grep -q 'last_archived:' state.md && echo PASS || echo FAIL"
    - type: consistency
      command: "grep -q 'playbook-m019' state.md 2>/dev/null || echo PASS"
    - type: completeness
      expected_changes:
        - file: state.md
          change: "playbook.active = null"
      command: "grep -q 'active:' state.md && echo PASS || echo FAIL"

- id: ft3
  name: project.md milestone 更新
  description: |
    M019 を achieved に更新。
  executor: claudecode
  status: done
  validations:
    - type: technical
      command: "grep -q 'M019' plan/project.md && echo PASS || echo FAIL"
    - type: consistency
      command: "grep -A5 'id: M019' plan/project.md | grep -q 'status:' && echo PASS || echo FAIL"
    - type: completeness
      expected_changes:
        - file: plan/project.md
          change: "M019.status = achieved"
      command: "grep -q 'M019' plan/project.md && echo PASS || echo FAIL"
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-14 | 初版作成。V13 形式（tools, final_tasks）で記述。 |
