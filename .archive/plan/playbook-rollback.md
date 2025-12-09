# playbook-rollback.md

> **Issue #11: ロールバック機能 - 失敗時の状態復元機能**

---

## meta

```yaml
project: rollback-feature
branch: feat/rollback-recovery
created: 2025-12-08
issue: task-11
category: 回復・監視
priority: high
```

---

## goal

```yaml
summary: 失敗時の状態復元機能（ロールバック）を実装
done_when:
  - git ロールバック機構が実装される
  - state.md ロールバック機構が実装される
  - 復元テストが全て PASS する
  - playbook 実行失敗時の自動復元が動作する
```

---

## phases

### p1: ロールバック機構設計

```yaml
id: p1
name: ロールバック機構設計
goal: 復元ポイント・スナップショット管理・復元対象を定義
executor: claude
depends_on: []
done_criteria:
  - rollback-design.md が作成される
  - 復元ポイント（commit hash, state.md version）の定義が明記される
  - ロールバック対象の分類が定義される（git, state.md, working directory）
  - エラーシナリオの分類が完了する
  - 実装ガイドが作成される
  - 設計ドキュメントが実装段階で参照可能な形式である

test_method: |
  # P1 は設計フェーズ。以下をドキュメント検査で確認
  1. rollback-design.md セクション 1 で復元ポイントが定義されているか
  2. rollback-design.md セクション 2 で対象分類が git/state.md/ワーキングディレクトリの3層か
  3. rollback-design.md セクション 3 でエラーシナリオが 3 カテゴリ以上か
  4. rollback-design.md セクション 4 で実装ガイドが全て記載されているか
  5. 実装段階（p2-p4）で参照可能な詳細度になっているか確認

evidence:
  ドキュメント: plan/active/rollback-design.md（8486 bytes）
  セクション1_復元ポイント: Git 復元ポイント、state.md 復元ポイント、作成タイミング定義
  セクション2_対象分類: Git/state.md/ワーキングディレクトリの3層分類
  セクション3_エラーシナリオ: Git エラー/state.md エラー/Hook エラーの3カテゴリ
  セクション4_実装ガイド: ファイル構成/rollback.sh 仕様/Hook 統合/コマンド定義
  critic: PASS

status: done
max_iterations: 5
```

### p2: git ロールバック機能実装

```yaml
id: p2
name: git ロールバック機能実装
goal: git ロールバックの手動コマンド機能を実装（LLM が失敗検知時に使用）
executor: claude
depends_on: [p1]
done_criteria:
  - rollback.sh スクリプトが作成される
  - git reset（soft/mixed/hard）機能が実装される
  - git revert 機能が実装される
  - stash 操作機能が実装される
  - /rollback コマンドが実装される
  - --help と status コマンドで動作確認済み

test_method: |
  # P2 は手動ロールバック機能の実装
  1. ls -la .claude/scripts/rollback.sh で存在・実行権限を確認
  2. ./rollback.sh --help でヘルプ表示を確認
  3. ./rollback.sh status でロールバック候補表示を確認
  4. ls -la .claude/commands/rollback.md でコマンド定義を確認

evidence:
  rollback_sh: .claude/scripts/rollback.sh（実行権限付き、8109 bytes）
  help出力: ヘルプ表示 ✓（soft/mixed/hard/revert/stash/status サブコマンド）
  status出力: ロールバック候補表示 ✓
  rollback_command: .claude/commands/rollback.md
  critic: PASS

status: done
max_iterations: 5

note: |
  「自動復元」について:
  - Claude Code の Hook 構造では PostBash（コマンド失敗後の自動実行）がない
  - 「自動復元」は LLM が失敗を検知した際に /rollback を使用する形で実現
  - CLAUDE.md に「git 失敗時は /rollback を検討」ルールを追加予定（p4 で統合）
```

### p3: state.md ロールバック機構実装

