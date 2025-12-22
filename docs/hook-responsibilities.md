# Hook 責任定義書

> **各 Hook の単一責任を明示（SOLID 原則: Single Responsibility Principle）**

---

## 概要

このドキュメントは .claude/hooks/ 内の全スクリプトの責任を定義します。
各 Hook は 1 つの責任のみを持ち、他の Hook と連携して全体の機能を実現します。

---

## セッション管理

### session-start.sh
- **トリガー**: SessionStart
- 責任: セッション開始時の初期化処理
- **詳細**: pending ファイル作成、状態表示、CORE 情報出力
- **出力**: セッション開始メッセージ、警告
- **連携**: init-guard.sh（pending ファイル作成）

### session-end.sh
- **トリガー**: Stop
- 責任: セッション終了時の後処理
- **詳細**: セッション情報の更新、クリーンアップ
- **連携**: stop-summary.sh

### stop-summary.sh
- **トリガー**: Stop
- 責任: セッション終了サマリーの出力
- **詳細**: 作業結果の要約を表示
- **連携**: session-end.sh

---

## 初期化ガード

### init-guard.sh
- **トリガー**: PreToolUse (*)
- 責任: 必須ファイル Read 強制【単一責任】
- **詳細**: state.md, mission.md, playbook の Read を強制
- **許可**: Read, Grep, Glob, 基本 Bash コマンド（sed/grep/cat/echo/ls/wc）, git コマンド
- **ブロック**: 上記以外のツール（pending ファイル存在時）
- **連携**: session-start.sh（pending ファイル）

### playbook-guard.sh
- **トリガー**: PreToolUse:Edit/Write
- 責任: playbook 存在チェック【単一責任】
- **詳細**: Edit/Write 時に playbook が null でないことを確認
- **ブロック**: playbook=null で Edit/Write
- **連携**: init-guard.sh（責任分離）

---

## コード品質

### lint-check.sh
- **トリガー**: PreToolUse:Bash
- 責任: 静的解析の実行
- **詳細**: ESLint/ShellCheck/Ruff の自動実行
- **連携**: なし（独立）

### check-coherence.sh
- **トリガー**: PostToolUse:Edit
- 責任: state.md と playbook の整合性チェック
- **詳細**: 状態の矛盾を検出
- **連携**: system-health-check.sh

---

## 保護・セキュリティ

### check-protected-edit.sh
- **トリガー**: PreToolUse:Edit/Write
- 責任: 保護ファイルの編集制御
- **詳細**: CLAUDE.md 等の重要ファイルへの編集をチェック
- **ブロック**: 許可なしの保護ファイル編集
- **連携**: なし

### check-main-branch.sh
- **トリガー**: PreToolUse:Bash (git)
- 責任: main ブランチでの作業防止
- **詳細**: main ブランチへの直接コミット/プッシュをブロック
- **連携**: なし

### scope-guard.sh
- **トリガー**: PreToolUse:Edit/Write
- 責任: 変更スコープのチェック
- **詳細**: playbook 外のファイル変更を検出
- **連携**: playbook-guard.sh

### prompt-guard.sh
- **トリガー**: PreToolUse (*)
- 責任: プロンプト注入防止
- **詳細**: 悪意あるプロンプトパターンを検出
- **連携**: なし

---

## タスク管理

### subtask-guard.sh
- **トリガー**: PreToolUse:Edit (playbook)
- 責任: subtask 完了時の 3 検証強制【M018】
- **詳細**: status: done への変更時に検証を警告
- **3 検証**: technical / consistency / completeness
- **連携**: archive-playbook.sh

### critic-guard.sh
- **トリガー**: PreToolUse:Edit (playbook)
- 責任: critic 未実行での完了防止
- **詳細**: phase 完了前に critic 実行を強制
- **連携**: subtask-guard.sh

### executor-guard.sh
- **トリガー**: PreToolUse (Task)
- 責任: executor 指定のチェック
- **詳細**: subtask の executor と実際の実行者の整合性確認
- **連携**: なし

