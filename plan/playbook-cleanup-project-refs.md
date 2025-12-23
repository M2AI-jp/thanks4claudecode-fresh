# playbook-cleanup-project-refs.md

> **残存する project.md 参照を削除**

---

## meta

```yaml
branch: chore/cleanup-project-refs
created: 2025-12-23
reviewed: true
```

---

## goal

```yaml
summary: hooks と docs から project.md 参照を削除
done_when:
  - .claude/hooks/ 内の project.md コメントが削除されている
  - docs/ 内の project.md 参照が削除または更新されている
  - plan/design/ 内の project.md 参照が更新されている
```

---

## phases

### p1: hooks のコメント修正

**goal**: .claude/hooks/ 内の古いコメントを削除

#### subtasks

- [x] **p1.1**: session-start.sh のコメント修正
- [x] **p1.2**: scope-guard.sh のコメント修正

**status**: done

---

### p2: docs の修正

**goal**: docs/ 内の project.md 参照を削除

#### subtasks

- [x] **p2.1**: extension-system.md の修正
- [x] **p2.2**: git-operations.md の修正
- [x] **p2.3**: artifact-management-rules.md の修正

**status**: done

---

### p3: plan/design の修正

**goal**: 設計ドキュメントを playbook ベースに更新

#### subtasks

- [x] **p3.1**: plan/design/README.md の修正
- [x] **p3.2**: plan/design/plan-chain-system.md の修正
- [x] **p3.3**: plan/design/mission.md の修正

**status**: done

---

### p4: 検証

**goal**: 残存参照がないことを確認

#### subtasks

- [x] **p4.1**: grep で確認
  - executor: claudecode
  - validations:
    - technical: "PASS - grep 結果は変更履歴/サンプル/廃止ドキュメントのみ"
    - consistency: "PASS - done_when の基準と一致"
    - completeness: "PASS - 全対象ディレクトリを検証済み"
  - validated: 2025-12-23T17:30:00
- [x] **p4.2**: コミット
  - executor: claudecode
  - validations:
    - technical: "PASS - git commit 929c8f9 成功"
    - consistency: "PASS - playbook branch と一致"
    - completeness: "PASS - 全変更がコミット済み"
  - validated: 2025-12-23T17:35:00

**status**: done
