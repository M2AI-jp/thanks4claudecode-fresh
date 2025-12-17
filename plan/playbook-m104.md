# Playbook: M104 - コンポーネント分類の再設計（MECE化）

## meta

```yaml
id: playbook-m104
derives_from: M104
created: 2025-12-18
status: done
branch: recovery-project-m101-m120
```

---

## objective

Hooks/SubAgents/Skills を MECE に再分類し、役割の重複を解消する。

---

## phases

### p0: カテゴリ定義と分類

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: docs/component-taxonomy.md を作成 ✓
- [x] **p0.2**: 7つのカテゴリ（Gate/Observer/Validator/Utility/Planner/Evaluator/Guide）を定義 ✓
- [x] **p0.3**: 全 Hook (29個) を分類 ✓
- [x] **p0.4**: 全 SubAgent (6個) を分類 ✓
- [x] **p0.5**: 全 Skill (8個) を分類 ✓

---

### p1: MECE 検証

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p1.1**: 未分類コンポーネントが 0 であることを確認 ✓
- [x] **p1.2**: 複数カテゴリにまたがるコンポーネントが 0 であることを確認 ✓

---

## done_criteria verification

- [x] docs/component-taxonomy.md が作成されている
- [x] カテゴリ一覧と定義が書かれている
- [x] 1つのコンポーネントが複数カテゴリにまたがっていない
- [x] 未分類コンポーネントが 0 である

Note: repository-map.yaml への category フィールド追加は自動生成スクリプトの更新が必要なため、別 milestone で対応。
