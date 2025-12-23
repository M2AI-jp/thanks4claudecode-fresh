# 計画の連鎖的導出システム - 設計ドキュメント

> **playbook → phase の二層構造で計画を管理する**

---

## 概要

このドキュメントは、playbook ベースの計画管理システムの設計を説明します。

```
ユーザー要求
  ↓ pm SubAgent が分析
Playbook
  ↓ Phase に分割
Phase
  ↓ Claude が実行
Action
```

---

## 1. playbook の構造

### 基本構造

```yaml
# playbook-{name}.md

meta:
  branch: {ブランチ名}
  created: {日付}
  reviewed: {true/false}

goal:
  summary: {一言で何を達成するか}
  done_when:
    - {達成条件 1}
    - {達成条件 2}

phases:
  - id: p1
    name: {Phase 名}
    goal: {Phase の目標}
    done_criteria:
      - {完了条件 1}
      - {完了条件 2}
    status: pending
```

### done_criteria のルール

```yaml
done_criteria の要件:
  - 具体的で検証可能
  - grep/ls/実行結果で確認できる
  - 曖昧な表現を避ける

良い例:
  - "grep 'project.md' setup/playbook-setup.md が 0 件"
  - "pnpm build が成功する"
  - "src/components/Button.tsx が存在する"

悪い例:
  - "コードがきれいになっている"
  - "パフォーマンスが改善している"
  - "ユーザーが使いやすい"
```

---

## 2. 導出フロー

### 全体フロー

```
┌─────────────────────────────────────────────────────────────────┐
│                      セッション開始                              │
│  → state.md を Read                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  playbook チェック                                               │
│  → playbook.active が null か確認                               │
│  → null なら次のタスクを待つ                                     │
│  → あれば現在の Phase を確認                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  ユーザー要求受信                                                │
│  → タスク要求パターンを検出                                      │
│  → pm SubAgent を呼び出し                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  pm による playbook 生成                                         │
│  1. ユーザー要求を分析                                           │
│  2. playbook を作成（goal, phases）                              │
│  3. ブランチを作成                                               │
│  4. state.md を更新                                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  LOOP: Phase 実行                                                │
│  → done_criteria を順次達成                                      │
│  → critic による検証                                             │
│  → status: done に更新                                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  playbook 完了                                                   │
│  → POST_LOOP 発動                                                │
│  → アーカイブ                                                    │
│  → 次のタスクを待つ                                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. pm SubAgent の役割

### 主な責務

```yaml
計画作成:
  trigger:
    - ユーザーがタスクを要求
    - playbook=null の状態
  action:
    1. ユーザー要求を分析
    2. playbook を作成
    3. ブランチを作成
    4. state.md を更新

スコープ管理:
  trigger:
    - done_criteria/done_when の変更を検出
  action:
    - 警告を表示
    - pm 経由での変更を促す

reviewer 連携:
  trigger:
    - playbook 作成完了
  action:
    - reviewer SubAgent を呼び出し
    - PASS なら reviewed: true
```

### 呼び出しパターン

```yaml
自動呼び出し:
  - golden_path: タスク要求時に必ず pm を経由
  - POST_LOOP: playbook 完了後の次タスク導出

手動呼び出し:
  - Task(subagent_type='pm', prompt='playbook を作成')
  - /task-start コマンド
```

---

## 4. state.md との連携

### playbook セクション

```yaml
playbook:
  active: plan/playbook-{name}.md  # または null
  branch: {ブランチ名}             # または null
  last_archived: plan/archive/...
  review_pending: false
```

### goal セクション

```yaml
goal:
  phase: p1                        # 現在の Phase
  done_criteria:
    - 条件 1
    - 条件 2
  note: 補足情報
```

---

## 5. Phase 管理

### ステータス遷移

```
pending → in_progress → done
            ↓
         (critic PASS 必須)
```

### done_criteria の検証

```yaml
検証フロー:
  1. Claude が done_criteria を達成
  2. critic SubAgent を呼び出し
  3. 証拠ベースで検証
  4. PASS → status: done
  5. FAIL → 修正ループ
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-23 | project.md 参照を削除。playbook ベースの二層構造に再設計。 |
| 2025-12-08 | 初版作成 |
