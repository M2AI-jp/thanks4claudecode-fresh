# Hook Responsibilities（Hook 責任分担）

> 各 Hook の責任とアクティブ/手動の区分

---

## Hook 優先度分類

### Tier 1: 常時アクティブ（settings.json 登録）

| Hook | Trigger | 責任 | 理由 |
|------|---------|------|------|
| init-guard.sh | PreToolUse:* | 必須ファイル Read 強制 | セッション基盤 |
| check-main-branch.sh | PreToolUse:* | main ブランチ作業禁止 | コード保護 |
| check-protected-edit.sh | PreToolUse:Edit/Write | 保護ファイル編集禁止 | セキュリティ |
| playbook-guard.sh | PreToolUse:Edit/Write | playbook 必須 | 計画駆動 |
| pre-bash-check.sh | PreToolUse:Bash | Bash 実行前チェック | 安全性 |
| prompt-guard.sh | UserPromptSubmit | プロンプト検証 | 入力検証 |
| session-start.sh | SessionStart | セッション開始処理 | ブートストラップ |
| session-end.sh | SessionEnd | セッション終了処理 | クリーンアップ |
| log-subagent.sh | PostToolUse:Task | SubAgent ログ | 監査 |
| archive-playbook.sh | PostToolUse:Edit | アーカイブ提案 | ライフサイクル |
| cleanup-hook.sh | PostToolUse:Edit | 一時ファイル削除 | クリーンアップ |
| stop-summary.sh | Stop | 停止時サマリー | 状態保存 |
| pre-compact.sh | PreCompact | compact 前スナップショット | コンテキスト管理 |

### Tier 2: 手動実行（settings.json 未登録）

| Hook | 旧 Trigger | 責任 | 手動実行方法 |
|------|------------|------|--------------|
| consent-guard.sh | PreToolUse:Edit | 合意プロセス強制 | `bash .claude/hooks/consent-guard.sh` |
| depends-check.sh | PreToolUse:Edit | Phase 依存チェック | `bash .claude/hooks/depends-check.sh` |
| critic-guard.sh | PreToolUse:Edit | critic なしの done 禁止 | `bash .claude/hooks/critic-guard.sh` |
| scope-guard.sh | PreToolUse:Edit | done_criteria 無断変更検出 | `bash .claude/hooks/scope-guard.sh` |
| executor-guard.sh | PreToolUse:Edit | executor 不一致禁止 | `bash .claude/hooks/executor-guard.sh` |
| subtask-guard.sh | PreToolUse:Edit | subtask 検証強制 | `bash .claude/hooks/subtask-guard.sh` |
| check-coherence.sh | PreToolUse:Bash | state/playbook 整合性 | `bash .claude/hooks/check-coherence.sh` |
| lint-check.sh | PreToolUse:Bash | 静的解析チェック | `bash .claude/hooks/lint-check.sh` |
| create-pr-hook.sh | PostToolUse:Edit | PR 自動作成 | `bash .claude/hooks/create-pr-hook.sh` |

### Tier 3: ユーティリティ（直接呼び出し用）

| Hook | 責任 | 使用方法 |
|------|------|----------|
| create-pr.sh | PR 作成 | `bash .claude/hooks/create-pr.sh` |
| merge-pr.sh | PR マージ | `bash .claude/hooks/merge-pr.sh` |
| generate-repository-map.sh | マップ生成 | `bash .claude/hooks/generate-repository-map.sh` |
| role-resolver.sh | 役割解決 | `bash .claude/hooks/role-resolver.sh` |
| system-health-check.sh | 健全性チェック | `bash .claude/hooks/system-health-check.sh` |
| test-hooks.sh | Hook テスト | `bash .claude/hooks/test-hooks.sh` |
| failure-logger.sh | 失敗ログ記録 | 他スクリプトから呼び出し |

---

## 削減の根拠

### 削除した Hook

PreToolUse:Edit から削除:
- consent-guard.sh: 毎回の合意は過剰、必要時に手動実行
- depends-check.sh: Phase 依存は厳密すぎた
- critic-guard.sh: done 変更時のみ必要、毎編集には不要
- scope-guard.sh: done_criteria 監視は過剰
- executor-guard.sh: 役割チェックは手動で十分
- subtask-guard.sh: 3検証は手動で実行

PreToolUse:Bash から削除:
- check-coherence.sh: 整合性チェックは必要時に手動
- lint-check.sh: 静的解析は必要時に手動

PostToolUse:Edit から削除:
- create-pr-hook.sh: PR 作成は手動で制御

### 残した Hook の理由

| Hook | 残した理由 |
|------|-----------|
| init-guard.sh | セッション開始に必須、これがないと状態が不明 |
| check-main-branch.sh | main 直接作業は危険、常にブロック |
| check-protected-edit.sh | セキュリティ上必須、CLAUDE.md 等の保護 |
| playbook-guard.sh | 計画駆動の根幹、これがないと無計画作業が可能に |
| pre-bash-check.sh | 危険なコマンドの防止 |

---

## 変更履歴

| 日時 | 変更内容 |
|------|----------|
| 2025-12-18 | M105: PreToolUse:Edit を 8→2 に削減、PreToolUse:Bash を 3→1 に削減 |
