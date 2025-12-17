# Playbook: M103 - フレームワーク vs ワークスペースの分離方針を決める

## meta

```yaml
id: playbook-m103
derives_from: M103
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

フレームワーク層とプロダクト層の責務を明確に分離する方針を定義する。

---

## phases

### p0: 分離方針ドキュメントの作成

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: docs/product-vs-framework.md を作成 ✓
- [x] **p0.2**: framework/workspace/setup の定義を記載 ✓
- [x] **p0.3**: focus.current の候補値を整理 ✓

---

### p1: state-initial.md の更新

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p1.1**: plan/template/state-initial.md を新しい focus 構造に更新 ✓
- [x] **p1.2**: security-modes.md への参照を追加 ✓
- [x] **p1.3**: product-vs-framework.md への参照を追加 ✓

---

## done_criteria verification

- [x] docs/product-vs-framework.md が存在
- [x] フレームワーク層とプロダクト層の責務が定義されている
- [x] state.md の focus.current の候補値が整理されている
- [x] plan/template/state-initial.md が新しい focus 構造に更新されている
