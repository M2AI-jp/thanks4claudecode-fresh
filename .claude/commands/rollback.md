# /rollback コマンド

Git ロールバックを実行します。

## 使用方法

```
/rollback {soft|mixed|hard|revert|stash|status} [n|commit_hash]
```

## サブコマンド

### soft - Soft Reset
コミットを取り消し、変更をステージングに保持します。
```
/rollback soft 1    # 直前の1コミットを soft reset
/rollback soft 3    # 直前の3コミットを soft reset
```

### mixed - Mixed Reset
コミットを取り消し、変更をワーキングディレクトリに保持します。
```
/rollback mixed 1   # 直前の1コミットを mixed reset
```

### hard - Hard Reset（危険）
コミットを取り消し、変更も破棄します。
```
/rollback hard 1    # 直前の1コミットを hard reset（変更は失われます）
```

### revert - Revert
特定のコミットを打ち消す新しいコミットを作成します。
```
/rollback revert abc123   # abc123 を revert
```

### stash - Stash 操作
```
/rollback stash           # 変更を stash に退避
/rollback stash-pop       # stash から復元
```

### status - ステータス表示
```
/rollback status          # ロールバック候補を表示
```

## 実行コマンド

```bash
.claude/scripts/rollback.sh $ARGUMENTS
```

## 注意事項

- `hard` は変更を完全に破棄します。実行前に確認が表示されます。
- 未コミットの変更がある場合、`hard` は実行できません。先に `stash` してください。
- `revert` は公開済みコミットの取り消しに使用します。
