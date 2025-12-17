# Single Source of Truth（正本定義）

> 各情報の正本（唯一の真実源）を明確化する

---

## 概要

このリポジトリでは、情報の重複定義による混乱を防ぐため、
各情報カテゴリについて「正本」を1つだけ定義する。
他のファイルはこの正本を参照または派生させる。

---

## 正本一覧

| 情報カテゴリ | 正本ファイル | 派生/参照 |
|-------------|-------------|-----------|
| 現在の状態 | **state.md** | session-start.sh の出力 |
| プロジェクト計画 | **plan/project.md** | README.md の概要 |
| コンポーネント一覧 | **docs/repository-map.yaml** | component-taxonomy.md |
| 行動ルール | **CLAUDE.md** | boot-context.md（要約） |
| セキュリティモード | **docs/security-modes.md** | state.md の config.security |
| コンポーネント分類 | **docs/component-taxonomy.md** | repository-map.yaml |
| 用語定義 | **docs/current-definitions.md** | 各ドキュメント |
| 廃止用語 | **docs/deprecated-references.md** | 各ドキュメント |

---

## 詳細定義

### state.md（現在の状態）

```yaml
role: Single Source of Truth for current state
content:
  - focus.current: 現在の作業対象
  - playbook.active: 現在の計画
  - goal.milestone: 現在の目標
  - config.security: セキュリティモード
update_timing:
  - セッション開始時
  - playbook 切り替え時
  - milestone 完了時
do_not_duplicate:
  - 作業状態を他のファイルに書かない
  - session-start.sh の出力は参照用
```

### plan/project.md（プロジェクト計画）

```yaml
role: Single Source of Truth for project plan
content:
  - vision: プロジェクトの目標
  - milestones: 中間目標リスト
update_timing:
  - milestone 完了時
  - プロジェクト方針変更時
do_not_duplicate:
  - milestone の詳細を他のファイルに書かない
  - README.md には概要のみ
```

### docs/repository-map.yaml（コンポーネント一覧）

```yaml
role: Single Source of Truth for component list
content:
  - hooks: 全 Hook ファイル
  - agents: 全 SubAgent ファイル
  - skills: 全 Skill ファイル
  - commands: 全 Command ファイル
generator: .claude/hooks/generate-repository-map.sh
update_timing:
  - playbook 完了時（自動生成）
  - 手動で bash .claude/hooks/generate-repository-map.sh
do_not_duplicate:
  - コンポーネントの数を他のファイルにハードコードしない
  - current-definitions.md は補足情報のみ
```

### CLAUDE.md（行動ルール）

```yaml
role: Single Source of Truth for Claude behavior rules
content:
  - 絶対遵守事項
  - Plan Mode フロー
  - Hooks/SubAgents/Skills の使い方
update_timing:
  - フレームワーク変更時
do_not_duplicate:
  - 行動ルールを他のファイルに書かない
  - boot-context.md は要約のみ
```

---

## 派生ファイルの役割

| 派生ファイル | 正本 | 役割 |
|-------------|------|------|
| docs/boot-context.md | CLAUDE.md | セッション開始用の要約 |
| docs/hook-responsibilities.md | repository-map.yaml | Hook の責任分担詳細 |
| README.md | project.md | 外部向け概要 |
| session-start.sh 出力 | state.md | 可読形式の状態表示 |

---

## 禁止事項

1. **重複定義禁止**: 同じ情報を複数ファイルで定義しない
2. **ハードコード禁止**: 正本を参照せず数値等を埋め込まない
3. **派生物の直接編集禁止**: repository-map.yaml は自動生成、手動編集しない

---

## 矛盾発生時の対応

正本と派生物で矛盾が発生した場合：

1. **正本を信じる**: 派生物ではなく正本を参照
2. **派生物を再生成**: 自動生成可能なら再生成
3. **派生物を削除**: 不要なら削除して正本のみ残す

---

## 実装状態

| 項目 | 状態 |
|------|------|
| 正本定義（このドキュメント） | ✓ 完了 |
| 重複削除 | 部分的（feature-catalog.yaml 削除済み） |
| current-definitions.md 整理 | 未実装（M108 で対応） |
