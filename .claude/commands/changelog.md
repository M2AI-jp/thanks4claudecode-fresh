# /changelog コマンド

Claude Code の CHANGELOG を確認し、新機能や改善点を把握します。

## 使用方法

```
/changelog           # キャッシュから CHANGELOG を表示
/changelog --force   # キャッシュを強制更新して表示
/changelog --suggest # このリポジトリへの適用可能性分析
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

## 適用可能性分析（--suggest）

引数に `--suggest` が含まれる場合、以下の詳細な分析を実行:

1. **リポジトリプロファイル読込**: `.claude/cache/repo-profile.json` を読み込む
2. **CHANGELOG 読込**: `.claude/cache/changelog-latest.md` を読み込む
3. **マッチング分析**: CHANGELOG の新機能と repo-profile.json のキーワードを照合
4. **優先度分類**:
   - 🔴 **高優先度 (High)**: すぐに活用可能な機能
   - 🟡 **中優先度 (Medium)**: 検討の余地がある機能
   - 🟢 **低優先度 (Low)**: 将来的に検討する機能
5. **活用方法提示**: 各機能について
   - 現在の使用状況
   - 具体的な活用方法
   - 影響を受けるファイル

### 出力フォーマット（--suggest）

```markdown
## このリポジトリへの適用可能性分析

### 🔴 高優先度（すぐに活用可能）

1. **{機能名}** (v{version})
   - 現状: {current_usage}
   - 提案: {how_to_use}
   - 影響: {affected_files}

### 🟡 中優先度（検討の余地あり）

2. **{機能名}** (v{version})
   - 現状: {current_usage}
   - 提案: {how_to_use}
   - トレードオフ: {trade_offs}

### 🟢 低優先度（将来検討）

3. **{機能名}** (v{version})
   - 提案: {how_to_use}
```

### 参照ファイル

- `.claude/cache/repo-profile.json`: リポジトリの特性定義
  - `features_used`: 使用中の機能カテゴリ
  - `interest_areas`: 関心領域
  - `priority_keywords`: 優先度別キーワード
  - `feature_mapping`: 既知の機能マッピング（活用方法含む）
