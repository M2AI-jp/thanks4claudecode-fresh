# ARCHITECTURE.md

> **リポジトリの構造と各コンポーネントの関係を文書化**

---

## 1. 概要

このリポジトリは「Claude Code のための自律運用フレームワーク」を提供する。

```
主要な構成要素:
├── Hooks: 32 スクリプト (22 registered in settings.json)
├── SubAgents: 6 定義
├── Skills: 5 定義
├── Commands: 8 スラッシュコマンド
└── 状態管理: state.md + playbook
```

### 設計思想

- **三位一体**: Hooks（構造的強制）+ SubAgents（検証）+ CLAUDE.md（思考制御）
- **Single Source of Truth**: state.md が現在状態の真実源
- **報酬詐欺防止**: critic SubAgent による検証が必須

---

## 2. エントリーポイント

Claude Code がセッション開始時に読み込む順序:

```
1. CLAUDE.md          - 行動ルール（Frozen Constitution）
2. state.md           - 現在の状態（focus, playbook, goal）
3. playbook (if any)  - 現在の作業計画（plan/playbook-*.md）
4. RUNBOOK.md         - 運用手順
5. docs/repository-map.yaml - 全ファイルマッピング
```

---

## 3. ディレクトリ構成

```
/
├── CLAUDE.md              # LLM の行動ルール（不変）
├── RUNBOOK.md             # 手順書（変更可能）
├── AGENTS.md              # コーディングルール
├── README.md              # プロジェクト説明
├── state.md               # 現在状態（SSOT）
│
├── .claude/               # Claude Code 拡張システム
│   ├── settings.json      # Hook 登録・権限設定
│   ├── mcp.json           # MCP サーバー設定
│   ├── hooks/             # 31 Hook スクリプト
│   ├── agents/            # 6 SubAgent 定義
│   ├── skills/            # 5 Skill 定義
│   ├── commands/          # 8 スラッシュコマンド
│   ├── schema/            # state.md スキーマ定義
│   ├── logs/              # 実行ログ
│   └── tests/             # done_criteria テスト
│
├── plan/                  # 計画管理
│   ├── playbook-*.md      # 進行中 playbook
│   ├── archive/           # 完了済み playbook
│   └── template/          # playbook テンプレート
│
├── docs/                  # ドキュメント (17 files)
│   ├── repository-map.yaml
│   ├── extension-system.md
│   ├── hook-responsibilities.md
│   ├── folder-management.md
│   └── ... (他 13 files)
│
├── setup/                 # セットアップ関連
├── tmp/                   # テンポラリ（.gitignore）
└── .archive/              # アーカイブ済みファイル
```

---

## 4. Hook システム

### 4.1 登録済み Hooks (settings.json)

```yaml
PreToolUse:
  "*":
    - init-guard.sh        # 必須ファイル Read 強制
    - check-main-branch.sh # main ブランチ作業ブロック

  "Edit":
    - check-protected-edit.sh # 保護ファイルブロック
    - playbook-guard.sh    # playbook 存在チェック
    - depends-check.sh     # phase 依存関係チェック
    - critic-guard.sh      # done 変更ブロック
    - scope-guard.sh       # done_criteria 変更検出
    - executor-guard.sh    # executor 制御
    - subtask-guard.sh     # subtask 3検証

  "Write":
    - check-protected-edit.sh
    - playbook-guard.sh
    - critic-guard.sh
    - scope-guard.sh
    - executor-guard.sh
    - subtask-guard.sh

  "Bash":
    - pre-bash-check.sh    # コマンド事前チェック
    - check-coherence.sh   # 整合性チェック
    - lint-check.sh        # 静的解析

PostToolUse:
  "Task":
    - log-subagent.sh      # SubAgent ログ記録

  "Edit":
    - archive-playbook.sh  # playbook アーカイブ提案
    - cleanup-hook.sh      # tmp/ クリーンアップ
    - create-pr-hook.sh    # PR 作成提案

UserPromptSubmit:
  - prompt-guard.sh        # プロンプト処理

SessionStart:
  - session-start.sh       # セッション初期化

SessionEnd:
  - session-end.sh         # セッション終了処理

Stop:
  - stop-summary.sh        # 停止時サマリー

PreCompact:
  - pre-compact.sh         # コンパクト前処理
```

### 4.2 未登録 Hooks（ユーティリティ）

```
audit-unused.sh          # 未使用ファイル検出
check-integrity.sh       # リポジトリ整合性検証
create-pr.sh             # PR 作成スクリプト
failure-logger.sh        # 失敗パターン記録
generate-repository-map.sh # repository-map.yaml 生成
merge-pr.sh              # PR マージスクリプト
role-resolver.sh         # 役割→executor 解決
system-health-check.sh   # システム健全性チェック
test-done-criteria.sh    # テスト実行
test-hooks.sh            # Hook テスト
```

---

## 5. SubAgents

| Agent | ファイル | 目的 |
|-------|----------|------|
| pm | pm.md | playbook 作成・管理（MANDATORY entry point） |
| critic | critic.md | done_criteria 検証（PASS/FAIL 判定） |
| reviewer | reviewer.md | コード/設計レビュー |
| setup-guide | setup-guide.md | セットアップガイド |
| codex-delegate | codex-delegate.md | Codex MCP 呼び出し |
| health-checker | health-checker.md | システム健全性監視 |

### 呼び出しパターン

```
Task(subagent_type='pm', prompt='playbook を作成')
Task(subagent_type='critic', prompt='done_criteria を検証')
Task(subagent_type='reviewer', prompt='コードをレビュー')
```

---

