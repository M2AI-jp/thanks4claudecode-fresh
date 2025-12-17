# Component Taxonomy（コンポーネント分類体系）

> Hooks/SubAgents/Skills を MECE（漏れなく重複なく）に分類する

---

## カテゴリ定義

```yaml
categories:
  Gate:
    description: "操作をブロックする門番"
    behavior: "条件を満たさなければ exit 2"
    responsibility: "不正な操作の阻止"
    
  Observer:
    description: "ログ記録・状態観測"
    behavior: "常に exit 0、副作用としてログ記録や状態更新"
    responsibility: "監査可能性の確保"
    
  Validator:
    description: "検証を行うが、ブロックはしない"
    behavior: "警告を出すことはあるが exit 0"
    responsibility: "品質チェック、整合性確認"
    
  Utility:
    description: "便利機能の提供"
    behavior: "常に exit 0、オプショナルな処理"
    responsibility: "自動化、効率化"
    
  Planner:
    description: "計画・意思決定の支援"
    behavior: "計画を生成または提案"
    responsibility: "タスクの構造化"
    
  Evaluator:
    description: "評価・判定の実行"
    behavior: "PASS/FAIL などの判定を返す"
    responsibility: "品質保証、完了判定"
    
  Guide:
    description: "手順・知識の提供"
    behavior: "How-to やポリシーを提供"
    responsibility: "一貫性のある作業手順"
```

---

## Hooks 分類

| Hook | カテゴリ | 責任 |
|------|----------|------|
| init-guard.sh | Gate | 必須ファイル Read 強制 |
| playbook-guard.sh | Gate | playbook 必須強制 |
| check-main-branch.sh | Gate | main ブランチ作業禁止 |
| check-protected-edit.sh | Gate | 保護ファイル編集禁止 |
| consent-guard.sh | Gate | 合意プロセス強制 |
| critic-guard.sh | Gate | critic なしの done 禁止 |
| scope-guard.sh | Gate | done_criteria 無断変更検出 |
| executor-guard.sh | Gate | executor 不一致禁止 |
| subtask-guard.sh | Gate | subtask 検証強制 |
| depends-check.sh | Gate | Phase 依存チェック |
| prompt-guard.sh | Validator | プロンプト検証 |
| check-coherence.sh | Validator | state/playbook 整合性チェック |
| lint-check.sh | Validator | 静的解析チェック |
| pre-bash-check.sh | Validator | Bash 実行前チェック |
| session-start.sh | Observer | セッション開始処理 |
| session-end.sh | Observer | セッション終了処理 |
| log-subagent.sh | Observer | SubAgent ログ記録 |
| failure-logger.sh | Observer | 失敗ログ記録 |
| stop-summary.sh | Observer | 停止時サマリー |
| pre-compact.sh | Observer | compact 前スナップショット |
| archive-playbook.sh | Utility | playbook アーカイブ提案 |
| cleanup-hook.sh | Utility | 一時ファイル削除 |
| create-pr-hook.sh | Utility | PR 自動作成 |
| create-pr.sh | Utility | PR 作成ユーティリティ |
| merge-pr.sh | Utility | PR マージユーティリティ |
| generate-repository-map.sh | Utility | マップ生成 |
| role-resolver.sh | Utility | 役割解決 |
| system-health-check.sh | Validator | 健全性チェック |
| test-hooks.sh | Validator | Hook テスト |

---

## SubAgents 分類

| SubAgent | カテゴリ | 責任 |
|----------|----------|------|
| pm | Planner | playbook 作成、タスク管理 |
| critic | Evaluator | done_criteria 検証、PASS/FAIL 判定 |
| reviewer | Evaluator | コード/設計レビュー |
| health-checker | Validator | システム状態監視 |
| setup-guide | Guide | セットアッププロセスガイド |
| codex-delegate | Utility | Codex MCP ラップ |

---

## Skills 分類

| Skill | カテゴリ | 責任 |
|-------|----------|------|
| consent-process | Guide | 合意プロセス手順 |
| context-management | Guide | コンテキスト管理手順 |
| deploy-checker | Validator | デプロイ準備検証 |
| frontend-design | Guide | フロントエンド設計ガイド |
| lint-checker | Validator | コード品質チェック手順 |
| plan-management | Guide | 計画・playbook 管理手順 |
| state | Guide | state.md 管理手順 |
| test-runner | Utility | テスト実行手順 |

---

## MECE 検証

### カテゴリカバレッジ

```yaml
Gate: 10 Hooks
Validator: 5 Hooks, 2 SubAgents, 2 Skills
Observer: 6 Hooks
Utility: 7 Hooks, 1 SubAgent, 1 Skill
Planner: 1 SubAgent
Evaluator: 2 SubAgents
Guide: 1 SubAgent, 5 Skills
```

### 未分類コンポーネント

なし（全てのコンポーネントが1つのカテゴリに属している）

### 複数カテゴリにまたがるコンポーネント

なし（1コンポーネント = 1カテゴリ を維持）

---

## repository-map.yaml への反映

各コンポーネントに `category` フィールドを追加する。

```yaml
# 例
hooks:
  - name: init-guard.sh
    category: Gate
    description: 必須ファイル Read 強制
```

---

## 実装状態

| 項目 | 状態 |
|------|------|
| 分類定義（このドキュメント） | ✓ 完了 |
| repository-map.yaml への反映 | 未実装 |
| 各 Hook のコメント更新 | 未実装 |
