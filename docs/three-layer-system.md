# 3層自動運用システム

> project → playbook → phase の実装状況と現実的な責務分担

---

## 概要

3層自動運用は、以下の階層でタスクを管理する設計：

```
project (永続)
  └─ milestone (中間目標)
       └─ playbook (一時的な計画)
            └─ phase (作業単位)
                 └─ subtask (個別タスク)
```

このドキュメントでは、各層の「設計」と「実装状況」を冷静に棚卸しする。

---

## 各層の定義と実装状況

### project 層

```yaml
definition:
  role: "リポジトリ全体の目標と方向性"
  file: plan/project.md
  contains:
    - vision: 最終目標
    - milestones: 中間目標リスト

implementation_status:
  file_creation: implemented
    - plan/project.md は手動またはテンプレートから作成
  milestone_tracking: implemented
    - milestones セクションに status (not_started/in_progress/achieved) を記録
  auto_update: not_implemented
    - milestone 完了時の自動更新は手動作業が必要

human_intervention_required:
  - プロジェクト目標の決定
  - milestone の優先順位付け
  - milestone 完了の最終判断
```

### playbook 層

```yaml
definition:
  role: "milestone 達成のための具体的な計画"
  file: plan/playbook-{name}.md
  contains:
    - meta: derives_from (milestone ID), branch
    - phases: 作業フェーズ
    - done_criteria: 各フェーズの完了条件

implementation_status:
  file_creation: partially_implemented
    - pm SubAgent が playbook を作成可能
    - ただし pm を呼び出さなければ作成されない
  branch_creation: partially_implemented
    - playbook 作成時にブランチを切る設計
    - 手動で行うことも多い
  archiving: implemented
    - archive-playbook.sh が提案
    - plan/archive/ に移動

human_intervention_required:
  - phase の内容・順序の決定
  - done_criteria の定義
  - 完了判断
```

### phase 層

```yaml
definition:
  role: "playbook 内の作業単位"
  format: p0, p1, p2, ...
  contains:
    - status: not_started/in_progress/done
    - subtasks: 個別タスク
    - done_criteria: 完了条件

implementation_status:
  status_tracking: implemented
    - playbook 内で status を管理
  sequential_execution: partially_implemented
    - CLAUDE.md の LOOP で順次実行を定義
    - ただし LLM が従わなければ機能しない
  completion_verification: partially_implemented
    - critic SubAgent で検証可能
    - 自動呼び出しはない

human_intervention_required:
  - subtask の詳細定義
  - 実行時の判断
  - 完了確認
```

---

## 自動化の境界

### 自動でやること（implemented）

| 機能 | 実装 | 備考 |
|------|------|------|
| playbook=null で Edit ブロック | playbook-guard.sh | アクティブ |
| main ブランチで作業ブロック | check-main-branch.sh | アクティブ |
| playbook アーカイブ提案 | archive-playbook.sh | アクティブ |
| session 状態保存 | session-start/end.sh | アクティブ |

### 人間が介在すること（requires_human）

| 機能 | 理由 |
|------|------|
| milestone の定義 | ビジネス判断が必要 |
| playbook の作成 | pm を呼び出す判断 |
| done_criteria の定義 | 要件理解が必要 |
| 完了判断 | 最終的な品質判断 |
| critic の呼び出し | LLM の意思決定 |

### 自動化を断念したこと（not_planned）

| 機能 | 断念理由 |
|------|----------|
| 完全自動 milestone 遷移 | ビジネス判断を自動化すべきでない |
| 強制的 critic 呼び出し | 過剰な自動化は柔軟性を損なう |
| sed バイパスの防止 | 技術的に不可能 |

---

## 過剰な期待の削除

### 以前の記述（削除すべき）

- 「Claude が主導管理」→「Claude が支援」に変更
- 「人間は意思決定とプロンプト提供のみ」→ 削除
- 「完全自動」表現 → 削除

### 現実的な記述

```yaml
reality:
  - Claude は計画の実行を支援するが、判断は人間が行う
  - playbook-guard は「無計画作業の防止」であり「自動計画生成」ではない
  - 3層構造は「整理のためのフレームワーク」であり「自律システム」ではない
```

---

## pm SubAgent の現実的な責務

```yaml
current_responsibilities:
  - playbook テンプレートの生成
  - project.md の milestone 参照
  - derives_from の設定
  - 基本的な phase 構造の提案

not_responsibilities:
  - ビジネス要件の理解
  - done_criteria の品質保証
  - 自動的な milestone 進行管理

realistic_usage:
  - pm は「たたき台」を作る
  - 人間が内容を確認・修正
  - その後実行開始
```

---

## 実装状態サマリー

| 機能 | 設計 | 実装 | ギャップ |
|------|------|------|----------|
| project 管理 | 自動更新 | 手動 | 大 |
| playbook 作成 | pm 自動 | pm 呼び出し必要 | 中 |
| phase 実行 | 自動順次 | LLM 依存 | 大 |
| 完了検証 | critic 自動 | critic 呼び出し必要 | 大 |
| アーカイブ | 自動 | 提案のみ | 小 |

---

## 結論

3層自動運用は「フレームワーク」であり「自律システム」ではない。

- **できること**: 構造化、整理、強制的なガード
- **できないこと**: 判断の自動化、完全な自律運用

これを受け入れた上で、このリポジトリの価値を再評価する（M120）。
