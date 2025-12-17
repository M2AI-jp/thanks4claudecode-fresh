# Playbook: M101 - レガシー project.md の凍結と回復プロジェクトの開始

## meta

```yaml
id: playbook-m101
derives_from: M101
created: 2025-12-18
status: in_progress
branch: recovery-project-m101-m120
```

---

## objective

既存の project.md を「実験の履歴」として保存し、回復専用の project.md を作り直す。

---

## phases

### p0: レガシー project.md のアーカイブ

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p0.1**: plan/project.md を plan/archive/project-v1-legacy.md にコピー ✓
  - validated: 2025-12-18

---

### p1: 新 project.md の作成

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p1.1**: 新しい plan/project.md を回復プロジェクト用に作成 ✓
  - validated: 2025-12-18
- [x] **p1.2**: meta/vision/milestones セクションを全て記載 ✓
  - validated: 2025-12-18

---

### p2: state.md の更新

```yaml
status: done
executor: claudecode
```

**subtasks:**
- [x] **p2.1**: state.md の focus.current を回復プロジェクトに変更 ✓
  - validated: 2025-12-18
- [x] **p2.2**: state.md の playbook.active を playbook-m101.md に設定 ✓
  - validated: 2025-12-18
- [x] **p2.3**: state.md の goal.milestone を M101 に設定 ✓
  - validated: 2025-12-18

---

## done_criteria verification

- [x] 既存の plan/project.md が plan/archive/project-v1-legacy.md として保存されている
- [x] 新しい plan/project.md が作成され、回復プロジェクト用の構造になっている
- [x] vision が『回復プロジェクト』専用の内容になっている
- [x] state.md が新しい project.md を参照している
