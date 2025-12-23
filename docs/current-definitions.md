# 最新状態の定義 (2025-12-18)

> このファイルは「古い表記」を特定するための基準を定義する。
> ここに記載されていない表記は「古い」可能性がある。

---

## 1. 用語定義

### 現在有効な用語

| 用語 | 定義 |
|------|------|
| playbook | タスクを達成するための実行計画。ファイル: plan/playbook-{name}.md |
| phase | playbook 内の作業単位。ID形式: p0, p1, p2, ... |
| subtask | phase 内の個別タスク。形式: `- [ ]` / `- [x]` |
| focus.current | 現在作業中のプロジェクト名（state.md で定義） |

### 廃止された用語

| 廃止用語 | 代替 | 廃止日 |
|----------|------|--------|
| Macro | project | 2025-12-13 (V7.0) |
| layer | 廃止（使用しない） | 2025-12-13 (V7.0) |
| architecture-*.md | 廃止（docs/ に統合） | 2025-12-08 |
| spec.yaml | 廃止 | 2025-12-08 |

---

## 2. focus.current の有効値

### main ブランチで許可される focus 値

check-main-branch.sh より：

| focus 値 | 用途 | main での Edit/Write |
|----------|------|---------------------|
| setup | 新規ユーザーのセットアップ | 許可 |
| product | 新規ユーザーのプロダクト開発 | 許可 |
| plan-template | テンプレート編集 | 許可 |

### main ブランチでブロックされる focus 値

| focus 値 | 用途 | main での Edit/Write |
|----------|------|---------------------|
| thanks4claudecode | ワークスペース作業 | ブロック（ブランチ必須） |
| workspace | 一般的なワークスペース作業 | ブロック（ブランチ必須） |
| その他 | - | ブロック |

---

## 3. 機能一覧

### Hooks（30個）

構造的強制を実現するシェルスクリプト。

| Hook | トリガー | 責任 |
|------|----------|------|
| archive-playbook.sh | PostToolUse:Edit | playbook 完了時のアーカイブ提案 |
| check-coherence.sh | PreToolUse:Bash | state/playbook 整合性チェック |
| check-main-branch.sh | PreToolUse:* | main ブランチでの作業ブロック |
| check-protected-edit.sh | PreToolUse:Edit | 保護ファイル編集ブロック |
| cleanup-hook.sh | PostToolUse:Edit | tmp/ クリーンアップ |
| create-pr-hook.sh | PostToolUse:Edit | PR 自動作成 |
| create-pr.sh | utility | PR 作成ユーティリティ |
| critic-guard.sh | PreToolUse:Edit | state: done 変更ブロック |
| depends-check.sh | PreToolUse:Edit | Phase 依存チェック |
| executor-guard.sh | PreToolUse:Edit | executor 強制 |
| failure-logger.sh | utility | 失敗ログ記録 |
| generate-repository-map.sh | utility | マップ生成 |
| init-guard.sh | PreToolUse:* | 必須ファイル Read 強制 |
| lint-check.sh | PreToolUse:Bash | 静的解析チェック |
| log-subagent.sh | PostToolUse:Task | SubAgent ログ記録 |
| merge-pr.sh | utility | PR マージユーティリティ |
| playbook-guard.sh | PreToolUse:Edit | playbook=null ブロック |
| pre-bash-check.sh | PreToolUse:Bash | Bash 実行前チェック |
| pre-compact.sh | PreCompact | compact 前スナップショット |
| prompt-guard.sh | UserPromptSubmit | プロンプト検証 |
| role-resolver.sh | utility | 役割解決 |
| scope-guard.sh | PreToolUse:Edit | done_criteria 無断変更検出 |
| session-end.sh | SessionEnd | セッション終了処理 |
| session-start.sh | SessionStart | セッション開始処理 |
| stop-summary.sh | Stop | 停止時サマリー |
| subtask-guard.sh | PreToolUse:Edit | subtask 3検証 |
| system-health-check.sh | utility | 健全性チェック |
| test-hooks.sh | utility | Hook テスト |

### SubAgents（6個）

特定の検証・操作を担当する専門エージェント。

| SubAgent | 責任 |
|----------|------|
| codex-delegate | Codex CLI をラップし、コンテキスト膨張を防止 |
| critic | done_criteria の検証、PASS/FAIL 判定 |
| health-checker | システム状態監視 |
| pm | playbook 管理、タスク開始 |
| reviewer | コード/設計/playbook レビュー |
| setup-guide | セットアッププロセスガイド |

### Skills（8個）

専門知識を提供するスキル定義。

| Skill | 責任 |
|-------|------|
| context-management | コンテキスト管理（/compact 最適化） |
| deploy-checker | デプロイ準備・検証 |
| frontend-design | フロントエンド設計 |
| lint-checker | コード品質チェック |
| plan-management | 計画・playbook 管理 |
| post-loop | playbook 完了後処理 |
| state | state.md 管理 |
| test-runner | テスト実行・検証 |

### Commands（8個）

カスタムスラッシュコマンド。

| Command | 責任 |
|---------|------|
| /crit | done_criteria の CRITIQUE |
| /focus | focus.current 変更 |
| /lint | state/playbook 整合性チェック |
| /playbook-init | playbook 初期化 |
| /rollback | Git ロールバック |
| /state-rollback | state.md 復元 |
| /task-start | タスク開始 |
| /test | テスト実行 |

---

## 4. ファイル構造

### 有効なディレクトリ

| ディレクトリ | 役割 |
|--------------|------|
| .claude/hooks/ | Hook スクリプト |
| .claude/agents/ | SubAgent 定義 |
| .claude/skills/ | Skill 定義 |
| .claude/commands/ | カスタムコマンド |
| .claude/schema/ | スキーマ定義 |
| .claude/logs/ | ログ（.gitignore） |
| docs/ | ドキュメント |
| plan/ | 計画関連 |
| plan/archive/ | アーカイブ済み playbook |
| plan/template/ | テンプレート |
| tmp/ | 一時ファイル（.gitignore） |

### 廃止されたディレクトリ/ファイル

| パス | 状態 |
|------|------|
| architecture-*.md | 廃止（存在しない） |
| spec.yaml | 廃止（存在しない） |
| plan/active/ | 廃止（plan/ 直下に配置） |

---

## 5. 参照ファイル

### 毎セッション読むべきファイル

| ファイル | 役割 |
|----------|------|
| state.md | 現在地（Single Source of Truth） |
| playbook（state.md の playbook.active） | 現在の計画 |
| RUNBOOK.md | 運用手順 |
| docs/repository-map.yaml | ファイルマッピング |

### 存在しないファイルへの参照（削除対象）

| 参照元 | 参照先 | 状態 |
|--------|--------|------|
| plan/template/state-initial.md | architecture-*.md | 廃止済み |
| .claude/agents/reviewer.md | architecture-*.md | 廃止済み |
| AGENTS.md | architecture-*.md | 廃止済み |