### depends-check.sh
- **トリガー**: PreToolUse:Edit (playbook)
- 責任: 依存関係チェック
- **詳細**: depends_on の phase が完了しているか確認
- **連携**: なし

---

## アーカイブ・クリーンアップ

### archive-playbook.sh
- **トリガー**: PostToolUse:Edit
- 責任: playbook 完了検出とアーカイブ提案
- **詳細**: 全 phase done → アーカイブ推奨メッセージ
- **final_tasks**: アーカイブ前に final_tasks 完了をチェック【M019】
- **連携**: subtask-guard.sh, cleanup-hook.sh

### cleanup-hook.sh
- **トリガー**: PostToolUse:Edit
- 責任: tmp/ フォルダのクリーンアップ
- **詳細**: playbook 完了時に一時ファイルを削除
- **連携**: archive-playbook.sh

---

## PR・Git 操作

### create-pr.sh
- **トリガー**: Bash (gh pr create)
- 責任: PR 作成の補助
- **詳細**: PR テンプレート適用、チェック実行
- **連携**: create-pr-hook.sh

### create-pr-hook.sh
- **トリガー**: PostToolUse:Bash (gh)
- 責任: PR 作成後のフック処理
- **詳細**: PR 作成完了時の通知
- **連携**: create-pr.sh

### merge-pr.sh
- **トリガー**: Bash (gh pr merge)
- 責任: PR マージの補助
- **詳細**: マージ前チェック、post-merge 処理
- **連携**: なし

---

## ファイル依存・分析

### generate-repository-map.sh
- **トリガー**: PostToolUse:Write
- 責任: repository-map.yaml の自動生成
- **詳細**: ファイル構造のマッピング更新
- **連携**: なし

---

## Bash 制御

### pre-bash-check.sh
- **トリガー**: PreToolUse:Bash
- 責任: Bash コマンドの事前チェック
- **詳細**: 危険なコマンドパターンの検出
- **連携**: init-guard.sh

---

## ロギング・モニタリング

### log-subagent.sh
- **トリガー**: PostToolUse:Task
- 責任: SubAgent 呼び出しのログ記録
- **詳細**: SubAgent 使用履歴の保存
- **連携**: なし

### failure-logger.sh
- **トリガー**: Stop
- 責任: 失敗パターンの記録
- **詳細**: failures.log への追記
- **連携**: session-start.sh（失敗パターン表示）

### system-health-check.sh
- **トリガー**: SessionStart
- 責任: システム健全性チェック
- **詳細**: state.md / playbook / git の整合性確認
- **連携**: session-start.sh

---

## コンテキスト管理

### pre-compact.sh
- **トリガー**: PreToolUse:Compact
- 責任: /compact 前の状態保存
- **詳細**: コンテキスト要約前の重要情報保存
- **連携**: なし

---

## テスト・検証

### test-hooks.sh
- **トリガー**: 手動実行
- 責任: Hook 動作テスト
- **詳細**: 全 Hook の構文チェックと基本動作確認
- **連携**: なし

---

## 依存関係図

```
SessionStart
  │
  ├─→ session-start.sh ──→ pending ファイル作成
  │                              │
  ├─→ system-health-check.sh     │
  │                              ▼
  └─→ init-guard.sh ←────── pending ファイル参照
          │
          │ Read 完了後
          ▼
      playbook-guard.sh ──→ Edit/Write 許可
          │
          ├─→ check-protected-edit.sh
          ├─→ scope-guard.sh
          │
          ▼
      subtask-guard.sh ──→ 3 検証警告
          │
          ▼
      critic-guard.sh ──→ critic 実行強制
          │
          ▼
      archive-playbook.sh ──→ アーカイブ提案
          │
          ├─→ cleanup-hook.sh
          └─→ final_tasks チェック

Stop
  │
  ├─→ session-end.sh
  ├─→ stop-summary.sh
  └─→ failure-logger.sh
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-14 | 初版作成。M022 SOLID 原則リファクタリングの一環。 |
