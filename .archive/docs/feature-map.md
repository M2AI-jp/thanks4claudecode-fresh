# Feature Map

> **Hooks / SubAgents / Skills の一覧（簡略版）**
>
> 詳細な発火タイミング・依存関係は今後のマイルストーンで拡充予定

---

## Hooks 一覧

### セッション管理
- session-start.sh - セッション開始時の初期化
- session-end.sh - セッション終了時の処理
- stop-summary.sh - エージェント停止時のサマリー

### ガード系（PreToolUse）
- init-guard.sh - 必須ファイル Read チェック
- playbook-guard.sh - playbook 存在チェック
- consent-guard.sh - 合意ファイルチェック
- check-protected-edit.sh - 保護ファイルチェック
- critic-guard.sh - critic PASS チェック
- scope-guard.sh - スコープ外変更検出
- executor-guard.sh - executor 制御
- check-main-branch.sh - main ブランチ作業禁止

### 自動処理（PostToolUse）
- archive-playbook.sh - playbook 完了時のアーカイブ提案
- cleanup-hook.sh - テンポラリファイルの自動クリーンアップ
- log-subagent.sh - SubAgent 発動ログ
- update-tracker.sh - 変更追跡
- create-pr-hook.sh - PR 作成条件検出

### Bash 用（PreToolUse:Bash）
- pre-bash-check.sh - HARD_BLOCK ファイル書き込み検出
- check-coherence.sh - state-playbook-branch 整合性チェック
- lint-check.sh - ESLint/ShellCheck/Ruff 実行

### その他
- prompt-guard.sh - State Injection
- pre-compact.sh - compact 前の状態保存
- doc-freshness-check.sh - ドキュメント鮮度チェック

---

## SubAgents 一覧

| SubAgent | 役割 |
|----------|------|
| pm | Playbook 管理、タスク標準化 |
| critic | done_criteria の証拠ベース検証 |
| plan-guard | 3層計画の整合性チェック |
| reviewer | コード/設計レビュー |
| Explore | コードベース探索 |
| setup-guide | セットアップガイド |
| health-checker | システム状態監視 |
| claude-code-guide | Claude Code 使い方案内 |

---

## Skills 一覧

| Skill | 役割 |
|-------|------|
| state | state.md 管理 |
| learning | 失敗パターン学習 |
| plan-management | 3層計画管理 |
| context-management | /compact 最適化 |
| consent-process | 合意プロセス |
| post-loop | playbook 完了後処理 |
| lint-checker | コード品質チェック |
| test-runner | テスト実行 |
| deploy-checker | デプロイ準備検証 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-13 | M014 対応。簡略版として再作成。cleanup-hook.sh を追加。 |
