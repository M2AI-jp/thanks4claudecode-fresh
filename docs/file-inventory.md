# File Inventory

> **リポジトリ内全ファイルのインベントリ**
>
> 重複ファイル、孤立ファイル（参照されていない）の特定と存在意義の検証を行う。

---

## 概要

| カテゴリ | ファイル数 |
|----------|-----------|
| .claude/ (core) | 103 |
| docs/ | 6 |
| play/ (active + archive) | 100+ |
| Root files | 4 |

---

## 1. Core Files (.claude/)

### 1.1 Hooks (6 files)

| ファイル | 役割 | Reference |
|----------|------|-----------|
| .claude/hooks/prompt.sh | UserPromptSubmit Hook | settings.json |
| .claude/hooks/pre-tool.sh | PreToolUse Hook | settings.json |
| .claude/hooks/post-tool.sh | PostToolUse Hook | settings.json |
| .claude/hooks/session.sh | SessionStart/End Hook | settings.json |
| .claude/hooks/subagent-stop.sh | SubagentStop Hook | settings.json |
| .claude/hooks/generate-repository-map.sh | repository-map 生成 | session.sh |

### 1.2 Event Units (11 directories)

| ディレクトリ | chain.sh | Reference |
|--------------|----------|-----------|
| .claude/events/session-start/ | exists | session.sh |
| .claude/events/session-end/ | exists | session.sh |
| .claude/events/user-prompt-submit/ | exists | prompt.sh |
| .claude/events/pre-tool-edit/ | exists | pre-tool.sh |
| .claude/events/pre-tool-bash/ | exists | pre-tool.sh |
| .claude/events/post-tool-edit/ | exists | post-tool.sh |
| .claude/events/subagent-stop/ | exists | subagent-stop.sh |
| .claude/events/pre-compact/ | exists | session.sh |
| .claude/events/notification/ | exists | - |
| .claude/events/stop/ | exists | - |
| .claude/events/lib/ | telemetry.sh | Event Units |

### 1.3 Skills (13 directories)

| Skill | SKILL.md | agents | guards | handlers | workflow | checkers |
|-------|----------|--------|--------|----------|----------|----------|
| access-control | exists | - | 3 | - | - | - |
| executor-resolver | exists | 1 | - | - | - | - |
| git-workflow | exists | - | - | 3 | - | - |
| golden-path | exists | 2 | - | - | - | - |
| playbook-gate | exists | - | 4 | - | 3 | - |
| playbook-init | exists | - | - | - | - | - |
| post-loop | exists | - | 1 | 1 | - | - |
| prompt-analyzer | exists | 1 | - | - | - | - |
| quality-assurance | exists | 2 | - | - | - | 3 |
| reward-guard | exists | 1 | 7 | - | - | - |
| session-manager | exists | - | - | 4 | - | - |
| state | exists | - | - | - | - | - |
| understanding-check | exists | - | - | - | - | - |

### 1.4 SubAgents (.claude/agents/)

| ファイル | 実体場所 | 関係 |
|----------|----------|------|
| pm.md | golden-path/agents/pm.md | symlink/copy |
| critic.md | reward-guard/agents/critic.md | symlink/copy |
| reviewer.md | quality-assurance/agents/reviewer.md | symlink/copy |
| prompt-analyzer.md | prompt-analyzer/agents/prompt-analyzer.md | symlink/copy |
| executor-resolver.md | executor-resolver/agents/executor-resolver.md | symlink/copy |
| codex-delegate.md | golden-path/agents/codex-delegate.md | symlink/copy |
| coderabbit-delegate.md | quality-assurance/agents/coderabbit-delegate.md | symlink/copy |

### 1.5 Frameworks (3 files)

| ファイル | 役割 | Reference |
|----------|------|-----------|
| done-criteria-validation.md | critic 検証基準 | critic.md |
| playbook-review-criteria.md | reviewer 検証基準 | reviewer.md, pm.md |
| playbook-reviewer-spec.md | reviewer 仕様 | reviewer.md |

### 1.6 Libraries (.claude/lib/)

