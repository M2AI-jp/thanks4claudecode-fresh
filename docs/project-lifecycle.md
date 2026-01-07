# Project Lifecycle 設計書

> **Project と Playbook は別サイクルとして管理する**
>
> 本設計書は archive-project.sh の仕様、テンプレート構成、生成ロジックを定義する。

---

## 1. Project Lifecycle 概要

### 1.1 階層構造

```
Project (optional)
├── goal: summary, done_when
├── milestones[]
│   └── playbooks[]
│       └── phases[]
│           └── subtasks[]
└── progress: 進捗管理
```

### 1.2 ディレクトリ構造

```yaml
現行 project:
  play/projects/<project-id>/
  ├── project.json       # Project 定義
  ├── playbooks/         # 関連 playbook（pm が作成）
  │   └── <playbook-id>/
  │       ├── plan.json
  │       └── progress.json
  └── reports/           # 成果物（optional）

アーカイブ済み project:
  play/archive/projects/<project-id>/
  ├── project.json       # closed_at, closed_by 設定済み
  ├── playbooks/         # アーカイブ済み playbook
  └── reports/
```

### 1.3 Playbook との関係

| 項目 | Project | Playbook |
|------|---------|----------|
| 粒度 | 大きな目標（複数 playbook） | 具体的なタスク（複数 phase） |
| 完了条件 | 全 playbook done | 全 phase done |
| アーカイブ | archive-project.sh | archive-playbook.sh |
| トリガー | 最後の playbook 完了時 | phase 完了時 |

---

## 2. Status 遷移図

### 2.1 Project Status

```
                  ┌─────────┐
                  │  draft  │ ← 作成直後
                  └────┬────┘
                       │ reviewer PASS
                       ▼
                  ┌─────────┐
                  │ active  │ ← 運用中
                  └────┬────┘
                       │ 全 playbook done
                       ▼
                  ┌─────────┐
                  │ closed  │ ← 完了（アーカイブ前）
                  └────┬────┘
                       │ archive-project.sh
                       ▼
              ┌───────────────┐
              │ (archived)    │ ← play/archive/projects/ に移動
              └───────────────┘
```

### 2.2 Status 定義

| Status | 説明 | 条件 |
|--------|------|------|
| `draft` | 作成直後 | pm が project.json を作成 |
| `active` | 運用中 | reviewer PASS 後 |
| `closed` | 完了 | 全 playbook.status == done |
| (archived) | アーカイブ済み | play/archive/projects/ に移動後 |

### 2.3 Milestone Status

```yaml
pending:    開始前
in_progress: 進行中（1つ以上の playbook が in_progress）
done:       完了（全 playbook が done）
skipped:    スキップ（明示的にスキップ）
```

### 2.4 Playbook Status（project.json 内）

```yaml
pending:    未着手
in_progress: 進行中
done:       完了（archive-playbook.sh が更新）
```

---

## 3. archive-project.sh 入出力仕様

### 3.1 概要

```yaml
ファイル: .claude/skills/playbook-gate/workflow/archive-project.sh
目的: Project の完了処理とアーカイブを行う
トリガー: archive-playbook.sh の最後で呼び出し（条件付き）
```

### 3.2 入力

```yaml
引数:
  $1: PROJECT_ID（必須）

環境:
  - state.md が存在すること
  - play/projects/<PROJECT_ID>/project.json が存在すること
  - jq コマンドが利用可能であること
```

### 3.3 処理フロー

```
Step 1: Project 存在確認
        └── play/projects/<id>/project.json が存在するか

Step 2: 完了判定
        └── 全 milestone.playbooks[].status == "done" か確認
        └── done でない playbook がある場合は早期終了（exit 0）

Step 3: project.json 更新
        ├── meta.status = "closed"
        ├── meta.closed_at = ISO8601 タイムスタンプ
        └── meta.closed_by = "archive-project.sh"

Step 4: アーカイブ
        └── mv play/projects/<id>/ play/archive/projects/<id>/

Step 5: state.md 更新
        ├── project.active = null
        ├── project.status = idle
        └── project.current_milestone = null

Step 6: Git 操作
        ├── git add -A
        └── git commit -m "chore: archive project <id>"

Step 7: 完了ログ出力
```

### 3.4 出力

