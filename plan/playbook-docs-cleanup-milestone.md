# playbook-docs-cleanup-milestone.md

> **ドキュメントから project.md/milestone 参照を削除**

---

## meta

```yaml
branch: docs/cleanup-milestone-references
created: 2025-12-23
reviewed: true
```

---

## goal

```yaml
summary: ドキュメントファイルから project.md と milestone への参照を削除または更新する
done_when:
  - plan/template/project-format.md が削除されている
  - README.md から project.md/milestone 参照が削除されている
  - docs/ARCHITECTURE.md から project.md/milestone 参照が削除されている
  - docs/current-definitions.md から project/milestone 定義が削除されている
  - docs/folder-management.md から project.md 参照が削除されている
  - plan/README.md から project.md 説明が削除されている

rollback_plan:
  - git revert で変更を取り消し
```

---

## phases

### p1: テンプレート削除

**goal**: 不要になった project-format.md テンプレートを削除する

#### subtasks

- [ ] **p1.1**: plan/template/project-format.md が削除されている
  - executor: claudecode

**status**: pending

---

### p2: README.md 更新

**goal**: README.md から project.md/milestone 参照を削除する

**depends_on**: [p1]

#### subtasks

- [ ] **p2.1**: README.md から project.md への参照が削除されている
  - executor: claudecode

- [ ] **p2.2**: README.md から milestone への参照が更新されている（履歴としての言及は許容）
  - executor: claudecode

**status**: pending

---

### p3: docs/ 更新

**goal**: docs/ 内のファイルから project.md/milestone 参照を削除する

**depends_on**: [p2]

#### subtasks

- [ ] **p3.1**: docs/ARCHITECTURE.md から project.md 参照が削除されている
  - executor: claudecode

- [ ] **p3.2**: docs/current-definitions.md から project/milestone 定義が削除されている
  - executor: claudecode

- [ ] **p3.3**: docs/folder-management.md から project.md 参照が削除されている
  - executor: claudecode

**status**: pending

---

### p4: plan/README.md 更新

**goal**: plan/README.md から project.md の説明を削除する

**depends_on**: [p3]

#### subtasks

- [ ] **p4.1**: plan/README.md から project.md セクションが削除されている
  - executor: claudecode

- [ ] **p4.2**: plan/README.md のディレクトリ構造が更新されている
  - executor: claudecode

**status**: pending

---

### p_final: 検証

**goal**: 全ての変更が正しく完了していることを確認

**depends_on**: [p4]

#### subtasks

- [ ] **p_final.1**: 変更がコミットされている
  - executor: claudecode

**status**: pending

---

## changelog

| 日時 | 内容 |
|------|------|
| 2025-12-23 | 初版作成 |
