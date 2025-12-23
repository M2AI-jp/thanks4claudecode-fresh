# project-format.md

> **プロジェクトの根幹計画テンプレート。setup 完了時に `plan/project.md` として生成。**
>
> **3層構造: project（永続）→ playbook（一時）→ phase（作業単位）**

---

## 使い方

1. setup 完了後、LLM がこのテンプレートを参照
2. `plan/project.md` として生成（テンプレート自体は編集しない）
3. milestone に ID（M001, M002, ...）を付与
4. 以降の playbook は `derives_from: M001` で milestone と紐付け

---

## テンプレート

```yaml
# plan/project.md

> **プロジェクトの根幹計画。Claude が3層構造（project → playbook → phase）を自動運用する。**

## meta

project: {プロジェクト名}
created: {YYYY-MM-DD}
status: active  # active | completed

## vision

goal: "{最上位目標を1行で}"

principles:
  - {原則1}
  - {原則2}
  - {原則3}

success_criteria:
  - {成功条件1}
  - {成功条件2}
  - {成功条件3}

## milestones

# milestone には必ず ID を付与する
# playbook は derives_from で milestone ID を参照

- id: M001
  name: "{milestone 名}"
  description: |
    {詳細説明（複数行可）}
  status: not_started  # not_started | in_progress | achieved
  depends_on: []  # 依存する milestone ID のリスト
  playbooks: []   # この milestone を達成した playbook のリスト
  done_when:      # この milestone の完了条件
    - {条件1}
    - {条件2}

- id: M002
  name: "{milestone 名}"
  status: not_started
  depends_on: [M001]  # M001 が完了してから着手可能
  playbooks: []
  done_when:
    - {条件1}

## tech_stack

framework: {フレームワーク}
language: {言語}
deploy: {デプロイ先}
database: {データベース}

## constraints

- {制約条件1}
- {制約条件2}

## 変更履歴

| 日時 | 内容 |
|------|------|
| {YYYY-MM-DD} | 初版作成 |
```

---

## milestone の書き方

### 必須項目

| 項目 | 説明 |
|------|------|
| id | milestone ID（M001, M002, ...） |
| name | milestone 名（短い説明） |
| status | 状態（not_started / in_progress / achieved） |

### オプション項目

| 項目 | 説明 |
|------|------|
| description | 詳細説明 |
| depends_on | 依存する milestone ID のリスト |
| playbooks | この milestone を達成した playbook のリスト |
| done_when | 完了条件のリスト |
| achieved_at | 達成日時（status=achieved 時に自動設定） |

### milestone と playbook の紐付け

```yaml
# project.md
milestones:
  - id: M001
    name: "認証機能実装"
    status: in_progress
    playbooks:
      - playbook-auth-basic.md  # 完了した playbook が追記される

# playbook.md
meta:
  derives_from: M001  # どの milestone に紐づくか
```

---

## 自動更新フロー

```yaml
playbook 完了時:
  1. playbook をアーカイブ
  2. project.milestone を自動更新
     - milestone.status = achieved（全 done_when 達成時）
     - milestone.achieved_at = now()
     - milestone.playbooks[] に playbook 名を追記
  3. 次の milestone を特定（depends_on 分析）
  4. pm で新 playbook を自動作成
```

---

## 3層構造の関係

```
project (永続)
├── vision: 最上位目標
├── milestones[]: 中間目標
│   ├── M001: achieved
│   │   └── playbooks: [playbook-xxx.md]
│   ├── M002: in_progress
│   │   └── playbooks: []
│   └── M003: not_started
│       └── depends_on: [M001, M002]
└── constraints: 制約条件

playbook (一時的)
├── meta.derives_from: M002  # milestone との紐付け
├── goal.done_when: milestone 達成条件
└── phases[]: 作業単位

phase (作業単位)
├── done_criteria[]: 完了条件
├── test_method: 検証手順
└── status: pending | in_progress | done
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | V2.0: 3層構造対応。milestone に ID と詳細構造を追加。自動更新フローを明記。 |
| 2025-12-02 | 初版作成。 |