```yaml
成功時:
  stdout: JSON 形式のステータス
  exit_code: 0

失敗時:
  stderr: エラーメッセージ
  exit_code: 1（エラー）または 0（早期終了）
```

### 3.5 出力 JSON 例

```json
{
  "status": "success",
  "project_id": "design-validation",
  "archived_to": "play/archive/projects/design-validation",
  "message": "Project アーカイブ完了"
}
```

---

## 4. archive-playbook.sh との連携フロー

### 4.1 フロー図

```
[archive-playbook.sh]
        │
        ├── Step 1-12: 既存の playbook アーカイブ処理
        │   └── playbook を play/archive/.../playbooks/<id>/ へ移動
        │
        └── Step 13: pending ファイル作成
                │
                ▼
[新規追加: Project 完了チェック]
        │
        ├── parent_project が null → 何もしない
        │
        └── parent_project が存在
                │
                ├── play/projects/<id>/project.json を確認
                │
                └── 全 playbook done?
                        │
                        ├── NO → 何もしない（残り playbook あり）
                        │
                        └── YES → archive-project.sh 呼び出し
                                    └── Project アーカイブ
```

### 4.2 追加ロジック（archive-playbook.sh への追加）

```bash
# ==============================================================================
# Step 14: Project 完了チェック（M090 連携）
# ==============================================================================

if [ -n "$PARENT_PROJECT" ] && [ "$PARENT_PROJECT" != "null" ]; then
    PROJECT_FILE="play/projects/$PARENT_PROJECT/project.json"

    if [ -f "$PROJECT_FILE" ]; then
        # 残り playbook をチェック
        REMAINING=$(jq '[.milestones[].playbooks[] | select(.status != "done")] | length' "$PROJECT_FILE" 2>/dev/null || echo "-1")

        if [ "$REMAINING" = "0" ]; then
            log_info "全 playbook 完了。Project をアーカイブします..."
            ARCHIVE_PROJECT_SCRIPT="$SKILLS_DIR/playbook-gate/workflow/archive-project.sh"

            if [ -x "$ARCHIVE_PROJECT_SCRIPT" ]; then
                bash "$ARCHIVE_PROJECT_SCRIPT" "$PARENT_PROJECT" || log_warn "Project アーカイブに失敗しました"
            fi
        else
            log_info "残り playbook: $REMAINING 件（Project は継続）"
        fi
    fi
fi
```

### 4.3 呼び出し条件

| 条件 | 結果 |
|------|------|
| parent_project == null | スキップ（単発 playbook） |
| parent_project 存在 & 残り playbook > 0 | スキップ（継続） |
| parent_project 存在 & 残り playbook == 0 | archive-project.sh 呼び出し |

---

## 5. テンプレート構成

### 5.1 project.json テンプレート

**場所**: `play/projects/template/project.json`

```json
{
  "format_version": "1.0",
  "meta": {
    "id": "example-project",
    "title": "Project Title",
    "created": "YYYY-MM-DD",
    "status": "draft",
    "reviewed": false,
    "reviewed_by": "",
    "closed_at": null,
    "closed_by": null
  },
  "goal": {
    "summary": "High-level objective description.",
    "done_when": [
      "Condition 1 is met.",
      "Condition 2 is met."
    ]
  },
  "milestones": [
    {
      "id": "m1",
      "title": "Milestone 1",
      "order": 1,
      "status": "pending",
      "description": "Milestone description.",
      "playbooks": [
        {
          "id": "pb-001",
          "title": "First playbook",
          "status": "pending",
          "path": null
        }
      ]
    }
  ],
  "progress": {
    "total_playbooks": 1,
    "completed_playbooks": 0,
    "current_milestone": null,
    "current_playbook": null
  }
}
```

### 5.2 フィールド定義

#### meta セクション

| フィールド | 型 | 説明 | 設定タイミング |
|------------|---|------|----------------|
| id | string | Project ID（ディレクトリ名と一致） | 作成時 |
| title | string | Project タイトル | 作成時 |
| created | string | 作成日（YYYY-MM-DD） | 作成時 |
| status | string | draft/active/closed | 各フェーズ |
| reviewed | boolean | reviewer 検証済みフラグ | reviewer PASS 時 |
| reviewed_by | string | 検証者（"reviewer"） | reviewer PASS 時 |
| closed_at | string/null | 完了日時（ISO8601） | archive-project.sh |
| closed_by | string/null | 完了処理者 | archive-project.sh |

