# current-implementation.md

> **現在の実装状況 - Single Source of Truth**
>
> このファイルは `generate-implementation-doc.sh` によって自動生成されます。
> 手動編集は上書きされる可能性があります。

---

最終更新: 2025-12-10 04:53:24

---

## Hooks

| Hook | トリガー | 役割 |
|------|----------|------|
| session-start | SessionStart | # session-start.sh - LLMの自己認識を形成し、LOOPを開始させる |
| init-guard | PreToolUse:* | # init-guard.sh - セッション開始時の強制的自己認識ガード |
| check-main-branch | PreToolUse:* | # check-main-branch.sh - main ブランチでの作業をブロック |
| consent-guard | PreToolUse:Edit | # consent-guard.sh - 合意プロセス強制フック |
| check-protected-edit | PreToolUse:Edit | # check-protected-edit.sh - 保護対象ファイルの編集をブロック |
| playbook-guard | PreToolUse:Edit | # playbook-guard.sh - Edit/Write 時に playbook=null ならブロック |
| depends-check | PreToolUse:Edit | # depends-check.sh - Phase の depends_on を検証 |
| check-file-dependencies | PreToolUse:Edit | # check-file-dependencies.sh - ファイル依存関係チェック Hook |
| critic-guard | PreToolUse:Edit | # critic-guard.sh - state: done への変更を構造的にブロック |
| scope-guard | PreToolUse:Edit | # scope-guard.sh - done_criteria/done_when の無断変更を検出 |
| executor-guard | PreToolUse:Edit | # executor-guard.sh - Phase の executor を構造的に強制 |
| consent-guard | PreToolUse:Write | # consent-guard.sh - 合意プロセス強制フック |
| check-protected-edit | PreToolUse:Write | # check-protected-edit.sh - 保護対象ファイルの編集をブロック |
| playbook-guard | PreToolUse:Write | # playbook-guard.sh - Edit/Write 時に playbook=null ならブロック |
| check-file-dependencies | PreToolUse:Write | # check-file-dependencies.sh - ファイル依存関係チェック Hook |
| critic-guard | PreToolUse:Write | # critic-guard.sh - state: done への変更を構造的にブロック |
| scope-guard | PreToolUse:Write | # scope-guard.sh - done_criteria/done_when の無断変更を検出 |
| executor-guard | PreToolUse:Write | # executor-guard.sh - Phase の executor を構造的に強制 |
| pre-bash-check | PreToolUse:Bash | # pre-bash-check.sh - Bash コマンド実行前のチェック |
| check-coherence | PreToolUse:Bash | # check-coherence.sh - state.md と playbook の整合性をチェック |
| lint-check | PreToolUse:Bash | # lint-check.sh - 静的解析チェック Hook |
| log-subagent | PostToolUse:Task | # log-subagent.sh - Subagent 発動ログ記録 + critic 結果処理 |
| doc-freshness-check | PostToolUse:Read | # doc-freshness-check.sh - PostToolUse:Read Hook: ドキュメント鮮度チェック |
| archive-playbook | PostToolUse:Edit | # archive-playbook.sh - playbook 完了時の自動アーカイブ提案 |
| create-pr-hook | PostToolUse:Edit | # create-pr-hook.sh - playbook 完了時の PR 自動作成フック |
| update-tracker | PostToolUse:Edit | # update-tracker.sh - PostToolUse:Edit/Write Hook: 変更追跡と自動更新提案 |
| update-tracker | PostToolUse:Write | # update-tracker.sh - PostToolUse:Edit/Write Hook: 変更追跡と自動更新提案 |
| pre-compact | PreCompact | # pre-compact.sh - PreCompact Hook: 完全な状態スナップショット保存 |
| stop-summary | Stop | # stop-summary.sh - Stop Hook: Phase 状態サマリー + 整合性チェック |

---

## SubAgents

| SubAgent | 役割 |
|----------|------|
| critic | **コード変更を含む Phase の評価時、以下の Skills を呼び出す |
| health-checker |  |
| plan-guard |  |
| pm | **重要**: 全てのタスク開始は pm を経由する必要があります� |
| reviewer |  |
| setup-guide |  |

---

## Skills

| Skill | 役割 |
|-------|------|
| beginner-advisor |  |
| consent-process | **合意プロセス（CONSENT）- ユーザープロンプトの誤解釈防止 |
| context-externalization | **コンテキスト外部化 - チャット履歴に依存しない状態管理 |
| context-management | **チャット履歴に依存しない状態管理。プロンプト→意図→ |
| deploy-checker | **デプロイ準備・検証専門スキル** |
| execution-management |  |
| frontend-design | **プロダクション品質のフロントエンドインターフェースを |
| learning | 中断時に**自動で**以前の playbook を参照し、過去の教訓を活 |
| lint-checker | **コード品質チェック専門スキル** |
| plan-management |  |
| post-loop | **POST_LOOP - playbook 完了後の自動処理** |
| state |  |
| test-runner | **テスト実行・検証専門スキル** |

---

## Frameworks

| Framework | 役割 |
|-----------|------|
| done-criteria-validation | **done_criteria の妥当性を評価する固定フレームワーク** |
| playbook-review-criteria | **reviewer SubAgent が playbook をレビューする際の評価基準** |

---

## 設定ファイル

| ファイル | 役割 |
|----------|------|
| .claude/settings.json | Hook 登録、権限設定 |
| .claude/protected-files.txt | 保護対象ファイル一覧 |
| state.md | 現在の状態（focus, playbook, goal） |
| plan/project.md | Macro 計画 |

---

## 統計

- Hooks: 29 個
- SubAgents: 6 個
- Skills: 13 個
- Frameworks: 2 個

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-10 04:53:24 | 自動生成 |
