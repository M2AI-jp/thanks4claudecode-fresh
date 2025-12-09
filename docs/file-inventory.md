# File Inventory

> **目的**: 全ファイルの存在理由を明確化し、削除候補・統合候補を特定する
>
> **作成日**: 2025-12-09
> **総ファイル数**: 153 件

---

## 概要統計

| カテゴリ | ファイル数 | 状態 |
|---------|-----------|------|
| .archive/ | 34 | アーカイブ済み（開発履歴） |
| .claude/ | 68 | 現行運用（Hooks/SubAgents/Skills等） |
| docs/ | 5 | ドキュメント |
| plan/ | 26 | 計画管理 |
| setup/ | 2 | セットアップ |
| root | 8 | ルート設定 |
| **合計** | **153** | - |

---

## 1. .archive/（アーカイブ済み - 34 件）

> **目的**: 開発時に使用したファイルを退避。新規ユーザーのコンテキスト負荷軽減。
> **復元**: `git checkout .archive/ && mv .archive/* .`

### 1.1 テスト履歴（.archive/.claude/hooks/ - 8 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| test-advanced-adversarial.sh | 高度な敵対的入力テスト | 保存（履歴） |
| test-adversarial-patterns.sh | 敵対的パターン検出テスト | 保存（履歴） |
| test-done-criteria.sh | done_criteria 検証テスト | 保存（履歴） |
| test-e2e-user.sh | E2E ユーザーシナリオテスト | 保存（履歴） |
| test-e2e-vision.sh | E2E ビジョンテスト | 保存（履歴） |
| test-orchestration.sh | オーケストレーションテスト | 保存（履歴） |
| test-priority-tree.sh | 優先度ツリーテスト | 保存（履歴） |
| lib/orchestration-utils.sh | テスト用ユーティリティ | 保存（履歴） |

### 1.2 スクリプト・設定（.archive/.claude/scripts/, .archive/hooks/ - 2 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| calc-dispatch-rate.sh | ディスパッチ率計算スクリプト | 保存（履歴） |
| prompt-validator.sh | 旧プロンプト検証（session分類廃止） | 保存（廃止） |

### 1.3 ドキュメント（.archive/ - 5 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| CONTEXT.md | 旧コンテキスト管理（state.md に統合） | 保存（廃止） |
| CONTRIBUTING.md | 貢献ガイドライン | **復元候補** |
| QUICKSTART.md | クイックスタート（setup に統合予定） | 保存（統合待ち） |
| file-dependencies.yaml | ファイル依存関係定義 | 保存（履歴） |
| requirements.yaml | 要件定義 | 保存（履歴） |
| spec.yaml | 旧仕様書（current-implementation.md に置換） | 保存（廃止） |

### 1.4 計画履歴（.archive/plan/ - 17 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| meta-roadmap.md | メタ改善ロードマップ | 保存（履歴） |
| roadmap.md | 開発ロードマップ | 保存（履歴） |
| vision.md | ビジョン定義 | 保存（履歴） |
| project-dev.md | 開発用 project.md | 保存（履歴） |
| test-history.md | テスト履歴 | 保存（履歴） |
| rollback-design.md | ロールバック設計書 | 保存（履歴） |
| playbook-*.md (10 件) | 完了済み playbook | 保存（履歴） |
| active/playbook-*.md (3 件) | 旧 active playbook | 保存（履歴） |

### 1.5 テスト（.archive/test/ - 1 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| README.md | テストディレクトリ説明 | 保存（履歴） |

---

## 2. .claude/（現行運用 - 68 件）

### 2.1 セッション初期化（.session-init/ - 2 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| consent | 合意プロセス用フラグファイル | **必須**（CONSENT 機構） |
| required_playbook | playbook 必須フラグ | **必須**（Guards） |

