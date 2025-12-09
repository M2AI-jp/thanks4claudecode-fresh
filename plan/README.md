# plan/

> **計画管理ディレクトリ。プロジェクトの根幹計画とタスク計画を管理。**

---

## 構造

```
plan/
├── README.md                    # このファイル
├── project.md                   # 根幹計画（vision, tech_decisions, milestones）
├── active/                      # アクティブな playbook（進行中）
│   └── playbook-{name}.md
├── design/                      # 設計ドキュメント
│   ├── mission.md               # 最上位概念（vision の詳細）
│   ├── self-healing-system.md   # Self-Healing System 設計
│   └── plan-chain-system.md     # 計画連鎖システム設計
└── template/                    # テンプレート群
    ├── project-format.md        # project.md 生成テンプレート
    ├── playbook-format.md       # playbook 作成テンプレート
    ├── playbook-examples.md     # playbook の例
    ├── planning-rules.md        # 計画作成ルール
    ├── state-initial.md         # state.md 初期状態
    └── vercel-nextjs-saas-structure.md  # SaaS プロジェクト構造例
```

---

## ファイルの役割

### project.md（根幹計画）

- プロジェクト全体の **vision**（ユーザーの意図、成功の定義）
- **tech_decisions**（技術選択とその理由）
- **milestones**（達成すべきマイルストーン）
- playbook 作成時の参照元

### active/（進行中 playbook）

- 現在進行中の playbook を配置
- 1 playbook = 1 branch の原則
- 完了後は `.archive/plan/` に移動

### design/（設計ドキュメント）

- アーキテクチャ設計、システム設計
- vision の詳細説明
- 実装時の参照用

### template/（テンプレート）

- 新規 project.md / playbook 作成時に参照
- setup Phase 8 で project.md を生成
- pm SubAgent が playbook 作成時に参照

---

## playbook ライフサイクル

```
1. 作成
   pm SubAgent → plan/active/playbook-{name}.md を作成
   state.md の playbook.active を更新

2. 実行
   Phase を順次実行（done_criteria → critic → PASS）
   state.md の goal を Phase ごとに更新

3. 完了
   全 Phase が done → critic で最終検証
   state.md の playbook.active を null に

4. アーカイブ
   plan/active/playbook-{name}.md → .archive/plan/playbook-{name}.md
   学習用に保存（learning Skill が参照）
```

---

## 関連ファイル

| ファイル | 役割 |
|---------|------|
| state.md | 現在の状態（focus, playbook, goal） |
| CLAUDE.md | LLM の振る舞いルール（INIT, LOOP） |
| .archive/plan/ | 完了した playbook のアーカイブ |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | 構造を最新化。active/ フォルダの使用、ライフサイクルを明記。 |