| ファイル | 役割 | Reference |
|----------|------|-----------|
| common.sh | 共通関数 | guards/*.sh |
| contract.sh | 保護パターン | guards/*.sh |
| error.sh | エラー処理 | guards/*.sh |
| logging.sh | ログ出力 | guards/*.sh |
| testing.sh | テスト用 | - |

### 1.7 Configuration

| ファイル | 役割 | Reference |
|----------|------|-----------|
| settings.json | Hook 設定 | Claude Code |
| settings.local.json | ローカル設定 | - |

---

## 2. Documentation (docs/)

| ファイル | 役割 | Reference |
|----------|------|-----------|
| ARCHITECTURE.md | アーキテクチャ設計 | CLAUDE.md |
| PROMPT_CHANGELOG.md | 変更履歴 | CLAUDE.md |
| core-feature-reclassification.md | Hook Unit マッピング | state.md |
| validation-command-standards.md | 検証コマンド標準 | playbook |
| repository-map.yaml | ファイル構造（自動生成） | state.md |
| completion-criteria.md | 完成条件（本 playbook で作成） | - |

---

## 3. Root Files

| ファイル | 役割 | Reference |
|----------|------|-----------|
| CLAUDE.md | Core Contract | Claude Code |
| state.md | 現在状態（SSOT） | Claude Code |
| README.md | リポジトリ説明 | - |
| PROJECT-STORY.md | プロジェクト経緯 | - |

---

## 4. Duplicate Analysis

### 4.1 Intentional Duplicates (Design Pattern)

| 場所1 | 場所2 | 理由 |
|-------|-------|------|
| .claude/agents/*.md | skills/*/agents/*.md | アーキテクチャ設計：agents/ は Claude Code の SubAgent 定義場所、skills/ は Skill のモジュール |

**状態**: 意図的な重複（7 ペア）
- これは設計上の意図であり、問題ではない
- .claude/agents/ は Claude Code が SubAgent を参照する場所
- skills/*/agents/ は Skill の配下モジュールとしての場所
- 両者は同一内容であるべき（差分があればエラー）

### 4.2 Unintentional Duplicates

**検出件数**: 0 件

---

## 5. Orphan Analysis (参照されていないファイル)

### 5.1 Potentially Orphan Files

| ファイル | 状態 | マーク |
|----------|------|--------|
| .claude/lib/testing.sh | 参照なし | KEEP: テスト用ライブラリ |
| tmp/README.md | 参照なし | KEEP: 一時ファイル用 |
| .claude/logs/archive/.gitkeep | 参照なし | KEEP: Git 用プレースホルダ |
| .claude/templates/skill/SKILL.md | 参照なし | KEEP: Skill テンプレート |
| .claude/templates/skill/agents/agent-template.md | 参照なし | KEEP: Agent テンプレート |

### 5.2 pytest_cache (orphan-check.sh 検出)

| ファイル | 状態 | マーク |
|----------|------|--------|
| .pytest_cache/* | テストキャッシュ | KEEP: .gitignore 対象 |
| products/mini_lisp/.pytest_cache/* | テストキャッシュ | KEEP: .gitignore 対象 |

### 5.3 Session Logs

| ディレクトリ | ファイル数 | マーク |
|--------------|-----------|--------|
| .claude/logs/sessions/ | 25+ | KEEP: セッション履歴 |

**状態**: DELETE 対象ファイル 0 件

---

## 6. Archive Analysis (play/archive/)

### 6.1 Archived Playbooks

| playbook | 状態 | 判定 |
|----------|------|------|
| play/archive/auto-hard-block/ | archived | 最新アーカイブ |
| play/archive/findings-fix/ | archived | 完了済み |
| 他 30+ | archived | 歴史的記録 |

**判定**: アーカイブは歴史的記録として保持

---

## 7. Summary

| 項目 | 結果 |
|------|------|
| 意図的重複 | 7 ペア（SubAgent - 正常） |
| 意図しない重複 | 0 件 |
| 孤立ファイル（削除対象） | 0 件 |
| 保持すべき孤立ファイル | 5 件（テンプレート・プレースホルダ） |

---

## 更新履歴

| 日付 | 変更内容 |
|------|----------|
| 2026-01-28 | 初版作成（repository-completion playbook） |
