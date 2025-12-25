# playbook-remove-focus.md

## meta

```yaml
project: focus 機能の削除
branch: refactor/remove-focus-feature
created: 2025-12-25
reviewed: false
```

## goal

```yaml
summary: focus 機能を削除し、main ブランチ保護を普遍ルールに変更する
done_when:
  - focus 関連コード・ドキュメントが全て削除されている
  - main ブランチでは常に Edit/Write がブロックされる（focus 不問）
  - テストで動作確認済み
```

## phases

### p1: main-branch.sh の修正

**goal**: focus 判定を削除し、常に main ブロックにする

#### subtasks

- [ ] **p1.1**: main-branch.sh から focus 判定ロジックが削除されている
  - executor: claudecode
  - validations:
    - technical: "setup/product/plan-template の分岐が削除されている"
    - consistency: "exit 0 のフローが main ブロック以外は変わらない"
    - completeness: "focus 関連のコメントも削除されている"

**status**: pending

---

### p2: state.md と関連ファイルの修正

**goal**: focus セクションを削除し、state スキーマを更新する

#### subtasks

- [ ] **p2.1**: state.md から focus セクションが削除されている
  - executor: claudecode
  - validations:
    - technical: "## focus セクション全体が削除されている"
    - consistency: "他セクション（playbook, goal, session, config）は維持"
    - completeness: "YAML 構文が正しい"

- [ ] **p2.2**: plan/template/state-initial.md から focus が削除されている
  - executor: claudecode
  - validations:
    - technical: "focus セクションが削除されている"
    - consistency: "テンプレートとして機能する"
    - completeness: "必須セクションは維持"

- [ ] **p2.3**: .claude/schema/state-schema.sh から focus が削除されている
  - executor: claudecode
  - validations:
    - technical: "focus 関連の変数・関数が削除されている"
    - consistency: "他の state 項目の取得は正常"
    - completeness: "構文エラーがない"

**status**: pending

---

### p3: Skill/Guard ファイルの修正

**goal**: focus 参照を削除し、ロジックを簡素化する

#### subtasks

- [ ] **p3.1**: .claude/skills/state/SKILL.md から focus 説明が削除されている
  - executor: claudecode

- [ ] **p3.2**: .claude/lib/common.sh から focus 関連関数が削除されている
  - executor: claudecode

- [ ] **p3.3**: 各 guard/handler から focus.current 参照が削除されている
  - executor: claudecode
  - files:
    - .claude/skills/playbook-gate/guards/playbook-guard.sh
    - .claude/skills/playbook-gate/guards/executor-guard.sh
    - .claude/skills/session-manager/handlers/init-guard.sh
    - .claude/skills/session-manager/handlers/end.sh
    - .claude/skills/reward-guard/guards/coherence.sh
    - .claude/skills/git-workflow/handlers/merge-pr.sh
    - .claude/skills/quality-assurance/agents/health-checker.md

**status**: pending

---

### p4: コマンド・ドキュメントの修正

**goal**: /focus コマンド削除、ドキュメント更新

#### subtasks

- [ ] **p4.1**: .claude/commands/focus.md が削除されている
  - executor: claudecode

- [ ] **p4.2**: docs/ARCHITECTURE.md から focus 関連記述が削除されている
  - executor: claudecode

- [ ] **p4.3**: RUNBOOK.md から focus 参照が削除されている
  - executor: claudecode

- [ ] **p4.4**: docs/repository-map.yaml が再生成されている
  - executor: claudecode

**status**: pending

---

### p5: 検証

**goal**: 変更が正しく動作することを確認

#### subtasks

- [ ] **p5.1**: main ブランチで Edit がブロックされる
  - executor: claudecode
  - test_command: "focus=setup でも main でブロックされることを確認"

- [ ] **p5.2**: feature ブランチで Edit が許可される
  - executor: claudecode
  - test_command: "現在のブランチで Edit が通ることを確認"

- [ ] **p5.3**: Hook エラーがない
  - executor: claudecode
  - test_command: "session.sh, pre-tool.sh が正常動作"

**status**: pending
