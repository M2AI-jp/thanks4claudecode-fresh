# playbook-m085-orchestration-automation.md

> **オーケストレーション完全自動化 - pm による executor 自動判定・自動割り当て**

---

## meta

```yaml
project: thanks4claudecode
branch: feat/orchestration-automation
created: 2025-12-23
issue: null
derives_from: M085
reviewed: false
roles:
  worker: claudecode  # この playbook では Claude Code が実装
```

---

## goal

```yaml
summary: pm が playbook 作成時に executor を自動判定・自動割り当てし、executor-guard.sh が SubAgent 呼び出しを案内する
done_when:
  - pm.md にタスク分類パターンが「構造的強制」として定義されている
  - executor-guard.sh が SubAgent 呼び出し（Task(subagent_type='codex-delegate')）を案内している
  - docs/ai-orchestration.md にオーケストレーション自動化の説明が追加されている
```

---

## scope

```yaml
in_scope:
  - pm.md 強化: タスク分類ロジックを構造的強制として追加
  - executor-guard.sh 強化: SubAgent 呼び出し案内を追加
  - docs/ai-orchestration.md 更新: 自動化の説明を追加

out_of_scope:
  - 新規 Hook の追加（既存 Hook の強化のみ）
  - 動線の分離（1本の動線を維持）
```

---

## phases

### p1: pm.md 強化 - タスク分類ロジックの構造的強制

**goal**: pm.md にタスク分類パターンを「構造的強制」として定義し、pm が playbook 作成時に executor を自動判定する

**depends_on**: []

#### subtasks

- [x] **p1.1**: pm.md にタスク分類パターンセクションが追加されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep -q 'タスク分類パターン' .claude/agents/pm.md"
    - consistency: "PASS - executor 選択ロジックと整合性確認済み"
    - completeness: "PASS - coding_task, review_task, human_task, default の全パターンが定義済み"
  - validated: 2025-12-23T16:00:00

- [x] **p1.2**: pm.md のタスク分類パターンに coding_task キーワードが定義されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep -q 'coding_task' .claude/agents/pm.md"
    - consistency: "PASS - キーワードが playbook-format.md の executor 判定ガイドと整合"
    - completeness: "PASS - 実装, コーディング, ロジック, リファクタリング 等のキーワードが含まれる"
  - validated: 2025-12-23T16:00:00

- [x] **p1.3**: pm.md の executor 判定フローが明確に定義されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep -q 'executor 判定フロー' .claude/agents/pm.md"
    - consistency: "PASS - role-resolver.sh の解決ロジックと整合"
    - completeness: "PASS - パターンマッチ -> executor 割り当て -> 役割解決 のフローが明記"
  - validated: 2025-12-23T16:00:00

**status**: done
**max_iterations**: 5

---

### p2: executor-guard.sh 強化 - SubAgent 呼び出し案内

**goal**: executor-guard.sh のブロックメッセージに SubAgent 呼び出し指示を追加する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: executor-guard.sh の codex ブロックメッセージに Task(subagent_type='codex-delegate') が含まれている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep -q 'Task(subagent_type' .claude/hooks/executor-guard.sh"
    - consistency: "PASS - codex-delegate.md の呼び出し方法と整合"
    - completeness: "PASS - codex, coderabbit 両方の案内が更新されている"
  - validated: 2025-12-23T17:00:00

- [x] **p2.2**: executor-guard.sh の coderabbit ブロックメッセージに Task(subagent_type='reviewer') が含まれている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep -q 'reviewer' .claude/hooks/executor-guard.sh"
    - consistency: "PASS - reviewer.md の呼び出し方法と整合"
    - completeness: "PASS - coderabbit 専用の案内が存在する"
  - validated: 2025-12-23T17:00:00

- [x] **p2.3**: executor-guard.sh の構文エラーがない
  - executor: orchestrator
  - validations:
    - technical: "PASS - bash -n .claude/hooks/executor-guard.sh"
    - consistency: "PASS - 既存の動作を壊していない"
    - completeness: "PASS - 全ての case 文が正しく閉じている"
  - validated: 2025-12-23T17:00:00

**status**: done
**max_iterations**: 3

---

### p3: ドキュメント更新 - オーケストレーション自動化説明

**goal**: docs/ai-orchestration.md にオーケストレーション自動化の説明を追加する

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: docs/ai-orchestration.md に「オーケストレーション自動化」セクションが追加されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep -q 'オーケストレーション自動化' docs/ai-orchestration.md"
    - consistency: "PASS - pm.md のタスク分類パターンと整合"
    - completeness: "PASS - pm -> executor 判定 -> executor-guard -> SubAgent 呼び出し のフローが説明されている"
  - validated: 2025-12-23T17:00:00

- [x] **p3.2**: docs/ai-orchestration.md にタスク分類パターンの表が存在する
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep -q 'coding_task' docs/ai-orchestration.md"
    - consistency: "PASS - pm.md のパターン定義と整合"
    - completeness: "PASS - 全パターン（coding_task, review_task, human_task, default）が説明されている"
  - validated: 2025-12-23T17:00:00

**status**: done
**max_iterations**: 3

---

### p_self_update: Playbook 自己修正

**goal**: playbook 実行中の発見を playbook 自体に反映する

**depends_on**: [p1, p2, p3]

#### subtasks

- [x] **p_self_update.1**: 必要に応じて playbook が更新されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - playbook の内容が実際の作業と一致している"
    - consistency: "PASS - scope と done_when が整合している"
    - completeness: "PASS - 変更理由が変更履歴に記載されている"
  - validated: 2025-12-23T17:00:00

**status**: done
**max_iterations**: 2

---

### p_final: 完了検証（必須）

**goal**: playbook の done_when が全て満たされているか最終検証

**depends_on**: [p_self_update]

#### subtasks

- [x] **p_final.1**: pm.md にタスク分類パターンが「構造的強制」として定義されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep -q 'タスク分類パターン' .claude/agents/pm.md && grep -q 'coding_task' .claude/agents/pm.md"
    - consistency: "PASS - executor 選択ロジックと整合"
    - completeness: "PASS - 全パターンが定義されている"
  - validated: 2025-12-23T17:00:00

- [x] **p_final.2**: executor-guard.sh が SubAgent 呼び出し（Task(subagent_type='codex-delegate')）を案内している
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep -q 'Task(subagent_type' .claude/hooks/executor-guard.sh"
    - consistency: "PASS - SubAgent の呼び出し方法と整合"
    - completeness: "PASS - codex, coderabbit 両方の案内が存在"
  - validated: 2025-12-23T17:00:00

- [x] **p_final.3**: docs/ai-orchestration.md にオーケストレーション自動化の説明が追加されている
  - executor: orchestrator
  - validations:
    - technical: "PASS - grep -q 'オーケストレーション自動化' docs/ai-orchestration.md"
    - consistency: "PASS - pm.md, executor-guard.sh と整合"
    - completeness: "PASS - フロー全体が説明されている"
  - validated: 2025-12-23T17:00:00

**status**: done
**max_iterations**: 3

---

## final_tasks

- [x] **ft1**: repository-map.yaml を更新する
  - command: `bash .claude/hooks/generate-repository-map.sh`
  - status: done

- [x] **ft2**: tmp/ 内の一時ファイルを削除する
  - command: `find tmp/ -type f ! -name 'README.md' -delete 2>/dev/null || true`
  - status: done

- [ ] **ft3**: 変更を全てコミットする
  - command: `git add -A && git status`
  - status: pending

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成（M085 オーケストレーション完全自動化） |
