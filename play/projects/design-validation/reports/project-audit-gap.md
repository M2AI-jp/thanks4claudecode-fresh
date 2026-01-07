# Playbook vs Project 監査機能 Gap 分析

> Generated: 2026-01-07
> Playbook: audit-verification (p2.1, p2.2)
> Purpose: project 生成時のチェックフロー Gap を特定し、修正提案を作成

---

## 1. 概要

playbook 生成時には複数の検証ステップ（prompt-analyzer → understanding-check → reviewer）が存在するが、project 生成時には同等の検証が不足している。この Gap を解消することで、project 階層でも報酬詐欺を防止できる。

---

## 2. チェックフロー比較表

### 2.1 生成時チェック

| チェック機能 | Playbook 生成時 | Project 生成時 | Gap |
|-------------|----------------|----------------|-----|
| prompt-analyzer | ✅ 5W1H + リスク + 曖昧さ分析 | ❌ なし | **Gap** |
| understanding-check | ✅ ユーザー確認（AskUserQuestion） | ❌ なし | **Gap** |
| executor-resolver | ✅ executor アサイン | ❌ N/A（project 単位では不要） | - |
| reviewer | ✅ 4QV+ 検証（PASS 必須） | ❌ なし | **Critical Gap** |
| meta.reviewed | ✅ plan.json に存在 | ❌ project.json にない | **Gap** |
| meta.reviewed_by | ✅ plan.json に存在 | ❌ project.json にない | **Gap** |

### 2.2 完了時チェック

| チェック機能 | Playbook 完了時 | Project/Milestone 完了時 | Gap |
|-------------|----------------|------------------------|-----|
| critic | ✅ done_when の証拠ベース検証 | ❓ milestone 完了時は未定義 | **要定義** |
| subtask-guard | ✅ validations 全 PASS + validated_by: critic | ❌ milestone に対応なし | **Gap** |
| p_final reviewer | ✅ 独立検証 | ❌ なし | **Gap** |

### 2.3 運用時ガード

| ガード機能 | Playbook 運用時 | Project 運用時 | Gap |
|-----------|----------------|----------------|-----|
| playbook-guard | ✅ playbook なしで編集禁止 | ✅ 同じ（playbook 必須） | - |
| depends-check | ✅ phase 依存確認 | ❌ milestone 依存確認なし | Low Gap |
| scope-guard | ✅ scope.excludes チェック | ❌ project scope なし | Low Gap |

---

## 3. Gap 詳細分析

### 3.1 Critical Gap: reviewer チェックなし

**現状**:
```
pm SubAgent → project.json 作成 → state.md 更新
```

**問題**:
- project.json が直接作成され、第三者検証がない
- 報酬詐欺（架空の milestone 追加等）が可能
- playbook では pm が作成 → reviewer が検証という「作成者 ≠ 検証者」原則があるが、project にはない

**影響**: High - 報酬詐欺防止の根幹が欠落

### 3.2 Gap: meta.reviewed フィールドなし

**現状**:
```json
// playbook plan.json
{
  "meta": {
    "reviewed": true,
    "reviewed_by": "reviewer"
  }
}

// project.json
{
  "meta": {
    "id": "...",
    "title": "...",
    // reviewed フィールドなし
  }
}
```

**問題**:
- project が検証済みかどうかを判別できない
- 監査証跡が残らない

**影響**: Medium - 監査トレーサビリティの欠如

### 3.3 Gap: prompt-analyzer / understanding-check なし

**現状**:
- project 作成時に 5W1H 分析やユーザー確認がない
- playbook-init を経由せず pm が直接 project を作成

**問題**:
- 曖昧な要件で project が作成される可能性
- ユーザーの意図と乖離した project が作成される可能性

**影響**: Medium - 要件品質の低下

### 3.4 Low Gap: milestone 依存確認なし

**現状**:
- milestone 間の depends_on が project.json に存在するが、強制されていない

**問題**:
- m2 が m1 完了前に開始される可能性

**影響**: Low - 現状は運用で回避可能

---

## 4. 修正提案

### 4.1 Critical: project 用 reviewer チェック追加

**修正箇所**: `.claude/skills/golden-path/agents/pm.md`

**修正内容**:
```markdown
## Project 階層サポート（M090）

### Project 作成フロー（修正後）

1. project.json ドラフト作成
2. **【新規】reviewer を呼び出し**
   → Task(subagent_type="reviewer", prompt="project をレビュー")
   → PASS: 次のステップへ
   → FAIL: 問題点を修正して再レビュー（最大3回）
3. meta.reviewed = true, meta.reviewed_by = "reviewer" を設定
4. state.md 更新（project.active 設定）
```

**検証基準**: playbook と同じ 4QV+ フレームワークを使用
- 形式的正当性: milestones 配列の構造
- 内容的妥当性: goal の具体性
- 整合性: state.md との整合
- 完全性: 必須フィールドの存在
- 報酬詐欺: 架空 milestone がないか

### 4.2 Medium: project.json テンプレートへの meta.reviewed 追加

**修正箇所**: `play/projects/template/project.json`

**修正内容**:
```json
{
  "meta": {
    "id": "",
    "title": "",
    "created": "",
    "status": "draft",
    "reviewed": false,
    "reviewed_by": "",
    "closed_at": "",
    "closed_by": ""
  }
}
```

### 4.3 Medium: design-validation project.json への meta.reviewed 追加

**修正箇所**: `play/projects/design-validation/project.json`

**修正内容**:
```json
{
  "meta": {
    "id": "design-validation",
    "title": "Design Validation Project",
    "created": "2026-01-07",
    "status": "active",
    "reviewed": true,
    "reviewed_by": "reviewer",
    "closed_at": "",
    "closed_by": ""
  }
}
```

### 4.4 Low: milestone 依存 guard（将来）

**修正箇所**: `.claude/skills/playbook-gate/guards/` に新規 `milestone-depends-check.sh`

**優先度**: Low（現状は運用で回避可能）

---

## 5. 実装計画

| 順序 | 修正内容 | ファイル | 優先度 |
|------|----------|----------|--------|
| 1 | project.json テンプレートに meta.reviewed 追加 | `play/projects/template/project.json` | p3.1 |
| 2 | pm.md に project 用 reviewer チェック追加 | `.claude/skills/golden-path/agents/pm.md` | p3.2 |
| 3 | design-validation project.json に meta.reviewed 追加 | `play/projects/design-validation/project.json` | p3.3 |

---

## 6. 結論

### 主な Gap
1. **Critical**: project 生成時の reviewer チェックがない
2. **Medium**: meta.reviewed / meta.reviewed_by フィールドがない
3. **Medium**: prompt-analyzer / understanding-check がない（project 作成時）
4. **Low**: milestone 依存確認がない

### 推奨アクション
p3 で以下を実装:
1. project.json テンプレートに meta.reviewed フィールド追加
2. pm.md に project 用 reviewer 呼び出しステップ追加
3. design-validation project.json を更新

### 報酬詐欺防止の効果
- Before: project 作成時に検証なし → 架空 milestone 追加可能
- After: reviewer 検証必須 → 第三者チェックで防止
