---
name: abort-playbook
description: playbook を明示的に中断・破棄し、クリーンアップを実行する。
---

# abort-playbook

> **明示的な playbook 中断・破棄処理**

---

## Purpose

playbook を完了せずに中断する場合のクリーンアップ処理を提供する。
正常完了時の archive-playbook.sh とは異なり、PR 作成やマージは行わない。

---

## When to Use

```yaml
triggers:
  - playbook の作業を中断・破棄したい時
  - 別のタスクに切り替えたい時
  - orphan playbook を明示的にクリーンアップしたい時

invocation:
  - Skill(skill='abort-playbook')
  - /abort-playbook
```

---

## Behavior

```yaml
処理フロー:
  1. 未コミット変更の確認
     - 変更がある場合はユーザーに警告
     - コミットするか破棄するか確認

  2. playbook を plan/archive/ へ移動
     - meta セクションに status: aborted を追加
     - aborted_at タイムスタンプを追加

  3. state.md を更新
     - playbook.active = null
     - playbook.branch = null

  4. ブランチの処理（ユーザー確認）
     - 削除するか保持するか確認
     - 削除の場合は main にチェックアウト後に削除
```

---

## Required Action

**以下の手順で実行せよ。**

### Step 1: abort.sh スクリプトを実行

```bash
bash .claude/skills/abort-playbook/abort.sh [playbook_path]
```

引数を省略した場合は `state.md` の `playbook.active` を使用する。

### Step 2: ブランチ処理の確認

abort.sh はブランチを削除しない。ユーザーに確認してから処理する:

```yaml
削除する場合:
  - git checkout main
  - git branch -D {branch_name}

保持する場合:
  - そのまま残す（後で再開可能）
```

---

## Output

```yaml
success:
  - playbook が plan/archive/ に移動（status: aborted）
  - state.md が更新（playbook.active = null）
  - ブランチ処理の案内

failure:
  - playbook.active が null の場合はエラー
  - playbook ファイルが存在しない場合はエラー
```

---

## Difference from archive-playbook

| 項目 | abort-playbook | archive-playbook |
|------|----------------|------------------|
| トリガー | 明示的呼び出し | PostToolUse:Edit（自動） |
| 前提条件 | なし | 全 Phase が done |
| status | aborted | （なし） |
| PR 作成 | なし | あり |
| PR マージ | なし | あり |
| ブランチ処理 | ユーザー確認 | 自動削除 |

---

## Related Files

| ファイル | 役割 |
|----------|------|
| abort.sh | 中断処理の実装 |
| archive-playbook.sh | 正常完了時の処理（参考） |
| health.sh | orphan 検出（abort 提案） |