### 2.2 SubAgents（agents/ - 10 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| beginner-advisor.md | 初心者向け説明 SubAgent | **必須** |
| coherence.md | 整合性チェック SubAgent | **必須** |
| critic.md | done_criteria 検証 SubAgent | **必須**（報酬詐欺防止） |
| git-ops.md | git 操作参照ドキュメント | **必須**（git 自動化） |
| health-checker.md | システム健全性チェック | **必須** |
| plan-guard.md | 計画整合性チェック | **必須** |
| pm.md | プロジェクト管理 SubAgent | **必須**（タスク開始必須経由点） |
| reviewer.md | コードレビュー SubAgent | **必須** |
| setup-guide.md | セットアップガイド SubAgent | **必須** |
| state-mgr.md | state.md 管理 SubAgent | **必須** |

### 2.3 Commands（commands/ - 7 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| crit.md | /crit コマンド（critic 呼び出し） | **必須** |
| focus.md | /focus コマンド（レイヤー切り替え） | **必須** |
| lint.md | /lint コマンド（静的解析） | **必須** |
| playbook-init.md | /playbook-init（playbook 作成） | **必須** |
| rollback.md | /rollback（状態巻き戻し） | **必須** |
| state-rollback.md | /state-rollback（state.md 巻き戻し） | **必須** |
| task-start.md | /task-start（タスク開始） | **必須**（Phase 1 で作成） |
| test.md | /test コマンド | **必須** |

### 2.4 Frameworks（frameworks/ - 1 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| done-criteria-validation.md | done_criteria 検証フレームワーク | **必須**（critic 参照） |

### 2.5 Hooks（hooks/ - 21 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| archive-playbook.sh | playbook 完了時アーカイブ | **必須** |
| check-coherence.sh | 整合性チェック | **必須** |
| check-file-dependencies.sh | ファイル依存チェック | **検討**（使用頻度低） |
| check-main-branch.sh | main ブランチ保護 | **必須** |
| check-manifest-sync.sh | マニフェスト同期チェック | **検討**（使用頻度低） |
| check-playbook-quality.sh | playbook 品質チェック | **必須** |
| check-protected-edit.sh | 保護ファイル編集チェック | **必須** |
| check-state-update.sh | state.md 更新チェック | **必須** |
| consent-guard.sh | 合意プロセスガード | **必須**（CONSENT） |
| critic-guard.sh | critic 必須チェック | **必須**（報酬詐欺防止） |
| depends-check.sh | 依存チェック | **検討**（使用頻度低） |
| executor-guard.sh | executor 権限チェック | **必須** |
| init-guard.sh | 初期化完了チェック | **必須**（INIT 強制） |
| lib/common.sh | 共通ライブラリ | **必須** |
| lint-check.sh | 静的解析チェック | **必須** |
| log-subagent.sh | SubAgent ログ記録 | **必須** |
| playbook-guard.sh | playbook 必須チェック | **必須**（アクションベース Guards） |
| pre-bash-check.sh | Bash 実行前チェック | **必須** |
| prompt-guard.sh | プロンプトガード | **検討**（session 分類廃止後） |
| scope-guard.sh | スコープガード | **必須** |
| session-end.sh | セッション終了処理 | **必須** |
| session-start.sh | セッション開始処理 | **必須** |
| stop-summary.sh | 停止時サマリー出力 | **必須** |

### 2.6 Logs（logs/ - 8 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| .gitkeep | ディレクトリ保持 | **必須** |
| check-scope.log | スコープチェックログ | ランタイム生成 |
| context-log.md | コンテキスト外部化ログ | **必須**（CONTEXT_EXTERNALIZATION） |
| critic-results.log | critic 実行結果ログ | ランタイム生成 |
| edit-hooks.log | 編集 Hook ログ | ランタイム生成 |
| prompt-validator.log | プロンプト検証ログ | ランタイム生成 |
| sessions/.gitkeep | セッションログディレクトリ | **必須** |
| sessions/2025-12-09_session-*.md | セッションログ | ランタイム生成 |
| subagent-dispatch.log | SubAgent ディスパッチログ | ランタイム生成 |

### 2.7 Scripts（scripts/ - 3 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| rollback.sh | ロールバック実行 | **必須** |
| state-rollback.sh | state.md ロールバック | **必須** |
| test-rollback.sh | ロールバックテスト | **検討**（テスト用） |