## 6. Skills

| Skill | ディレクトリ | 目的 |
|-------|-------------|------|
| deploy-checker | deploy-checker/ | デプロイ準備検証 |
| lint-checker | lint-checker/ | ESLint/型チェック |
| test-runner | test-runner/ | テスト実行 |
| post-loop | post-loop/ | playbook 完了後処理 |

---

## 7. Commands

| コマンド | ファイル | 目的 |
|---------|----------|------|
| /playbook-init | playbook-init.md | playbook 新規作成 |
| /task-start | task-start.md | タスク開始（pm 経由） |
| /crit | crit.md | done_criteria 検証 |
| /test | test.md | テスト実行 |
| /lint | lint.md | 整合性チェック |
| /focus | focus.md | focus 切り替え |
| /rollback | rollback.md | Git ロールバック |
| /state-rollback | state-rollback.md | state.md 復元 |

---

## 8. データフロー

### 8.1 セッション開始

```
SessionStart
    │
    ├─→ session-start.sh
    │       ├─→ state.md 読み込み
    │       ├─→ playbook 確認
    │       ├─→ feature-catalog 読み込み
    │       └─→ systemMessage 出力
    │
    └─→ Claude: [自認] 出力 → LOOP 開始
```

### 8.2 Edit/Write フロー

```
Edit/Write 試行
    │
    ├─→ init-guard.sh (必須 Read 確認)
    ├─→ check-main-branch.sh (main ブロック)
    ├─→ check-protected-edit.sh (保護ファイル)
    ├─→ playbook-guard.sh (playbook 存在)
    ├─→ depends-check.sh (依存関係)
    ├─→ critic-guard.sh (done 変更)
    ├─→ scope-guard.sh (scope 変更)
    ├─→ executor-guard.sh (executor)
    └─→ subtask-guard.sh (3検証)
         │
         └─→ 全て通過 → Edit/Write 実行
                 │
                 ├─→ archive-playbook.sh
                 ├─→ cleanup-hook.sh
                 └─→ create-pr-hook.sh
```

### 8.3 3層構造

```
playbook (タスク単位)
├── meta: メタ情報（branch, created）
├── goal.done_when: 達成条件
└── phases[]: 作業単位
    ├── p0: done
    ├── p1: in_progress
    └── p2: pending

phase (作業単位)
├── subtasks[]: チェックボックス形式
│   ├── - [ ] subtask 1
│   └── - [x] subtask 2 ✓
├── validations: 3点検証（technical/consistency/completeness）
└── executor: orchestrator|worker|reviewer
```

---

## 9. 重要ファイル

### 9.1 Single Source of Truth

| ファイル | 役割 |
|----------|------|
| state.md | 現在状態（focus, playbook, goal, config） |
| plan/playbook-*.md | 進行中のタスク計画 |
| .claude/settings.json | Hook 登録・権限 |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |

### 9.2 設定ファイル

| ファイル | 役割 |
|----------|------|
| .claude/settings.json | Hook 登録、権限設定 |
| .claude/mcp.json | MCP サーバー設定（Codex） |
| .claude/protected-files.txt | 保護対象ファイルリスト |

### 9.3 テンプレート

| ファイル | 役割 |
|----------|------|
| plan/template/playbook-format.md | playbook テンプレート |
| plan/template/phase-definition.md | phase 定義テンプレート |

---

## 10. admin モード

`state.md` の `config.security: admin` 設定で全ガードをバイパス可能。

```yaml
# state.md
## config
security: admin  # 全ガードバイパス
```

対応 Hook:
- init-guard.sh
- playbook-guard.sh (修正済み)

---

## 11. 統計

| カテゴリ | 数 |
|----------|-----|
| Hooks (total) | 32 |
| Hooks (registered) | 22 |
| Hooks (utility) | 10 |
| SubAgents | 6 |
| Skills | 5 |
| Commands | 8 |
| Docs | 14 |
| Milestones (achieved) | 26 |
| Archived playbooks | 51+ |

---

## 12. ドキュメント整理方針

### アーカイブ候補（.archive/docs/ に移動）

| ファイル | 理由 |
|----------|------|
| fraud-investigation-report.md | M062 一回限りの調査レポート |
| e2e-simulation-log.md | M062 テストログ |
| e2e-simulation-scenarios.md | M062 テストシナリオ |
| deprecated-references.md | 廃止参照リスト（対応完了後アーカイブ） |

### 保持（必須）

| ファイル | 理由 |
|----------|------|
| ARCHITECTURE.md | リポジトリ構造文書 |
| ai-orchestration.md | 役割ベース実行 |
| archive-operation-rules.md | アーカイブ運用 |
| artifact-management-rules.md | 成果物管理 |
| criterion-validation-rules.md | done_criteria 検証 |
| current-definitions.md | 用語定義 |
| extension-system.md | Hook ドキュメント |
| folder-management.md | フォルダ管理 |
| git-operations.md | git 運用 |
| hook-responsibilities.md | Hook 責任 |
| repository-map.yaml | 自動生成マップ |
| session-management.md | セッション管理 |
| toolstack-patterns.md | Toolstack パターン |

---

## 13. 既知の問題

1. ~~playbook-guard.sh が admin モード未対応~~: 修正済み（2025-12-18）
2. **repository-map.yaml の description 切り詰め**: 一部の description が途中で切れている

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-18 | 初版作成（cleanup/architecture-audit） |
| 2025-12-18 | playbook-guard.sh に admin モードチェック追加 |
| 2025-12-18 | audit-unused.sh 作成、pm.md 修正、docs 整理（17→14） |
