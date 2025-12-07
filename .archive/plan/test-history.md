# test-history.md

> **テスト実行履歴（git 追跡対象）**
>
> 詳細なテスト定義とログは test/ ディレクトリ（.gitignore）にあります。

---

## テンプレート

新規テスト追加時:

```yaml
## YYYY-MM-DD: {テスト名}

test_id: {id}
date: {日時}
executor: {実行者}
branch: {ブランチ}
overall_status: PASS | FAIL | PARTIAL

### 目的
{テストの目的}

### 結果サマリー
| シナリオ | 内容 | 結果 |
|----------|------|------|
| S1 | ... | ✓ PASS |

### 詳細ファイル
- テスト定義: test/core/{name}.test.md
- 詳細結果: test/results/{date}-{name}.md
```

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| - | 初期状態 |
