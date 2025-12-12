# playbook-doc-audit-component-eval.md

> **ドキュメント・コンポーネント監査 playbook**
>
> tech-stack.md 以外の不要ドキュメント削除、非Core Hooks/SubAgents/Skills の評価・削除検討

---

## meta

```yaml
project: thanks4claudecode
branch: feat/doc-audit-component-eval
created: 2025-12-13
issue: null
derives_from: M010  # ドキュメント・コンポーネント監査
reviewed: false
```

---

## goal

```yaml
summary: |
  ドキュメント・コンポーネント監査を実施し、参照されないファイルを削除、
  非Core Hooks/SubAgents/Skills の必要性を評価・改善する

done_when:
  - ドキュメント参照状況の最終確認リストが作成されている
  - 未参照ドキュメントがアーカイブに移動されている
  - 非Core Hooks の評価が完了している
  - 非Core SubAgents の評価が完了している
  - 非Core Skills の評価が完了している
  - Codex による第三者評価・最終レポートが作成されている
```

---

## phases

### p0: ドキュメント参照状況の最終確認・リスト作成

```yaml
id: p0
name: ドキュメント参照状況の最終確認・リスト作成
goal: tech-stack.md を除く全ドキュメントの参照状況を確認し、削除/保持判定リストを作成

subtasks:
  - id: p0.1
    criterion: "docs/ 配下の全ドキュメントが列挙されている"
    executor: claudecode
    test_command: "ls -la /Users/amano/Desktop/thanks4claudecode/docs/ | grep -c '\.md$' | awk '{if($1>0) print \"PASS\"; else print \"FAIL\"}'"

  - id: p0.2
    criterion: "plan/template/ 配下の全テンプレートが列挙されている"
    executor: claudecode
    test_command: "ls -la /Users/amano/Desktop/thanks4claudecode/plan/template/ | grep -c '\.md$' | awk '{if($1>0) print \"PASS\"; else print \"FAIL\"}'"

  - id: p0.3
    criterion: "参照状況リスト（docs/doc-reference-audit.md）が作成されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/docs/doc-reference-audit.md && echo PASS || echo FAIL"

  - id: p0.4
    criterion: "リストに削除/保持の判定と理由が記載されている"
    executor: claudecode
    test_command: "grep -q '削除予定\\|保持' /Users/amano/Desktop/thanks4claudecode/docs/doc-reference-audit.md && echo PASS || echo FAIL"

status: done
max_iterations: 5
critic: PASS (2025-12-13)
```

---

### p1: 未参照ドキュメントをアーカイブに移動

```yaml
id: p1
name: 未参照ドキュメントをアーカイブに移動
goal: 削除予定のドキュメントを archive/ に移動し、削除せずに保管
depends_on: [p0]

subtasks:
  - id: p1.1
    criterion: ".archive/ ディレクトリが存在する"
    executor: claudecode
    test_command: "test -d /Users/amano/Desktop/thanks4claudecode/.archive && echo PASS || echo FAIL"
    note: "既存の .archive/plan/ との整合性を取り、ドット付きディレクトリを使用"

  - id: p1.2
    criterion: "削除予定ドキュメントが全て .archive/ に移動されている"
    executor: claudecode
    test_command: "find /Users/amano/Desktop/thanks4claudecode/.archive -type f \\( -name '*.md' -o -name '*.sh' \\) | wc -l | awk '{if($1>=27) print \"PASS: \" $1 \" files\"; else print \"FAIL: \" $1 \" files\"}'"

  - id: p1.3
    criterion: ".archive/docs.moved.txt に移動ファイル一覧が記載されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/.archive/docs.moved.txt && grep -q 'archive:' /Users/amano/Desktop/thanks4claudecode/.archive/docs.moved.txt && echo PASS || echo FAIL"

status: done
max_iterations: 5
critic: PASS (2025-12-13)
```

---

### p2: 非Core Hooks の評価

