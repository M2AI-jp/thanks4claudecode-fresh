# 最新状態の定義 (2025-12-24)

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

### Hooks（5個 - 導火線モデル）

> **4QV+ アーキテクチャ**: Hook は「導火線」として Skills を呼び出す

| Hook | トリガー | 責任 |
|------|----------|------|
| pre-tool.sh | PreToolUse:* | 全ツール使用前のガードチェック |
| post-tool.sh | PostToolUse:* | ツール使用後の処理 |
| session.sh | SessionStart/End | セッション管理 |
| prompt.sh | UserPromptSubmit | State Injection |
| generate-repository-map.sh | utility | マップ生成 |

> 参照: docs/4qv-architecture.md（導火線モデル詳細）

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

### Skills（16個）

ユースケース単位のパッケージ。SubAgent を内包する場合あり。

| Skill | 責任 | SubAgents |
|-------|------|-----------|
| golden-path | タスク開始 → pm → playbook 作成 | pm, codex-delegate |
| playbook-gate | playbook なしでの変更をブロック | - |
| reward-guard | 報酬詐欺防止、done 検証 | critic |
| access-control | 保護ファイル、ブランチ制御 | - |
| session-manager | セッション開始〜終了 | setup-guide |
| quality-assurance | レビュー、ヘルスチェック | reviewer, health-checker |
| git-workflow | PR 作成・マージ | - |
| understanding-check | 5W1H 理解確認 | - |
| plan-management | 計画・playbook 管理 | - |
| context-management | コンテキスト管理 | - |
| deploy-checker | デプロイ準備・検証 | - |
| frontend-design | フロントエンド設計 | - |
| lint-checker | コード品質チェック | - |
| post-loop | playbook 完了後処理 | - |
| state | state.md 管理 | - |
| test-runner | テスト実行・検証 | - |

> 参照: docs/4qv-architecture.md（Skill 構造詳細）

### Commands（7個）

カスタムスラッシュコマンド（Entry Skill）。

| Command | 責任 | 委譲先 SubAgent |
|---------|------|-----------------|
| /playbook-init | playbook 初期化 | pm → reviewer |
| /crit | done_criteria の CRITIQUE | critic |
| /test | テスト実行 | (Bash 直接) |
| /lint | state/playbook 整合性チェック | (Bash 直接) |
| /focus | focus.current 変更 | (Edit 直接) |
| /rollback | Git ロールバック | (git 直接) |
| /state-rollback | state.md 復元 | (ファイル操作) |

> 参照: docs/4qv-architecture.md（Entry Skill → SubAgent 委譲パターン）

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
