# play/ (Playbook v2 - M090)

playbook の **計画/進捗/証拠** を分離して管理するためのディレクトリ。
旧 `plan/playbook-*.md` は使用禁止。

## ディレクトリ構造 (M090)

```
play/
├── projects/                              # project（大規模タスク）
│   ├── template/
│   │   └── project.json                   # project テンプレート
│   └── <project-id>/
│       ├── project.json                   # project 定義
│       └── playbooks/
│           └── <playbook-id>/
│               ├── plan.json              # 計画
│               └── progress.json          # 進捗
│
├── standalone/                            # 単発 playbook（小規模タスク）
│   └── <playbook-id>/
│       ├── plan.json
│       └── progress.json
│
├── template/                              # 共通テンプレート
│   ├── plan.json                          # playbook 計画テンプレート
│   ├── progress.json                      # playbook 進捗テンプレート
│   └── project.json                       # (legacy, projects/template/ を使用)
│
└── archive/                               # 完了後のアーカイブ
    ├── projects/
    │   └── <project-id>/
    │       └── <playbook-id>/
    └── <playbook-id>/                     # standalone アーカイブ
```

## 配置ルール

| タスク規模 | 配置先 | 判定基準 |
|-----------|--------|----------|
| 大規模（project） | `play/projects/<id>/` | milestone が複数、または明示的に project 指定 |
| 小規模（単発） | `play/standalone/<id>/` | 単一タスク、1-2 Phase で完了 |

## 基本ルール

1. **plan と progress を分離**
   plan は「何をするか」、progress は「どう検証したか」を記録する。

2. **証拠はファイルで残す**
   progress の evidence にはファイルパスを記録し、内容は `evidence/` に保存する。

3. **reviewed 後の plan は固定**
   reviewed: true の plan は原則編集禁止（修正は新 playbook）。

4. **review_profile でレビュー深度を指定**
   standard は通常レビュー、system-test は構造チェック中心。

5. **done 判定は progress + critic 依存**
   progress の validations と critic 結果が揃わない限り完了不可。

6. **final_tasks は progress で管理**
   plan の final_tasks と同数のステータスを progress に記録する。

## 参照テンプレート

| テンプレート | 用途 |
|-------------|------|
| `play/projects/template/project.json` | project 作成時 |
| `play/template/plan.json` | playbook 計画 |
| `play/template/progress.json` | playbook 進捗 |

## 関連ドキュメント

- `.claude/skills/golden-path/agents/pm.md` - pm SubAgent（M090 規定）
- `docs/criterion-validation-rules.md` - criterion 検証ルール
