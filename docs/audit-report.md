# リポジトリ監査レポート

> **調査日**: 2026-01-02
>
> **目的**: リポジトリ全体を網羅的に調査し、設計と実装の乖離を明確化

---

## 概要

| カテゴリ | 結果 |
|---------|------|
| 総ファイル数（.claude/） | 139 |
| 実装率 | 97.5%（79 コンポーネント中 77 完了） |
| 未実装機能 | 8 件 |
| 破損ログ | 1 件（failures.log） |
| 不正参照 | 1 件（failure-logger.sh） |

---

## 1. 全ファイル棚卸し

### 1.1 .claude/ 配下のファイル構成

| タイプ | 数 |
|--------|-----|
| ディレクトリ | 45 |
| シェルスクリプト (.sh) | 44 |
| Markdown (.md) | 78 |
| JSON (.json) | 3 |
| YAML (.yaml) | 1 |
| その他 | 13 |
| **合計** | **139** |

### 1.2 Hook 登録状況

| Hook | スクリプト | 状態 |
|------|----------|------|
| PreToolUse | pre-tool.sh | ✅ |
| PostToolUse | post-tool.sh | ✅ |
| SessionStart | session.sh | ✅ |
| UserPromptSubmit | prompt.sh | ✅ |
| SubagentStop | subagent-stop.sh | ✅ |
| PreCompact | compact.sh | ✅ |

**結果**: 全 6 Hook のスクリプト存在確認済み

### 1.3 Skills 一覧（21 Skills）

| Skill | 主要スクリプト | SubAgents |
|-------|---------------|-----------|
| abort-playbook | abort.sh | - |
| access-control | main-branch.sh, protected-edit.sh, bash-check.sh | - |
| context-management | - | - |
| deploy-checker | - | - |
| executor-resolver | - | executor-resolver.md |
| frontend-design | - | - |
| git-workflow | create-pr-hook.sh, create-pr.sh, merge-pr.sh | - |
| golden-path | - | pm.md, codex-delegate.md |
| lint-checker | - | - |
| plan-management | - | - |
| playbook-gate | playbook-guard.sh, depends-check.sh, executor-guard.sh | - |
| playbook-init | - | - |
| post-loop | pending-guard.sh, complete.sh | - |
| prompt-analyzer | - | prompt-analyzer.md |
| quality-assurance | health.sh, integrity.sh, lint.sh | reviewer.md, health-checker.md, coderabbit-delegate.md |
| reward-guard | coherence.sh, critic-guard.sh, scope-guard.sh, subtask-guard.sh | critic.md |
| session-manager | init-guard.sh, start.sh, end.sh, compact.sh | setup-guide.md |
| state | - | - |
| term-translator | - | term-translator.md |
| test-runner | run-all.sh, run-unit.sh, run-e2e.sh, run-typecheck.sh, run-build.sh | - |
| understanding-check | - | - |

### 1.4 SubAgents 一覧（10 SubAgents）

| SubAgent | 所属 Skill | 役割 |
|----------|-----------|------|
| pm | golden-path | タスク開始の必須エントリーポイント |
| reviewer | quality-assurance | playbook 検証（4QV+） |
| critic | reward-guard | done_criteria 検証（報酬詐欺防止） |
| codex-delegate | golden-path | Codex MCP ラッパー |
| coderabbit-delegate | quality-assurance | CodeRabbit CLI ラッパー |
| health-checker | quality-assurance | システム健全性チェック |
| setup-guide | session-manager | 初期設定ガイド |
| prompt-analyzer | prompt-analyzer | 5W1H 抽出・リスク分析 |
| term-translator | term-translator | 曖昧表現→エンジニア用語変換 |
| executor-resolver | executor-resolver | executor 自動判定 |

---

## 2. 設計と実装の差分分析

### 2.1 実装完了度

| カテゴリ | 設計数 | 完了 | 部分的 | 未実装 |
|---------|-------|------|--------|--------|
| Hook イベント | 8 | 6 | 0 | 2 |
| Skill | 21 | 21 | 0 | 0 |
| SubAgent | 10 | 10 | 0 | 0 |
| Guard スクリプト | 19 | 19 | 0 | 0 |
| ユーティリティ | 9 | 9 | 0 | 0 |
| **合計** | **79** | **77** | **0** | **2** |

**実装率: 97.5%**

