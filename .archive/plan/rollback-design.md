# ロールバック機構設計書

> **Issue #11: 失敗時の状態復元機能**

---

## 1. 復元ポイント定義

### 1.1 Git 復元ポイント

```yaml
types:
  commit_hash:
    description: 特定のコミットに戻る
    storage: Git 履歴（自動）
    retention: 永続（git gc まで）

  branch_state:
    description: ブランチの特定状態
    storage: Git 履歴
    retention: 永続

  stash:
    description: 一時保存された変更
    storage: git stash
    retention: 手動削除まで
```

### 1.2 state.md 復元ポイント

```yaml
types:
  version:
    description: state.md の特定バージョン
    storage: .claude/state-history/
    format: state-{timestamp}.md
    retention: 最新 50 世代

  snapshot:
    description: 手動スナップショット
    storage: .claude/state-history/snapshots/
    format: snapshot-{name}-{timestamp}.md
    retention: 手動削除まで
```

### 1.3 復元ポイント作成タイミング

```yaml
自動作成:
  - Phase 開始時（state.md バックアップ）
  - git commit 前（pre-commit hook）
  - 重要な state.md 変更時

手動作成:
  - /snapshot コマンドで任意のタイミング
  - git stash で作業内容を一時保存
```

---

## 2. ロールバック対象分類

### 2.1 Git ロールバック

```yaml
対象:
  - 失敗した commit
  - 失敗した push
  - 破損したブランチ状態

操作:
  soft_reset:
    command: "git reset --soft HEAD~{n}"
    effect: コミットを取り消し、変更をステージングに保持
    use_case: コミットメッセージの修正、追加変更

  mixed_reset:
    command: "git reset HEAD~{n}"
    effect: コミットを取り消し、変更をワーキングディレクトリに保持
    use_case: コミット内容の再編成

  hard_reset:
    command: "git reset --hard HEAD~{n}"
    effect: コミットを取り消し、変更も破棄
    use_case: 完全なやり直し（危険）

  revert:
    command: "git revert {commit_hash}"
    effect: 指定コミットを打ち消す新コミットを作成
    use_case: 公開済みコミットの取り消し
```

### 2.2 state.md ロールバック

```yaml
対象:
  - 不正な状態遷移
  - 破損した goal/playbook 参照
  - 誤った focus 設定

操作:
  restore_version:
    command: "/state-rollback {n}"
    effect: n 世代前の state.md に復元

  restore_snapshot:
    command: "/state-restore {snapshot_name}"
    effect: 指定スナップショットに復元

  manual_fix:
    description: 手動で特定セクションのみ修正
```

### 2.3 ワーキングディレクトリロールバック

```yaml
対象:
  - 未コミットの変更
  - 破損したファイル
  - 誤って削除したファイル

操作:
  discard_changes:
    command: "git checkout -- {file}"
    effect: 特定ファイルの変更を破棄

  clean_untracked:
    command: "git clean -fd"
    effect: 追跡されていないファイルを削除

  restore_deleted:
    command: "git checkout HEAD -- {file}"
    effect: 削除したファイルを復元
```

---

## 3. エラーシナリオ分類

### 3.1 Git エラー

```yaml
commit_failure:
  症状: git commit が失敗
  原因:
    - pre-commit hook エラー
    - 空のコミット
    - コンフリクト
  復旧:
    - hook エラーの修正
    - git add でファイル追加
    - コンフリクト解決

push_failure:
  症状: git push が失敗
  原因:
    - リモートとの diverge
    - 認証エラー
    - ネットワークエラー
  復旧:
    - git pull --rebase
    - 認証情報の更新
    - リトライ

merge_conflict:
  症状: マージ中にコンフリクト
  原因: 同じファイルの異なる変更
  復旧:
    - 手動コンフリクト解決
    - git merge --abort
    - git reset --hard ORIG_HEAD
```

### 3.2 state.md エラー

```yaml
invalid_transition:
  症状: forbidden 遷移の検出
  原因: LLM が不正な状態遷移を実行
  復旧:
    - 前の state.md に復元
    - 正しい中間状態を経由

playbook_mismatch:
  症状: playbook と state.md の不整合
  原因: 手動編集、同期漏れ
  復旧:
    - check-coherence.sh で検出
    - playbook または state.md を修正

focus_corruption:
  症状: focus.current が不正
  原因: 誤った編集
  復旧:
    - 正しい focus に修正
    - 関連セクションを同期
```

