# project.md

> **Macro 計画: リポジトリ全体の最終目標**

---

## vision

```yaml
summary: 仕組みのための仕組みづくり - LLM 主導の開発環境テンプレート
goal: LLM が完全自律で PDCA を回せる開発環境を提供する
```

---

## done_when

```yaml
core:
  - LLM がセッション開始から終了まで自律で動作する
  - playbook 完了後、自動で次のタスクに進む
  - 自己報酬詐欺を構造的に防止する

quality:
  - 全ての機能が検証済み
  - 新規ユーザーがフォークして即使用可能
  - setup レイヤーが完全に動作する
```

---

## current_phase

```yaml
phase: implementation
focus: 欠落機能の実装
completed:
  - Issue #8: 自律性強化（PDCA自動回転・妥当性評価フレームワーク）
  - Issue #9: 回帰テスト機能（task-06）
  - Issue #10: 自動 /clear 判断（task-08）
  - Issue #11: ロールバック機能（task-11）
  - task-07: レビュー機能（reviewer SubAgent）
  - task-01: タイムボックス機能（playbook スキーマ拡張: time_limit）
  - task-02: 優先順位管理（playbook スキーマ拡張: priority）
  - task-03: 依存関係管理（playbook スキーマ拡張: depends_on 強化）

remaining_tasks:
  # 実行管理（2件）
  - id: task-04
    name: 並列実行制御
    category: 実行管理
    description: 複数タスクの並列実行を制御
    priority: low

  - id: task-05
    name: リソース配分
    category: 実行管理
    description: コンテキスト・時間のリソース配分最適化
    priority: low

  # コンテキスト管理（2件）
  - id: task-09
    name: /compact 最適化
    category: コンテキスト管理
    description: 優先保持情報の最適化
    priority: medium

  - id: task-10
    name: 履歴の要約
    category: コンテキスト管理
    description: セッション履歴の自動要約・保存
    priority: medium

  # 回復・監視（2件）
  - id: task-12
    name: ヘルスチェック
    category: 回復・監視
    description: システム状態の定期監視
    priority: medium

  - id: task-13
    name: 学習・改善機構
    category: 回復・監視
    description: 失敗パターンの記録・学習
    priority: low
```

---

## priority_order

```yaml
# 優先度順の実装順序（task-11 完了）
high:
  - (完了)

medium:
  - task-01: タイムボックス
  - task-02: 優先順位管理
  - task-03: 依存関係管理
  - task-07: レビュー機能
  - task-09: /compact 最適化
  - task-10: 履歴の要約
  - task-12: ヘルスチェック

low:
  - task-04: 並列実行制御
  - task-05: リソース配分
  - task-13: 学習・改善機構
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。MECE 分析の残タスク 13件を登録。 |
