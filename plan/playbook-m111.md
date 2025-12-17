# Playbook: M111 - 3層自動運用の実装範囲の再定義

## meta

```yaml
id: playbook-m111
derives_from: M111
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

3層自動運用が「設計だけ」なのか「どこまで実装済み」かを冷静に棚卸しする。

---

## phases

### p0: 実装状況の棚卸し

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: docs/three-layer-system.md を作成 ✓
- [x] **p0.2**: 各層（project/playbook/phase）の実装状況を記載 ✓
- [x] **p0.3**: 自動化の境界を明確化 ✓
- [x] **p0.4**: 過剰な期待の削除すべき記述を特定 ✓
- [x] **p0.5**: pm SubAgent の現実的な責務を記載 ✓

---

## done_criteria verification

- [x] docs/three-layer-system.md が作成されている
- [x] implemented / planned / not-planned が一覧化されている
- [x] 過剰な期待表現が特定されている
- [x] pm SubAgent の仕様が現実的な責務に合わせて記載されている