#### goal セクション

| フィールド | 型 | 説明 |
|------------|---|------|
| summary | string | Project の目的（1-2文） |
| done_when | string[] | 完了条件のリスト |

#### milestones セクション

| フィールド | 型 | 説明 |
|------------|---|------|
| id | string | Milestone ID（m1, m2, ...） |
| title | string | Milestone タイトル |
| order | number | 実行順序 |
| status | string | pending/in_progress/done/skipped |
| description | string | Milestone の説明（optional） |
| playbooks | object[] | 関連 playbook リスト |

#### playbooks（milestone 内）

| フィールド | 型 | 説明 |
|------------|---|------|
| id | string | Playbook ID |
| title | string | Playbook タイトル |
| status | string | pending/in_progress/done |
| path | string/null | playbook のパス（作成後に設定） |

#### progress セクション

| フィールド | 型 | 説明 |
|------------|---|------|
| total_playbooks | number | 全 playbook 数 |
| completed_playbooks | number | 完了 playbook 数 |
| current_milestone | string/null | 現在の milestone ID |
| current_playbook | string/null | 現在の playbook ID |

---

## 6. 生成ロジック

### 6.1 Project 作成フロー（pm SubAgent）

```
1. ユーザー要求が「大規模タスク」と判定された場合
   └── prompt-analyzer の multi_topic_detection.topic_count > 2

2. pm が project 作成を提案
   └── ユーザー確認

3. project.json 作成
   ├── play/projects/<id>/project.json
   ├── テンプレートをコピー
   ├── meta.id, meta.title, meta.created を設定
   └── goal.summary, goal.done_when を設定

4. reviewer 検証
   └── PASS: meta.reviewed = true, meta.reviewed_by = "reviewer"

5. state.md 更新
   ├── project.active = play/projects/<id>/project.json
   ├── project.status = in_progress
   └── project.current_milestone = m1
```

### 6.2 Playbook 作成時の project.json 更新

```
1. pm が playbook を作成
   └── play/projects/<id>/playbooks/<pb-id>/

2. project.json の該当 playbook を更新
   ├── playbooks[].status = "in_progress"
   └── playbooks[].path = "play/projects/<id>/playbooks/<pb-id>/plan.json"

3. progress を更新
   └── current_playbook = <pb-id>
```

### 6.3 Playbook 完了時の project.json 更新（archive-playbook.sh）

```
1. archive-playbook.sh の Step 8 で実行

2. project.json の該当 playbook を更新
   └── playbooks[].status = "done"

3. progress を更新
   └── completed_playbooks += 1, current_playbook = null
```

---

## 7. state.md との連携

### 7.1 project セクション

```yaml
project:
  active: play/projects/<id>/project.json  # or null
  current_milestone: m1                     # or null
  status: in_progress                       # null | in_progress | completed | idle
```

### 7.2 更新タイミング

| イベント | active | current_milestone | status |
|----------|--------|-------------------|--------|
| Project 作成 | パス設定 | m1 | in_progress |
| Milestone 完了 | 維持 | 次の milestone | 維持 |
| Project 完了 | null | null | idle |

---

## 8. エラーハンドリング

### 8.1 archive-project.sh のエラーケース

| ケース | 対応 |
|--------|------|
| project.json が存在しない | exit 0（警告のみ） |
| jq コマンドがない | exit 1 |
| 残り playbook がある | exit 0（正常終了、アーカイブなし） |
| mv 失敗 | exit 1 |
| git commit 失敗 | 警告のみ（続行） |

### 8.2 リカバリ

```yaml
手動リカバリ:
  1. project.json の status を確認
  2. 必要に応じて手動で play/archive/projects/ へ移動
  3. state.md を手動更新
```

---

## 9. 関連ファイル

| ファイル | 役割 |
|----------|------|
| .claude/skills/playbook-gate/workflow/archive-project.sh | Project アーカイブ処理 |
| .claude/skills/playbook-gate/workflow/archive-playbook.sh | Playbook アーカイブ処理（連携元） |
| .claude/agents/pm.md | Project 階層サポート（M090）定義 |
| play/projects/template/project.json | Project テンプレート |
| state.md | Project 状態管理 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-08 | 初版作成（project-lifecycle playbook） |
