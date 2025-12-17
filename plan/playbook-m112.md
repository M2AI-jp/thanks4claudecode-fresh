# Playbook: M112 - E2E テストの実装

## meta

```yaml
id: playbook-m112
derives_from: M112
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

M109〜M111 で定義したシナリオに対して、実際のテスト手順を実装し、結果を記録する。

---

## phases

### p0: テスト実装

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: docs/e2e-tests/README.md を作成 ✓
- [x] **p0.2**: Test-001 (playbook-guard) の手順を記載 ✓
- [x] **p0.3**: Test-002 (main ブランチブロック) の手順を記載 ✓
- [x] **p0.4**: Test-003 (sed バイパス) の手順を記載 ✓

---

### p1: 結果の記録

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p1.1**: 防げているシナリオを列挙 ✓
- [x] **p1.2**: 防げていないシナリオを正直に記載 ✓
- [x] **p1.3**: 正直な評価を記載 ✓

---

## done_criteria verification

- [x] docs/e2e-tests/ に E2E 手順が実装されている
- [x] 少なくとも 1 つのシナリオで『実際に防げている』ことが確認されている
  - playbook-guard.sh で playbook なし Edit をブロック
  - check-main-branch.sh で main ブランチ作業をブロック
- [x] 少なくとも 1 つのシナリオで『今の設計では防げない』ことが確認されている
  - sed バイパスは防げない
- [x] 『何が出来ていて何が出来ていないか』が率直に書かれている
