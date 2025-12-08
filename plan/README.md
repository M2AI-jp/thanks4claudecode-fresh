# plan/

> **計画管理ディレクトリ。開発用と新規ユーザー用が併存。**

---

## 構造

```
plan/
├── README.md                # このファイル
├── project.md               # 開発用: 現在のリポジトリの Macro 計画
├── active/                  # 開発用: 進行中の playbook
│   ├── .gitkeep
│   └── playbook-*.md
└── template/                # 新規ユーザー用: テンプレート群
    ├── project-format.md    # project.md 生成テンプレート
    ├── playbook-format.md   # playbook 作成テンプレート
    ├── state-initial.md     # state.md 初期状態
    └── ...
```

---

## 用途別説明

### 開発者向け（このリポジトリを完成させる）

- `plan/project.md`: Macro 計画（最終目標と done_when）
- `plan/active/`: 進行中の playbook
- 作業完了後は playbook を `.archive/plan/` に移動

### 新規ユーザー向け（フォーク後に 0 から開始）

- フォーク直後は `plan/project.md` が存在しない
- `setup/playbook-setup.md` に従って環境構築
- Phase 8 完了後、`plan/template/project-format.md` を基に `plan/project.md` が生成される
- `plan/template/` のテンプレートを使って playbook を作成

---

## 公開前チェックリスト

リポジトリを公開する前に以下を実行:

```bash
# 開発用ファイルを archive に移動
mv plan/project.md .archive/plan/
mv plan/active/playbook-*.md .archive/plan/active/

# state.md を初期状態にリセット
cp plan/template/state-initial.md state.md

# 確認
ls plan/active/  # .gitkeep のみ
ls plan/project.md  # 存在しない
```

---

## 関連ファイル

| ファイル | 役割 |
|---------|------|
| `plan/template/project-format.md` | project.md 生成テンプレート |
| `plan/template/playbook-format.md` | playbook 作成テンプレート |
| `plan/template/state-initial.md` | state.md 初期状態 |
| `setup/playbook-setup.md` | 新規ユーザー向けセットアップガイド |