```yaml
id: p3
name: state.md ロールバック機構実装
goal: state.md のバージョン管理と復元機能を実装
executor: claude
depends_on: [p1]
done_criteria:
  - .claude/state-history/ ディレクトリが作成される
  - backup コマンドでバックアップが作成できる
  - rollback コマンドで復元できる
  - snapshot/restore で名前付き保存・復元ができる
  - /state-rollback コマンドが実装される
  - 世代管理ルール（最大50世代）が実装される

test_method: |
  # P3 は state.md ロールバック機能の実装
  1. ls -la .claude/state-history/ でディレクトリ存在確認
  2. ./state-rollback.sh --help でヘルプ表示確認
  3. ./state-rollback.sh backup でバックアップ作成確認
  4. ./state-rollback.sh list でバックアップ一覧確認
  5. ls -la .claude/commands/state-rollback.md でコマンド定義確認

evidence:
  state_history_dir: .claude/state-history/ 作成済み
  state_rollback_sh: .claude/scripts/state-rollback.sh（実行権限付き）
  help出力: ヘルプ表示 ✓（backup/list/rollback/snapshot/restore/cleanup）
  backup動作: バックアップ作成 ✓（state-20251208-133005.md）
  list動作: バックアップ一覧表示 ✓
  state_rollback_command: .claude/commands/state-rollback.md
  世代管理: 最大50世代、60超過で自動クリーンアップ
  critic: PASS

status: done
max_iterations: 5

note: |
  「自動バックアップ」について:
  - session-start.sh への統合は保護ファイルのため見送り
  - LLM が Phase 開始時に /state-rollback backup を実行する運用を推奨
  - CLAUDE.md に「Phase 開始時は /state-rollback backup」ルールを追加予定（p4 で統合）
```

### p4: 復元テストと検証

```yaml
id: p4
name: 復元テストと検証
goal: ロールバック機能の全テストケースを検証
executor: claude
depends_on: [p2, p3]
done_criteria:
  - test-rollback.sh がテストスクリプトとして作成される
  - git ロールバック機能テストが PASS する
  - state.md ロールバック機能テストが PASS する
  - 設計ドキュメントテストが PASS する
  - 全テストケース実行結果で PASS が確認される

test_method: |
  1. ./.claude/scripts/test-rollback.sh を実行
  2. テスト結果を確認：
     - Git Rollback Tests: 全 PASS
     - state.md Rollback Tests: 全 PASS
     - Design Document Tests: 全 PASS
  3. Results: PASS=15, FAIL=0 を確認

evidence:
  test_script: .claude/scripts/test-rollback.sh
  test_result: PASS=15, FAIL=0
  git_rollback_tests:
    - rollback.sh exists: PASS
    - rollback.sh is executable: PASS
    - rollback.sh --help works: PASS
    - rollback.sh status works: PASS
    - /rollback command exists: PASS
  state_rollback_tests:
    - state-rollback.sh exists: PASS
    - state-rollback.sh is executable: PASS
    - state-rollback.sh --help works: PASS
    - state-history directory exists: PASS
    - state-rollback.sh backup works: PASS
    - state-rollback.sh list works: PASS
    - backup files exist: PASS
    - /state-rollback command exists: PASS
  design_tests:
    - rollback-design.md exists: PASS
    - playbook-rollback.md exists: PASS
  critic: PASS

status: done
max_iterations: 5
```

---

## 実装ロードマップ

```yaml
p1:
  - 状態復元ポイント戦略の文書化
  - スナップショット管理方式の設計
  - エラーシナリオ分類表の作成

p2:
  - .claude/scripts/rollback.sh の実装
  - PreToolUse Hook での自動エラー検知
  - /rollback コマンド定義

p3:
  - state-history ディレクトリ構造の設計
  - 自動バックアップ機構の実装
  - /state-rollback コマンド定義

p4:
  - test-rollback.sh スクリプトの作成
  - 全テストケース実行
  - ドキュメント整備
```

---

## 技術仕様

### ロールバック対象

```yaml
git:
  - 失敗した commit を reset
  - 失敗した push を revert
  - ブランチを安全な状態に戻す

state_md:
  - 前バージョンの state.md を復元
  - .claude/state-history/ に世代管理
  - max 50 世代を保持（圧縮/削除）

working_directory:
  - 失敗時の作業ファイルを保持
  - git clean で作業ディレクトリをリセット
```

### 復元トリガー

```yaml
自動トリガー:
  - git commit FAIL
  - git push FAIL
  - script ERROR

手動トリガー:
  - /rollback {commit_hash}
  - /state-rollback {n_generations_back}
  - /rollback-all
```

---

## 参照資料

- plan/project.md: task-11 定義
- CONTEXT.md: ロールバック機構の設計思想
- CLAUDE.md: エラーハンドリングルール

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| 2025-12-08 | 初版作成。Phase 4 設計。 |
