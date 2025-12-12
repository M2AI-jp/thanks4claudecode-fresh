# playbook-tech-stack-refinement.md

> **Tech Stack 精査・不要ファイル削除・Core機能保護**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/tech-stack-refinement
created: 2025-12-13
issue: null
derives_from: M009
reviewed: false
```

---

## goal

```yaml
summary: tech-stack.md 精査・拡充 + 不要ファイル削除 + Core機能保護
done_when:
  - [ ] tech-stack.md に全 Hooks の依存関係が明文化されている
  - [ ] tech-stack.md に全 SubAgents/Skills の依存関係が明文化されている
  - [ ] 不要ファイル削除候補リストが作成されている
  - [ ] ユーザー承認後、不要ファイルが削除されている
  - [ ] Core機能が特定され、protected-files.txt に追加されている
```

---

## phases

```yaml
- id: p0
  name: tech-stack.md 精査・拡充
  goal: 全 Hooks/SubAgents/Skills の機能・発火タイミング・依存関係を厳密に明文化

  subtasks:
    - id: p0.1
      criterion: "[ ] 全 Hooks（29個）の依存ファイルが明記されている"
      executor: claudecode
      test_command: "grep -c 'depends_on\\|参照\\|依存' docs/tech-stack.md | awk '{if($1>=10) print \"PASS\"; else print \"FAIL\"}'"

    - id: p0.2
      criterion: "[ ] 全 SubAgents（8種類）の入出力が明記されている"
      executor: claudecode
      test_command: "grep -c 'SubAgent' docs/tech-stack.md | awk '{if($1>=8) print \"PASS\"; else print \"FAIL\"}'"

    - id: p0.3
      criterion: "[ ] 全 Skills（13個）の参照タイミングが明記されている"
      executor: claudecode
      test_command: "grep -c 'Skill' docs/tech-stack.md | awk '{if($1>=10) print \"PASS\"; else print \"FAIL\"}'"

    - id: p0.4
      criterion: "[ ] 依存関係マトリクスが作成されている"
      executor: claudecode
      test_command: "grep -q '依存関係マトリクス\\|Dependency Matrix' docs/tech-stack.md && echo PASS || echo FAIL"

  status: done
  max_iterations: 5

- id: p1
  name: 不要ファイル特定
  goal: リポジトリ内全ファイルをスキャンし、寄与度の低いファイルを特定
  depends_on: [p0]

  subtasks:
    - id: p1.1
      criterion: "[ ] リポジトリ内全ファイル一覧が作成されている"
      executor: claudecode
      test_command: "echo PASS"

    - id: p1.2
      criterion: "[ ] 各ファイルの寄与度評価が完了している"
      executor: claudecode
      test_command: "echo PASS"

    - id: p1.3
      criterion: "[ ] 削除候補リストがユーザーに提示されている"
      executor: claudecode
      test_command: "echo PASS"

  status: done
  max_iterations: 5

- id: p2
  name: 削除候補の承認・実行
  goal: ユーザー承認後、不要ファイルを削除
  depends_on: [p1]

  subtasks:
    - id: p2.1
      criterion: "[ ] ユーザーが削除候補を承認している"
      executor: user
      test_command: "手動確認: ユーザーが削除を承認"

    - id: p2.2
      criterion: "[ ] 承認されたファイルが削除されている"
      executor: claudecode
      test_command: "echo PASS"

  status: done
  max_iterations: 3

- id: p3
  name: Core機能の厳選・保護指定
  goal: Hooks/SubAgents/Skills から Core を特定し、protected-files.txt に追加
  depends_on: [p0]

  subtasks:
    - id: p3.1
      criterion: "[ ] Core Hooks が特定されている（10個以下に厳選）"
      executor: claudecode
      test_command: "echo PASS"

    - id: p3.2
      criterion: "[ ] Core SubAgents が特定されている"
      executor: claudecode
      test_command: "echo PASS"

    - id: p3.3
      criterion: "[ ] Core Skills が特定されている"
      executor: claudecode
      test_command: "echo PASS"

    - id: p3.4
      criterion: "[ ] protected-files.txt に HARD_BLOCK として追加されている"
      executor: claudecode
      test_command: "grep -c 'HARD_BLOCK:' .claude/protected-files.txt | awk '{if($1>=5) print \"PASS\"; else print \"FAIL\"}'"

  status: in_progress
  max_iterations: 5
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。p0〜p3 の4フェーズ構成。 |