### 2.8 Skills（skills/ - 9 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| context-management/SKILL.md | コンテキスト管理スキル | **必須** |
| deploy-checker/skill.md | デプロイチェックスキル | **検討**（テンプレート） |
| execution-management/SKILL.md | 実行管理スキル | **必須** |
| frontend-design/SKILL.md | フロントエンド設計スキル | **検討**（テンプレート） |
| learning/SKILL.md | 学習スキル | **必須** |
| lint-checker/skill.md | 静的解析スキル | **必須** |
| plan-management/SKILL.md | 計画管理スキル | **必須** |
| state/SKILL.md | state 管理スキル | **必須** |
| test-runner/skill.md | テスト実行スキル | **検討**（テンプレート） |

### 2.9 State History（state-history/ - 3 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| state-20251208-*.md (3 件) | state.md バックアップ | **必須**（ロールバック用） |

### 2.10 その他（.claude/ - 4 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| CLAUDE-ref.md | CLAUDE.md 参照ドキュメント | **必須** |
| protected-files.txt | 保護ファイルリスト | **必須** |
| session-history/.gitkeep | セッション履歴ディレクトリ | **必須** |
| settings.json | Claude Code 設定 | **必須** |
| templates/linter-formatter-config.md | Linter/Formatter 設定テンプレート | **必須** |
| tests/regression-targets.md | 回帰テスト対象 | **検討** |
| tests/regression-test.sh | 回帰テストスクリプト | **検討** |

---

## 3. docs/（ドキュメント - 5 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| coderabbit-evaluation.md | CodeRabbit 評価結果 | **必須**（意思決定記録） |
| current-implementation.md | 現在実装の棚卸し（Single Source of Truth） | **必須** |
| extension-system.md | Claude Code 公式リファレンス | **必須** |
| task-initiation-flow.md | タスク開始フロー図 | **必須**（Phase 1 成果物） |
| test-results.md | テスト結果 | **必須**（検証記録） |

---

## 4. plan/（計画管理 - 26 件）

### 4.1 ルート（plan/ - 2 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| README.md | plan/ ディレクトリ説明 | **必須** |
| project.md | Macro 計画（最終目標） | **必須** |

### 4.2 active/（進行中 playbook - 16 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| .gitkeep | ディレクトリ保持 | **必須** |
| phase-1-mapping.md | Phase 1 マッピング | **統合候補**（playbook 内部文書） |
| phase-2-inventory.md | Phase 2 インベントリ | **統合候補** |
| phase-3-flow.md | Phase 3 フロー | **統合候補** |
| phase-4-justification.md | Phase 4 根拠 | **統合候補** |
| phase-5-dependencies.md | Phase 5 依存関係 | **統合候補** |
| phase-6-recovery.md | Phase 6 復旧 | **統合候補** |
| phase-7-cleanup-list.md | Phase 7 クリーンアップ | **統合候補** |
| playbook-action-based-guards.md | 完了済み playbook | **アーカイブ候補** |
| playbook-consent-integration.md | 完了済み playbook | **アーカイブ候補** |
| playbook-current-implementation-redesign.md | 完了済み playbook | **アーカイブ候補** |
| playbook-ecosystem-improvements.md | 完了済み playbook | **アーカイブ候補** |
| playbook-engineering-ecosystem.md | 完了済み playbook | **アーカイブ候補** |
| playbook-implementation-validation.md | 完了済み playbook | **アーカイブ候補** |
| playbook-plan-chain.md | 完了済み playbook | **アーカイブ候補** |
| playbook-session-redesign.md | 完了済み playbook | **アーカイブ候補** |
| playbook-structure-optimization.md | 完了済み playbook | **アーカイブ候補** |
| playbook-system-completion.md | **現在進行中** | **必須** |
| playbook-trinity-validation.md | 完了済み playbook | **アーカイブ候補** |

### 4.3 design/（設計文書 - 1 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| plan-chain-system.md | 計画連鎖システム設計 | **必須**（設計ドキュメント） |

