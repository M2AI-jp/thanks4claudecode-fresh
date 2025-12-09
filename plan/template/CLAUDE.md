# plan/template/

> **計画テンプレート - project.md と playbook の作成ガイド**

---

## 役割

このフォルダは、新規プロジェクト計画や playbook を作成する際のテンプレートを提供します。
LLM（pm SubAgent）が playbook 作成時に参照します。

---

## テンプレート一覧

| ファイル | 役割 | 使用タイミング |
|----------|------|----------------|
| project-format.md | project.md のテンプレート | setup Phase 8 で生成 |
| playbook-format.md | playbook のテンプレート | pm SubAgent が playbook 作成時 |
| playbook-examples.md | playbook の具体例 | playbook 作成の参考 |
| planning-rules.md | 計画作成のルール | 計画時の品質基準 |
| state-initial.md | state.md の初期状態 | 新規ワークスペース作成時 |
| vercel-nextjs-saas-structure.md | SaaS プロジェクト構造例 | web_app/saas タイプのプロジェクト |

---

## 使用フロー

### 新規ワークスペース作成時

```
1. state-initial.md → state.md にコピー
2. setup/playbook-setup.md に従って環境構築
3. Phase 8 で project-format.md を参照して project.md を生成
```

### playbook 作成時

```
1. pm SubAgent が project.md を読み込み
2. playbook-format.md を参照
3. planning-rules.md のルールに従って playbook 作成
4. 必要に応じて playbook-examples.md を参考
```

---

## 各テンプレートの詳細

### project-format.md

- **目的**: プロジェクトの根幹計画を定義
- **セクション**: meta, vision, tech_decisions, non_functional_requirements, stack, constraints, skills, milestones
- **生成タイミング**: setup Phase 8 完了後

### playbook-format.md

- **目的**: タスク計画（playbook）の標準フォーマット
- **セクション**: meta, goal, phases
- **特徴**: derives_from で project.md との連鎖を追跡

### planning-rules.md

- **目的**: 計画作成の品質基準
- **内容**: done_criteria の書き方、Phase の粒度、検証方法

### playbook-examples.md

- **目的**: 具体的な playbook の例
- **用途**: 初めて playbook を作成する際の参考

### state-initial.md

- **目的**: state.md の初期状態
- **用途**: 新規ワークスペース作成時の初期化

### vercel-nextjs-saas-structure.md

- **目的**: SaaS プロジェクトのディレクトリ構造例
- **用途**: web_app/saas タイプのプロジェクトで参照

---

## 連携

- **pm SubAgent** → playbook-format.md, planning-rules.md を参照
- **setup-guide SubAgent** → project-format.md, state-initial.md を参照
- **CLAUDE.md** → テンプレート参照を指示

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 | 初版作成。各テンプレートの役割と使用タイミングを説明。 |
