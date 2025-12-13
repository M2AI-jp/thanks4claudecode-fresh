# /changelog コマンド

Claude Code の CHANGELOG を確認し、新機能や改善点を把握します。

## 使用方法

```
/changelog          # キャッシュから CHANGELOG を表示
/changelog --force  # キャッシュを強制更新して表示
```

## 実行内容

1. `.claude/cache/changelog-latest.md` から CHANGELOG を読み込む
2. `.claude/cache/changelog-meta.json` からメタデータを読み込む
3. 最新バージョン情報と主要な変更点を要約して表示する

## 強制更新（--force）

`--force` オプションが指定された場合:
1. キャッシュを削除
2. GitHub から最新の CHANGELOG を取得
3. キャッシュを更新

## 指示

以下の手順で CHANGELOG を確認してください:

1. **メタデータ確認**: `.claude/cache/changelog-meta.json` を読み込み、最終更新日時とバージョン情報を確認
2. **CHANGELOG 読込**: `.claude/cache/changelog-latest.md` を読み込み
3. **要約出力**: 以下の形式で出力
   - 最新バージョン
   - 最終キャッシュ日時
   - 主要な新機能（5件程度）
   - このリポジトリに関連する機能（Hooks, SubAgents, Skills 等）

引数に `--force` が含まれる場合:
1. WebFetch で https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md を取得
2. `.claude/cache/changelog-latest.md` を更新
3. `.claude/cache/changelog-meta.json` を更新（バージョン、タイムスタンプ）
4. 上記の要約を出力