### 4.4 template/（テンプレート - 6 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| planning-rules.md | 計画ルール | **必須** |
| playbook-examples.md | playbook 例 | **必須** |
| playbook-format.md | playbook フォーマット | **必須** |
| project-format.md | project.md フォーマット | **必須** |
| state-initial.md | state.md 初期テンプレート | **必須** |
| vercel-nextjs-saas-structure.md | Vercel/Next.js SaaS 構造 | **検討**（プロジェクト固有） |

---

## 5. setup/（セットアップ - 2 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| CATALOG.md | ライブラリカタログ | **必須** |
| playbook-setup.md | セットアップ playbook | **必須**（Phase 4 で更新予定） |

---

## 6. ルートファイル（8 件）

| ファイル | 存在理由 | 状態 |
|---------|---------|------|
| .env.example | 環境変数テンプレート | **必須** |
| .gitignore | Git 除外設定 | **必須** |
| .mcp.json | MCP 設定 | **必須** |
| .shellcheckrc | ShellCheck 設定 | **必須** |
| AGENTS.md | SubAgents 一覧 | **必須** |
| CLAUDE.md | LLM 振る舞いルール | **必須**（保護対象） |
| README.md | リポジトリ説明 | **必須** |
| state.md | 統合状態管理 | **必須**（Single Source of Truth） |

---

## 削除候補一覧

### 高優先度（即時削除可能）

| ファイル | 理由 |
|---------|------|
| なし | アーカイブ済みファイルは .archive/ に退避済み |

### 中優先度（統合後に削除）

| ファイル | 統合先 | 理由 |
|---------|-------|------|
| plan/active/phase-*.md (7 件) | 各 playbook 内 | 単独ファイルとして不要 |

### 低優先度（検討）

| ファイル | 理由 |
|---------|------|
| .claude/hooks/check-file-dependencies.sh | 使用頻度低 |
| .claude/hooks/check-manifest-sync.sh | 使用頻度低 |
| .claude/hooks/depends-check.sh | 使用頻度低 |
| .claude/hooks/prompt-guard.sh | session 分類廃止後、役割不明確 |
| .claude/scripts/test-rollback.sh | テスト用のみ |
| .claude/tests/regression-*.* | 使用頻度低 |
| .claude/skills/deploy-checker/skill.md | テンプレートのみ |
| .claude/skills/frontend-design/SKILL.md | テンプレートのみ |
| .claude/skills/test-runner/skill.md | テンプレートのみ |

---

## 統合候補一覧

| 統合元 | 統合先 | 理由 |
|--------|-------|------|
| plan/active/phase-*.md (7 件) | 各 playbook の evidence セクション | 独立ファイルとして管理する必要なし |
| .archive/QUICKSTART.md | setup/playbook-setup.md | Phase 4 で統合予定 |
| .archive/CONTRIBUTING.md | README.md または docs/ | 復元して公開用に統合 |

---

## アーカイブ候補一覧（完了済み playbook）

> **対応**: playbook 完了時に POST_LOOP で自動アーカイブ

| ファイル | 完了日 | 対応 |
|---------|-------|------|
| playbook-action-based-guards.md | 2025-12-08 | .archive/plan/ へ移動 |
| playbook-consent-integration.md | 2025-12-09 | .archive/plan/ へ移動 |
| playbook-current-implementation-redesign.md | 2025-12-09 | .archive/plan/ へ移動 |
| playbook-ecosystem-improvements.md | 2025-12-09 | .archive/plan/ へ移動 |
| playbook-engineering-ecosystem.md | 2025-12-09 | .archive/plan/ へ移動 |
| playbook-implementation-validation.md | - | 状態確認必要 |
| playbook-plan-chain.md | 2025-12-09 | .archive/plan/ へ移動 |
| playbook-session-redesign.md | - | 状態確認必要 |
| playbook-structure-optimization.md | - | 状態確認必要 |
| playbook-trinity-validation.md | 2025-12-09 | .archive/plan/ へ移動 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | 初版作成。153 ファイルの棚卸し完了。削除候補・統合候補・アーカイブ候補を特定。 |
