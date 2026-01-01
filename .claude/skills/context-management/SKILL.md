---
name: context-management
description: /compact 最適化と履歴要約のガイドライン。コンテキスト管理の専門知識を提供。
triggers:
  - /compact を実行する前
  - コンテキストが 80% を超えたとき
  - セッション終了時（履歴要約）
---

# Context Management Skill

コンテキスト管理の専門知識を提供する Skill です。

## /compact 最適化ガイドライン（task-09）

### 優先保持情報（高優先度）

```yaml
must_keep:
  - analysis_result: prompt-analyzer の分析結果全体
  - translated_requirements: term-translator の変換結果全体
  - user_approved_understanding: ユーザーが承認した理解内容
  - done_criteria: 現在の Phase の完了条件
  - current_phase: 作業中の Phase 情報
  - playbook_path: アクティブな playbook のパス
  - branch: 現在のブランチ名
  - recent_errors: 直近のエラーと対処法
  - user_decisions: ユーザーが明示した意思決定
```

### 削除候補（低優先度）

```yaml
can_remove:
  - completed_phases: 完了済み Phase の詳細（要約可）
  - file_contents: 大きなファイル内容（パスのみ保持）
  - command_outputs: 長いコマンド出力（要点のみ）
  - exploration_results: 探索結果（結論のみ）
```

### /compact 実行前のチェックリスト

```yaml
pre_compact:
  - [ ] state.md の現在の goal.done_criteria を確認
  - [ ] 作業中の Phase の status を確認
  - [ ] 未コミットの変更がないか確認
  - [ ] 重要な意思決定をメモ

post_compact:
  - [ ] [自認] を再宣言
  - [ ] done_criteria を再確認
  - [ ] 作業を続行
```

## 履歴要約ガイドライン（task-10）

### セッション終了時の要約フォーマット

```yaml
session_summary:
  date: {ISO8601}
  duration: {開始-終了}
  branch: {ブランチ名}

  completed:
    - {完了した Phase/タスク}

  in_progress:
    - {進行中の作業}
    - next_step: {次にやるべきこと}

  decisions:
    - {ユーザーが決定した重要事項}

  issues:
    - {発生した問題と対処法}

  commits:
    - {コミットハッシュ}: {メッセージ}
```

### 要約の保存先

```yaml
storage:
  location: .claude/session-history/
  format: session-{YYYYMMDD-HHMMSS}.md
  retention: 最新 30 件
```

### LLM への指示

```yaml
on_session_end:
  1. 上記フォーマットで要約を作成
  2. .claude/session-history/ に保存
  3. state.md の session_tracking を更新

on_session_start:
  1. 最新の session-history を確認
  2. 前回の in_progress を把握
  3. [自認] に反映
```

## コンテキスト監視

```yaml
thresholds:
  warning: 70%   # 警告表示
  critical: 80%  # /compact 推奨
  danger: 90%    # /clear 推奨

monitoring:
  - /context でコンテキスト使用率を確認
  - 80% 超過で「コンテキスト使用率が高いです。/compact を検討してください」
  - 90% 超過で「/clear を推奨します。state.md が真実源です」
```

## コンテキスト外部化（context-log）

> **チャット履歴に依存しない状態管理。プロンプト→意図→処理→結果を外部ファイルに記録。**

### 記録先

```yaml
file: .claude/logs/context-log.md
purpose: |
  Claude の長時間作業でコンテキストが膨大になっても、
  ユーザーが「何をやっているか」を追跡可能にする。
```

### 記録フォーマット

```markdown
### [HH:MM] Entry: {タスク名}
- **User Prompt**: ユーザーの指示（原文または要約）
- **Intent**: Claude が解釈した意図
- **Actions**: 実行した処理
- **Result**: 結果・成果物
- **Technical Notes**: 技術的発見・制約（あれば）
- **Files Changed**: 変更したファイル
- **Playbook Phase**: 該当する Phase（あれば）
```

### 記録タイミング

```yaml
required:
  - Phase 完了時（critic PASS 後）
  - セッション終了前

recommended:
  - ユーザーから新しい指示を受けたとき
  - 重要な技術的発見時
  - 5 回以上の Edit/Write 実行後
```

### current-implementation.md 連携

```yaml
trigger:
  - context-log の Entry が 5 件以上溜まった
  - 構造的な変更（新 Hook、新 SubAgent、アーキテクチャ変更）

action: |
  current-implementation.md に該当セクションを更新
  → Single Source of Truth の維持

check_command: |
  Entry 数を確認:
  grep -c "^### \[" .claude/logs/context-log.md
```

### 運用ルール

```yaml
禁止:
  - Entry なしで Phase を done にする
  - 「記録した」と言って実際に書かない
  - context-log を編集せずに次のタスクに移る

推奨:
  - Entry は簡潔に（各項目 1-2 行）
  - Technical Notes は発見時のみ記載
  - Files Changed は主要ファイルのみ（5 件以下）
```

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-09 | context-log 機能追加。プロンプト→意図→処理→結果の外部化。current-implementation.md 連携。 |
| 2025-12-08 | 初版作成。task-09, task-10 対応。 |
