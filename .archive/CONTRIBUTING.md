# CONTRIBUTING

**このワークスペーステンプレートへの貢献ガイドライン**

---

## 貢献の種類

### 1. バグ報告

Issue を作成してください：

```markdown
## 症状
何が起きたか

## 再現手順
1. ...
2. ...

## 期待する動作
何が起きるべきだったか

## 環境
- macOS:
- Claude Code:
```

### 2. 機能提案

Issue を作成し、以下を含めてください：
- 何を解決したいか（WHY）
- どう解決するか（HOW）
- 影響範囲

### 3. プルリクエスト

1. フォーク
2. ブランチ作成: `fix/xxx` または `feat/xxx`
3. 変更
4. テスト
5. PR 作成

---

## 開発ルール

### ブランチ命名

```
fix/   - バグ修正
feat/  - 新機能
docs/  - ドキュメント
test/  - テスト
refactor/ - リファクタリング
```

### コミットメッセージ

```
feat: 新機能の説明
fix: 修正の説明
docs: ドキュメント更新
test: テスト追加
refactor: リファクタリング
```

### 保護ファイル

以下のファイルは直接編集しないでください：
- `CLAUDE.md`
- `CONTEXT.md`
- `.claude/hooks/*.sh`

変更が必要な場合は Issue で提案してください。

---

## テスト

変更を提出する前に、以下を確認：

```bash
# 整合性チェック
bash .claude/hooks/check-coherence.sh

# done_criteria テスト
bash .claude/hooks/test-done-criteria.sh
```

---

## コードレビュー

PR は CodeRabbit による自動レビューを受けます。
指摘事項は修正後に再プッシュしてください。

---

## 質問

不明点は Issue で質問してください。
