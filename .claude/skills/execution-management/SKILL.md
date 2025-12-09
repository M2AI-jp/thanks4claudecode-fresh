---
name: execution-management
description: 並列実行制御とリソース配分のガイドライン。タスク実行の最適化を支援。
triggers:
  - 複数タスクを同時に実行するとき
  - コンテキストが逼迫しているとき
  - 効率的な実行順序を決めるとき
---

# Execution Management Skill

タスク実行の最適化を支援する Skill です。

## 並列実行制御（task-04）

### 並列実行可能なケース

```yaml
parallel_safe:
  - 独立した Read 操作（複数ファイルの読み込み）
  - 独立した Grep/Glob 検索
  - 独立した Task エージェント呼び出し
  - 副作用のない情報収集

examples:
  - Read(file1) + Read(file2) + Read(file3)
  - Grep(pattern1) + Grep(pattern2)
  - Task(agent1) + Task(agent2)
```

### 順次実行が必要なケース

```yaml
sequential_required:
  - ファイル作成 → ファイル編集
  - git add → git commit
  - 依存関係のある Phase 実行
  - 前の結果に依存する操作

examples:
  - Write(file) → Edit(file)
  - mkdir → touch file
  - git add → git commit → git push
```

### 並列実行の判断フロー

```yaml
decision_flow:
  1. 操作間に依存関係があるか？
     - YES → 順次実行
     - NO → 次へ
  2. 副作用があるか？
     - YES → 順次実行を検討
     - NO → 並列実行可能
  3. リソース競合があるか？
     - YES → 順次実行
     - NO → 並列実行可能
```

## リソース配分（task-05）

### コンテキストリソース管理

```yaml
context_budget:
  exploration: 20%   # ファイル探索・検索
  implementation: 60% # 実装作業
  verification: 20%  # 検証・テスト

monitoring:
  - /context でコンテキスト使用率を確認
  - 各フェーズで予算内に収まっているか確認
```

### 時間リソース管理

```yaml
time_allocation:
  planning: 10%      # 計画立案
  execution: 70%     # 実行
  review: 20%        # レビュー・確認

playbook_integration:
  - time_limit フィールドで Phase ごとの時間を設定
  - 超過時は警告を表示
```

### 優先度ベースのリソース配分

```yaml
priority_rules:
  high:
    - 最優先で実行
    - 必要なリソースを確保
    - 他のタスクをブロック可能

  medium:
    - 通常の優先度
    - high 完了後に実行
    - リソースを公平に分配

  low:
    - 余裕があれば実行
    - 他のタスクに影響しない
    - 後回し可能
```

## 効率化のベストプラクティス

```yaml
best_practices:
  - 情報収集は可能な限り並列で
  - ファイル操作は依存順に順次で
  - 大きなタスクは小さく分割
  - コンテキスト使用率を常に意識
  - 不要なファイル読み込みを避ける
```

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。task-04, task-05 対応。 |