### 2.2 未実装機能

| 機能 | 設計箇所 | 影響度 | 推奨対応 |
|------|---------|--------|---------|
| failure-logger.sh | playbook-guard.sh 参照 | 低 | 実装または参照削除 |
| doc-freshness-check.sh | 設計構想 | 中 | 要件定義後に検討 |
| update-tracker.sh | 設計構想 | 中 | git diff で代替可能 |
| self-healing-system.md | 設計構想 | 低 | health.sh/integrity.sh が代替 |
| health.sh 自動呼び出し | health.sh コメント | 中 | session.sh から呼び出し追加 |
| SessionEnd Hook | ARCHITECTURE.md | 低 | 現在不要 |
| Notification Hook | ARCHITECTURE.md | 低 | 現在不要 |
| .claude/agents/ 空ディレクトリ | 旧設計 | 低 | 削除検討 |

### 2.3 存在しないファイルへの参照

| 参照元 | 参照先 | 影響度 |
|--------|--------|--------|
| playbook-guard.sh (行 107, 138, 171) | .claude/hooks/failure-logger.sh | 低（存在チェックあり） |

---

## 3. ログ・証跡の状態調査

### 3.1 ログファイル一覧

| ファイル | サイズ | 最終更新 | 状態 |
|----------|--------|----------|------|
| block-reasons.log | 1,592 bytes | 2026-01-01 | 正常 |
| critic-results.log | 2,410 bytes | 2026-01-02 | 正常 |
| e2e-flow-simulation.log | 5,143 bytes | 2025-12-21 | 正常 |
| failures.log | 2,566 bytes | 2025-12-24 | **破損** |
| flow-fire-test.log | 1,312 bytes | 2025-12-21 | 正常 |
| subagent-dispatch.log | 1,253 bytes | 2025-12-24 | 正常 |
| subagent.log | 46,792 bytes | 2026-01-02 | 正常 |
| test-results.log | 9,484 bytes | 2025-12-22 | 正常 |
| sessions/*.md | 45 files | - | 全て正常 |

### 3.2 破損ログ

| ファイル | 問題 | 修復推奨 |
|----------|------|---------|
| failures.log | 先頭データ欠損（最初の JSON オブジェクトが不完全） | 先頭の不完全オブジェクトを削除 |

### 3.3 ログ書き込み元

| ログファイル | 書き込み元 | 状態 |
|-------------|-----------|------|
| subagent.log | subagent-stop.sh | 特定済み |
| subagent-dispatch.log | common.sh | 特定済み |
| sessions/*.md | end.sh | 特定済み |
| block-reasons.log | 不明 | Claude 直接書き込みの可能性 |
| critic-results.log | 不明 | Claude 直接書き込みの可能性 |
| failures.log | 不明 | Claude 直接書き込みの可能性 |
| test-results.log | 不明 | テストスクリプト経由 |

---

## 4. 既存ドキュメントとの差分

### 4.1 repository-map.yaml

| 項目 | 差分 |
|------|------|
| Skills | 一致（21/21） |
| SubAgents | 一致（10/10） |
| Commands | 一致（6/6） |
| Hooks | **SubagentStop 記載漏れ** |

### 4.2 ARCHITECTURE.md

| 項目 | 現状 |
|------|------|
| Section 8 (Skills 一覧) | 最新 |
| Section 7 (SubAgent) | 最新 |
| 未実装機能セクション | **存在しない** |
| 不正参照セクション | **存在しない** |

---

## 5. 推奨アクション

### 高優先度

| アクション | 理由 |
|-----------|------|
| ARCHITECTURE.md に「既知の課題と未実装」セクション追加 | 設計と実装の乖離を明文化 |
| health.sh の SessionStart 自動呼び出し実装 | 設計意図と実装の差異解消 |

### 中優先度

| アクション | 理由 |
|-----------|------|
| failure-logger.sh の実装または参照削除 | 不正参照の解消 |
| failures.log の修復 | 先頭データ欠損の解消 |
| repository-map.yaml に SubagentStop 追加 | 記載漏れの解消 |

### 低優先度

| アクション | 理由 |
|-----------|------|
| .claude/agents/ 空ディレクトリの削除 | 旧設計の残骸 |
| 書き込み元不明ログのドキュメント化 | 運用管理の改善 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2026-01-02 | 初版作成（P1-P4 調査結果統合） |
