# /state-rollback コマンド

state.md のバックアップと復元を管理します。

## 使用方法

```
/state-rollback {backup|list|rollback|snapshot|restore|cleanup} [引数]
```

## サブコマンド

### backup - バックアップ作成
現在の state.md をバックアップします。
```
/state-rollback backup
```

### list - バックアップ一覧
バックアップとスナップショットの一覧を表示します。
```
/state-rollback list
```

### rollback - 世代ロールバック
n 世代前の state.md に復元します。
```
/state-rollback rollback 1    # 1 世代前に復元
/state-rollback rollback 5    # 5 世代前に復元
```

### snapshot - スナップショット作成
名前付きスナップショットを作成します。
```
/state-rollback snapshot phase-done
/state-rollback snapshot before-refactor
```

### restore - スナップショット復元
スナップショットから復元します。
```
/state-rollback restore phase-done
/state-rollback restore before-refactor
```

### cleanup - クリーンアップ
古いバックアップを削除します（最大50世代を保持）。
```
/state-rollback cleanup
```

## 実行コマンド

```bash
.claude/scripts/state-rollback.sh $ARGUMENTS
```

## 世代管理ルール

- 最大 50 世代を保持
- 60 世代超過時に古い 10 世代を自動削除
- スナップショットは手動削除のみ

## 注意事項

- 復元前に自動的にバックアップが作成されます
- 復元は確認プロンプトが表示されます
- スナップショットは重要なマイルストーンで作成してください