### 3.3 Hook エラー

```yaml
hook_timeout:
  症状: Hook がタイムアウト
  原因: 無限ループ、重い処理
  復旧:
    - Hook スクリプトの修正
    - タイムアウト設定の調整

hook_block:
  症状: Hook が操作をブロック
  原因: 検証失敗
  復旧:
    - エラー原因の修正
    - 必要に応じて --no-verify（非推奨）

hook_crash:
  症状: Hook が異常終了
  原因: 構文エラー、依存関係の欠落
  復旧:
    - Hook スクリプトの修正
    - 依存関係のインストール
```

---

## 4. 実装ガイド

### 4.1 ファイル構成

```
.claude/
├── scripts/
│   ├── rollback.sh          # Git ロールバックスクリプト
│   └── test-rollback.sh     # ロールバックテスト
├── state-history/
│   ├── state-{timestamp}.md # 自動バックアップ
│   └── snapshots/           # 手動スナップショット
└── commands/
    ├── rollback.md          # /rollback コマンド定義
    └── state-rollback.md    # /state-rollback コマンド定義
```

### 4.2 rollback.sh 実装仕様

```bash
#!/bin/bash
# .claude/scripts/rollback.sh

# 使用方法
# ./rollback.sh git {soft|mixed|hard} {n}  - Git ロールバック
# ./rollback.sh state {n}                   - state.md ロールバック
# ./rollback.sh snapshot {name}             - スナップショット作成
# ./rollback.sh restore {snapshot_name}     - スナップショット復元

# 安全チェック
# - 未コミット変更の確認
# - ユーザー確認（危険な操作）
# - ログ記録
```

### 4.3 Hook 統合

```yaml
PreToolUse(Bash):
  - git commit 失敗時に自動復旧提案
  - git push 失敗時に自動復旧提案

SessionStart:
  - 前セッションの state.md をバックアップ

PreToolUse(Edit):
  - state.md 変更時に自動バックアップ
```

### 4.4 コマンド定義

```yaml
/rollback:
  description: Git ロールバックを実行
  usage: /rollback {soft|mixed|hard|revert} {n|commit_hash}
  examples:
    - /rollback soft 1  # 直前のコミットを soft reset
    - /rollback revert abc123  # 特定コミットを revert

/state-rollback:
  description: state.md を前のバージョンに復元
  usage: /state-rollback {n}
  examples:
    - /state-rollback 1  # 1 世代前に復元
    - /state-rollback 5  # 5 世代前に復元

/snapshot:
  description: 現在の state.md のスナップショットを作成
  usage: /snapshot {name}
  examples:
    - /snapshot before-refactor

/state-restore:
  description: スナップショットから state.md を復元
  usage: /state-restore {snapshot_name}
  examples:
    - /state-restore before-refactor
```

---

## 5. 世代管理ルール

```yaml
自動バックアップ:
  max_generations: 50
  cleanup_trigger: 60 世代超過時
  cleanup_action: 古い 10 世代を削除

スナップショット:
  max_count: 20
  cleanup: 手動のみ

命名規則:
  auto_backup: state-{YYYYMMDD}-{HHMMSS}.md
  snapshot: snapshot-{name}-{YYYYMMDD}-{HHMMSS}.md
```

---

## 6. テスト計画

### 6.1 単体テスト

```yaml
git_rollback:
  - soft reset が正しく動作する
  - mixed reset が正しく動作する
  - hard reset が正しく動作する
  - revert が正しく動作する

state_rollback:
  - 自動バックアップが作成される
  - 指定世代に復元できる
  - スナップショットが作成される
  - スナップショットから復元できる
```

### 6.2 統合テスト

```yaml
error_recovery:
  - commit 失敗後に自動復旧提案が出る
  - state.md 破損後に復元できる
  - playbook 不整合を検出・修復できる

edge_cases:
  - 複数回連続のロールバック
  - 存在しない世代へのロールバック（エラー処理）
  - 空のスナップショットディレクトリ
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。Issue #11 p1 設計。 |
