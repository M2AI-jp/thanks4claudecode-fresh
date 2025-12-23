---
description: project.md から新しいタスクを開始。pm SubAgent を呼び出し playbook を作成する標準フロー。
allowed-tools: Read, Write, Edit, Bash, Task
---

# /task-start - project.md からタスクを開始

> **標準タスク開始コマンド。全てのタスクは project.md からの導出を経由する。**
>
> pm SubAgent を呼び出し、project.md の done_when から playbook を作成する。

---

## 設計思想

```yaml
品質の一貫性:
  - 全タスクが project.md から導出される
  - derives_from が必ず設定される
  - 直接 playbook を作成することは禁止

pm 経由の強制:
  - pm SubAgent がタスク開始の必須経由点
  - project.md の参照を構造的に保証
  - ブランチ作成も pm が実行
```

---

## フロー

```
┌─────────────────────────────────────────────────────────────┐
│ ユーザー: /task-start または「〇〇を実装して」               │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 1: project.md 参照                                     │
│   - plan/project.md の done_when を読み込み                 │
│   - not_achieved のタスクを一覧表示                         │
│   - depends_on を解決して着手可能なタスクを特定             │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: タスク選択                                          │
│   - ユーザーの要求に最も近い done_when を特定               │
│   - 該当なし → project.md に新規 done_when を追加           │
│   - 複数候補 → ユーザーに選択を促す                         │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 3: ブランチ作成                                        │
│   - feat/{done_when.name の kebab-case} でブランチ作成      │
│   - main からの分岐を確認                                   │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 4: playbook 作成                                       │
│   - derives_from: {done_when.id} を必須設定                 │
│   - decomposition を参照して Phase を構成                   │
│   - plan/playbook-{name}.md を作成                          │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 5: state.md 更新                                       │
│   - active_playbooks.product を更新                         │
│   - goal を更新                                             │
│   - verification.self_complete を false に                  │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 6: LOOP 開始                                           │
│   - Phase 1 から作業開始                                    │
│   - done_criteria に従って進行                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 実行手順

### 1. project.md の確認

```bash
echo "=== project.md の done_when ===" && \
grep -A5 "status: not_achieved" plan/project.md | head -30
```

### 2. 着手可能なタスクの特定

以下の条件を満たす done_when を特定：
- status: not_achieved
- depends_on の全てが achieved

### 3. playbook 作成（pm を呼び出す）

```
Task(subagent_type="pm", prompt="
  ユーザーの要求: {要求内容}

  以下の手順で playbook を作成してください:
  1. project.md の done_when から最も適切なものを選択
  2. derives_from を設定
  3. decomposition を参照して Phase を構成
  4. ブランチを作成
  5. state.md を更新
")
```

---

## derives_from の重要性

```yaml
derives_from の設定:
  必須: 全ての playbook は derives_from を持つ
  形式: derives_from: project.md / {セクション名} / {done_when.id}
  目的:
    - タスクと上位計画の紐付け
    - 完了時に project.md の status を自動更新
    - トレーサビリティの確保

例:
  derives_from: project.md / system_completion / dw_sc_1_task_standardization
  derives_from: project.md / engineering_ecosystem / dw_2_linter_formatter
```

---

## project.md に該当タスクがない場合

```yaml
新規 done_when の追加フロー:
  1. ユーザーの要求を分析
  2. 適切なセクションを特定（または新規作成）
  3. done_when を追加:
     - name: タスク名
     - status: not_achieved
     - description: 詳細説明
     - depends_on: 依存タスク
     - decomposition: 分解項目
  4. playbook を作成（derives_from を設定）

注意:
  - project.md の変更は pm が行う
  - ユーザーの許可なく勝手に追加しない
  - 既存の done_when で代替できないか先に検討
```

---

## 禁止事項

```
❌ pm を経由せずに playbook を作成
❌ derives_from なしの playbook 作成
❌ project.md を参照せずにタスク開始
❌ main ブランチでの直接作業
❌ 既存の in_progress playbook を無視して新規作成
```

---

## 旧コマンドとの関係

```yaml
/task-start:
  役割: 標準タスク開始（project.md 経由必須）
  推奨: 全ての新規タスクで使用

/playbook-init:
  役割: 旧互換（直接 playbook 作成）
  非推奨: /task-start を使用すること
  動作: 内部的に /task-start と同じフローを実行
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。project.md からの導出を強制するタスク開始コマンド。 |
