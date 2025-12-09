---
name: learning
description: 失敗パターンの記録・学習。過去の失敗から学び、同じ問題を繰り返さない。
triggers:
  - エラーが発生したとき
  - critic が FAIL を返したとき
  - 作業が行き詰まったとき
  - 同じ問題が繰り返されているとき
---

# Learning Skill

失敗パターンを記録し、学習するための Skill です。

## 失敗パターンの記録

### 記録先

```yaml
location: .claude/logs/failures.log
format: JSONL（1行1レコード）
retention: 最新 100 件
```

### 記録フォーマット

```json
{
  "timestamp": "2025-12-08T12:00:00+09:00",
  "type": "critic_fail | hook_block | error | timeout",
  "context": {
    "phase": "p2",
    "playbook": "plan/active/playbook-xxx.md",
    "branch": "feat/xxx"
  },
  "failure": {
    "description": "done_criteria の証拠が不十分",
    "details": "ファイル存在確認のみで動作確認なし"
  },
  "resolution": {
    "action": "test_method を実行して動作確認を追加",
    "result": "PASS"
  },
  "lesson": "「設定した」≠「動く」。必ず動作確認が必要"
}
```

## 失敗パターンの分類

```yaml
critic_fail:
  - 証拠不十分
  - done_criteria 未達成
  - 自己報酬詐欺の疑い

hook_block:
  - init-guard: 必須ファイル未読み込み
  - playbook-guard: playbook なしで作業開始
  - protected-edit: 保護ファイル編集試行

error:
  - コマンド実行エラー
  - ファイル操作エラー
  - git 操作エラー

timeout:
  - Phase タイムアウト
  - LOOP 回数超過
```

## 学習の活用

### セッション開始時

```yaml
on_session_start:
  1. failures.log の直近 10 件を確認
  2. 繰り返しパターンがあれば [自認] で警告
  3. 同じ失敗を避けるための対策を意識
```

### 同種のタスク実行時

```yaml
on_similar_task:
  1. failures.log で同種の失敗を検索
  2. 過去の lesson を参照
  3. 対策を適用して実行
```

### 定期的な振り返り

```yaml
periodic_review:
  frequency: 週1回または 10 件蓄積ごと
  action:
    - パターンの分析
    - 根本原因の特定
    - 構造的な改善提案
```

## LLM への指示

```yaml
on_failure:
  1. 失敗を failures.log に記録
  2. 原因を分析
  3. 対策を実行
  4. lesson を記録

on_success_after_failure:
  1. resolution を更新
  2. lesson を明確化
  3. 同種の問題への対策を一般化
```

## 過去 playbook 参照機能（確認事項 #8 対応）

> 中断時に**自動で**以前の playbook を参照し、過去の教訓を活用する。

### アーカイブ構造

```yaml
location: .archive/plan/
contents:
  - playbook-*.md: 完了または中断した playbook
  - vision.md, roadmap.md: 上位計画
  - test-history.md: テスト履歴
```

### 参照トリガー

```yaml
triggers:
  - Phase が行き詰まったとき
  - critic FAIL が連続したとき
  - 同種のタスクを開始するとき
  - エラーが繰り返されるとき
```

### 参照手順

```yaml
on_phase_block:
  1. 現在の Phase 名と done_criteria を取得
  2. .archive/plan/playbook-*.md を検索
  3. 類似の Phase 名または done_criteria を持つ playbook を特定:
     grep -l "類似キーワード" .archive/plan/playbook-*.md
  4. 該当 playbook の evidence / known_issues を参照
  5. 「過去の教訓」として出力:
     - 成功パターン: 何が効果的だったか
     - 失敗パターン: 何を避けるべきか
     - workaround: 代替手段

on_similar_task:
  1. 新しい playbook のタスク名を取得
  2. .archive/plan/ で類似のタスクを検索
  3. 過去の所要時間、問題点、解決策を参照
  4. 計画に反映
```

### 参照出力フォーマット

```yaml
past_reference:
  source: .archive/plan/playbook-xxx.md
  phase: p3
  similarity: "done_criteria に類似の項目あり"
  lessons:
    - success: "テスト駆動で evidence を先に収集"
    - failure: "シミュレーションのみで PASS は NG"
    - workaround: "直接スクリプト実行で検証"
```

### 自動参照の実装

```yaml
implementation:
  hook: session-start.sh 拡張（オプション）
  trigger: phase_block 検出時
  action:
    1. Read: .archive/plan/playbook-*.md
    2. Grep: 現在の Phase キーワード
    3. 該当あれば「過去の教訓」セクションを出力
```

## 失敗ログの例

```json
{"timestamp":"2025-12-08T10:00:00+09:00","type":"hook_block","context":{"phase":"init","playbook":null,"branch":"main"},"failure":{"description":"init-guard でブロック","details":"state.md を Read していない"},"resolution":{"action":"Read(state.md) を実行","result":"PASS"},"lesson":"INIT フェーズでは必ず state.md を Read する"}
{"timestamp":"2025-12-08T11:00:00+09:00","type":"critic_fail","context":{"phase":"p2","playbook":"plan/active/playbook-xxx.md","branch":"feat/xxx"},"failure":{"description":"証拠不十分","details":"ls 出力なしでファイル存在を主張"},"resolution":{"action":"ls コマンドで存在確認","result":"PASS"},"lesson":"証拠は必ずコマンド出力またはファイル引用で示す"}
```

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。task-13 対応。 |
