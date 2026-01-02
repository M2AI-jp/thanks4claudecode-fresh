# project-{name}.md

> **プロジェクト全体を定義するテンプレート。**
>
> playbook よりも上位の計画単位。複数の playbook を束ねる。

---

## meta

```yaml
project: {プロジェクト名}
created: {作成日}
status: planning | active | paused | completed | archived
```

---

## goal

```yaml
summary: {1行のプロジェクト目標}
done_when:
  - {最終完了条件1}
  - {最終完了条件2}
```

---

## milestones

### M1: {マイルストーン名}

```yaml
id: M1
goal: {このマイルストーンの目標}
status: pending | in_progress | done
```

### M2: {マイルストーン名}

```yaml
id: M2
goal: {このマイルストーンの目標}
depends_on: [M1]
status: pending
```

---

## playbooks

```yaml
- id: playbook-{name}-01
  derives_from: M1
  status: pending | active | completed
  path: plan/playbook-{name}-01.md

- id: playbook-{name}-02
  derives_from: M1
  status: pending
  path: plan/playbook-{name}-02.md

- id: playbook-{name}-03
  derives_from: M2
  status: pending
  path: plan/playbook-{name}-03.md
```

---

## playbook 連携ルール

### 作成フロー

```yaml
flow:
  1: project 作成 → milestones 定義
  2: milestone ごとに playbook を作成（derives_from で紐付け）
  3: playbook は 1 つずつ active にして実行
```

### 進捗管理

```yaml
状態更新タイミング:
  playbook: phase 完了時・critic PASS 時に status 更新
  milestone: 配下の全 playbook が completed → done に変更
  project: 全 milestone が done → completed に変更

禁止:
  - 複数 playbook の同時 active
  - milestone/project status の先行更新
```

### 完了条件

```yaml
playbook_done: critic が全 done_criteria に PASS
milestone_done: derives_from が一致する全 playbook が completed
project_done: 全 milestone が done かつ goal.done_when を満たす
```

---

## コンテキスト管理

```yaml
context_budget:
  total_limit: 200k tokens
  baseline_overhead: 50k tokens  # 主要ファイル群
  threshold_warn: 70%            # 警告表示
  threshold_block: 90%           # /clear 推奨

skill_reference: context-management
  # .claude/skills/context-management/SKILL.md 参照

on_warning:
  - /compact で不要な履歴を圧縮
  - 完了済み Phase 詳細を削除候補に

on_block:
  - /clear でリセット
  - state.md を再読して再開（SSOT）
```

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-02 | コンテキスト管理セクション追加（p2.3） |
| 2026-01-02 | 初版作成（harness-self-awareness playbook p2） |