```yaml
id: p2
name: 非Core Hooks の評価
goal: 各 Hook のコード確認、使用頻度、代替手段の有無を評価し、削除候補を提示
depends_on: [p0]

subtasks:
  - id: p2.1
    criterion: "全 Hook ファイル（.claude/hooks/）の一覧が列挙されている"
    executor: claudecode
    test_command: "find /Users/amano/Desktop/thanks4claudecode/.claude/hooks -name '*.sh' | wc -l | awk '{if($1>0) print \"PASS\"; else print \"FAIL\"}'"

  - id: p2.2
    criterion: "各 Hook について依存関係・使用頻度が分析されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/docs/hook-evaluation.md && grep -q '使用頻度\\|依存関係' /Users/amano/Desktop/thanks4claudecode/docs/hook-evaluation.md && echo PASS || echo FAIL"

  - id: p2.3
    criterion: "非Core Hook の削除候補リストが作成されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/docs/hook-evaluation.md && grep -q '削除候補' /Users/amano/Desktop/thanks4claudecode/docs/hook-evaluation.md && echo PASS || echo FAIL"

status: done
max_iterations: 5
critic: PASS (2025-12-13)
```

---

### p3: 非Core SubAgents の評価

```yaml
id: p3
name: 非Core SubAgents の評価
goal: 各 SubAgent の依存関係、使用状況を確認・評価し、削除候補を提示
depends_on: [p0]

subtasks:
  - id: p3.1
    criterion: "全 SubAgent ファイル（.claude/agents/）の一覧が列挙されている"
    executor: claudecode
    test_command: "find /Users/amano/Desktop/thanks4claudecode/.claude/agents -name '*.md' | wc -l | awk '{if($1>0) print \"PASS\"; else print \"FAIL\"}'"

  - id: p3.2
    criterion: "各 SubAgent について機能・依存関係が分析されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/docs/subagent-evaluation.md && grep -q '機能\\|依存関係' /Users/amano/Desktop/thanks4claudecode/docs/subagent-evaluation.md && echo PASS || echo FAIL"

  - id: p3.3
    criterion: "非Core SubAgent の削除候補リストが作成されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/docs/subagent-evaluation.md && grep -q '削除候補' /Users/amano/Desktop/thanks4claudecode/docs/subagent-evaluation.md && echo PASS || echo FAIL"

status: pending
max_iterations: 5
```

---

### p4: 非Core Skills の評価

```yaml
id: p4
name: 非Core Skills の評価
goal: 各 Skill の機能、使用可能性を確認・評価し、削除候補を提示
depends_on: [p0]

subtasks:
  - id: p4.1
    criterion: "全 Skill ファイル（.claude/skills/）の一覧が列挙されている"
    executor: claudecode
    test_command: "find /Users/amano/Desktop/thanks4claudecode/.claude/skills -name '*.md' | wc -l | awk '{if($1>0) print \"PASS\"; else print \"FAIL\"}'"

  - id: p4.2
    criterion: "各 Skill について機能・使用状況が分析されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/docs/skill-evaluation.md && grep -q '機能\\|使用状況' /Users/amano/Desktop/thanks4claudecode/docs/skill-evaluation.md && echo PASS || echo FAIL"

  - id: p4.3
    criterion: "非Core Skill の削除候補リストが作成されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/docs/skill-evaluation.md && grep -q '削除候補' /Users/amano/Desktop/thanks4claudecode/docs/skill-evaluation.md && echo PASS || echo FAIL"

status: pending
max_iterations: 5
```

---

### p5: Codex による第三者評価・最終レポート

```yaml
id: p5
name: Codex による第三者評価・最終レポート
goal: 削除予定ファイル・コンポーネントを Codex に提示し、第三者視点での評価・改善提案を取得
depends_on: [p2, p3, p4]

subtasks:
  - id: p5.1
    criterion: "削除候補を Codex に提示し、評価を取得している"
    executor: codex
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/docs/codex-evaluation-report.md && echo PASS || echo FAIL"

  - id: p5.2
    criterion: "Codex の最終レポートに削除/保持の判定が記載されている"
    executor: codex
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/docs/codex-evaluation-report.md && grep -q '削除\\|保持' /Users/amano/Desktop/thanks4claudecode/docs/codex-evaluation-report.md && echo PASS || echo FAIL"

  - id: p5.3
    criterion: "最終判定リスト（docs/audit-final-decision.md）が作成されている"
    executor: claudecode
    test_command: "test -f /Users/amano/Desktop/thanks4claudecode/docs/audit-final-decision.md && echo PASS || echo FAIL"

status: pending
max_iterations: 5
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | 初版作成。M010 から導出。6つの Phase を定義。 |
