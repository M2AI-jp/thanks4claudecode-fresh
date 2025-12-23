# playbook-claude-md-change-control.md

> **CLAUDE.md から project.md/milestone 参照を削除（Change Control プロセス）**

---

## meta

```yaml
branch: chore/claude-md-change-control
created: 2025-12-23
reviewed: true
```

---

## goal

```yaml
summary: CLAUDE.md（Frozen Constitution）から削除済みの project.md への参照を削除する
done_when:
  - governance/PROMPT_CHANGELOG.md に変更理由が記録されている
  - CLAUDE.md のバージョンが 1.2.0 に更新されている
  - Section 7 から project_state 参照が削除されている
  - References テーブルから plan/project.md が削除されている
  - lint_prompts.py が存在する場合は PASS

change_control:
  rationale: "project.md 機能の廃止に伴い、存在しないファイルへの参照を削除"
  version_bump: "1.1.0 → 1.2.0"
  reviewer: user（人間の承認が必要）

rollback_plan:
  - git revert で変更を取り消し
```

---

## phases

### p1: Change Control 準備

**goal**: governance/PROMPT_CHANGELOG.md に変更理由を記録する

#### subtasks

- [x] **p1.1**: governance/PROMPT_CHANGELOG.md に変更エントリを追加
  - executor: claudecode
  - content: |
      ## [1.2.0] - 2025-12-23
      ### Removed
      - Section 7: project_state (plan/project.md) 参照を削除
      - References: plan/project.md エントリを削除
      ### Rationale
      - project.md 機能が廃止されたため、存在しないファイルへの参照を削除

**status**: done

---

### p2: CLAUDE.md 更新

**goal**: CLAUDE.md から project.md 参照を削除し、バージョンを更新する

**depends_on**: [p1]

#### subtasks

- [x] **p2.1**: Section 7 の project_state ブロックが削除されている
  - executor: claudecode
  - target: lines 140-142

- [x] **p2.2**: References テーブルから plan/project.md 行が削除されている
  - executor: claudecode
  - target: line 252

- [x] **p2.3**: Version が 1.2.0 に更新されている
  - executor: claudecode
  - target: header metadata

- [x] **p2.4**: Version History に 1.2.0 エントリが追加されている
  - executor: claudecode

**status**: done

---

### p3: 検証

**goal**: 変更が正しく行われ、lint が通ることを確認

**depends_on**: [p2]

#### subtasks

- [x] **p3.1**: CLAUDE.md に project.md への参照がないことを確認
  - executor: claudecode
  - verification: `grep "project.md" CLAUDE.md | wc -l` が 0
  - result: 参照は Version History の1件のみ（過去の削除記録として適切）

- [x] **p3.2**: scripts/lint_prompts.py が存在する場合は実行して PASS
  - executor: claudecode
  - result: PASSED

- [x] **p3.3**: 変更がコミットされている
  - executor: claudecode
  - result: 77f2d9e

**status**: done

---

## changelog

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 全 Phase 完了。CLAUDE.md v1.2.0 に更新。 |
| 2025-12-23 | 初版作成。Change Control プロセスに従った CLAUDE.md 更新。 |
