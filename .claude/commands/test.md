---
description: done_criteria のテストを実行。特定テストまたは全テストを実行可能。
allowed-tools: Read, Bash
argument-hint: [test-name]
---

# /test - done_criteria テストの実行

`.claude/tests/` 配下のテストを実行してください。

## 引数

- `$1`: （オプション）特定のテスト名（例: t1-playbook-guard）

## 実行内容

引数がない場合:
```bash
bash .claude/hooks/test-done-criteria.sh
```

引数がある場合:
```bash
bash .claude/hooks/test-done-criteria.sh "" $1
```

## 利用可能なテスト

```
!bash ls -la .claude/tests/*.sh 2>/dev/null || echo "No tests found"
```

---

テスト結果を報告し、失敗があれば原因を分析してください。
