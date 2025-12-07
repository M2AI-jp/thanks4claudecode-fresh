# project.md（Macro 計画）

> **このリポジトリ全体の最終目標を定義する。**

---

## meta

```yaml
project: dev-workspace-template
created: 2025-12-08
status: in_progress
```

---

## goal

```yaml
summary: |
  フォークするだけで LLM 主導の TDD 開発環境が整うテンプレートを完成させ、公開する。

ultimate_vision: |
  1. 新規ユーザーがフォーク
  2. Claude Code 起動 → 「ChatGPTクローン作りたい」
  3. setup 自動起動 → ヒアリング → 環境セットアップ
  4. playbook 自動生成 → TDD で開発開始
  5. アプリ完成 → デプロイ

done_when:
  - 新規ユーザーが setup を完走できる（30分以内）
  - plan-guard が機能し、LLM 主導でセッションが進む
  - playbook が自動生成され、TDD で開発できる
  - 開発時の余分なコンテキストが排除されている（.archive/）
```

---

## current_phase

```yaml
phase: 公開準備
tasks:
  - [x] 3層計画管理システム（plan-guard）
  - [x] 開発ファイル退避（.archive/）
  - [ ] 新規ユーザー視点での setup 動作確認
  - [ ] main へマージ
  - [ ] 公開
```

---

## success_criteria

```yaml
新規ユーザー体験:
  - フォーク後、Claude Code 起動で自動的に setup が開始される
  - 余分なコンテキスト（開発履歴）を見せられない
  - 30分以内に開発開始できる

LLM 主導:
  - セッション開始時に LLM が計画を提示する
  - ユーザープロンプトなしでも次のステップが明確
  - 計画外の要求には警告が出る

テンプレート品質:
  - state.md が初期状態にリセットされている
  - .archive/ で開発履歴が隔離されている
  - README.md が新規ユーザー向けに整備されている
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成 |
