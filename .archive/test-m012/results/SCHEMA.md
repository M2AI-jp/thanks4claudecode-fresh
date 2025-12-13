# Test Results Schema

> **テスト結果ファイルの標準フォーマット定義**

---

## 必須フィールド

```yaml
result_file:
  header:
    title: string      # テスト結果のタイトル
    timestamp: ISO8601 # 実行日時
    executor: string   # 実行者（claudecode | codex | coderabbit | user）

  summary:
    total: number      # テスト総数
    pass: number       # PASS 数
    fail: number       # FAIL 数
    skip: number       # SKIP 数（任意）

  results:
    - id: string       # テスト ID（例: H01, SA01, SK01）
      name: string     # テスト名
      result: enum     # PASS | FAIL | SKIP
      evidence: string # 検証根拠（コマンド出力、ファイル存在等）
```

---

## テスト ID 命名規則

| プレフィックス | 対象 | 例 |
|---------------|------|-----|
| H | Hook | H01, H02, ... H29 |
| SA | SubAgent | SA01, SA02, ... SA10 |
| SK | Skill | SK01, SK02, ... SK10 |

---

## Result 値の定義

| Result | 意味 | 条件 |
|--------|------|------|
| PASS | テスト成功 | 全検証項目が期待値と一致 |
| FAIL | テスト失敗 | 1つ以上の検証項目が期待値と不一致 |
| SKIP | テスト未実行 | 前提条件未充足（例: 認証エラー） |

---

## Evidence 記載ガイドライン

```yaml
good_examples:
  - "test -f .claude/hooks/session-start.sh → exit 0"
  - "grep 'last_start' state.md → 2025-12-13 16:00"
  - "bash -n hook.sh → syntax OK"

bad_examples:
  - "確認しました"  # 具体性なし
  - "問題なし"      # 何を確認したか不明
  - "動作OK"        # 根拠なし
```

---

## ファイル構成

```
test/results/
├── SCHEMA.md           # 本ファイル（スキーマ定義）
├── hooks-results.md    # Hook テスト結果
├── subagents-results.md # SubAgent テスト結果
├── skills-results.md   # Skill テスト結果
├── summary.md          # 総合サマリー
└── issues.md           # FAIL 項目詳細（該当時のみ）
```
