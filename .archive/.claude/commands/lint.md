# /lint - 整合性チェックの実行

state.md と playbook の整合性をチェックしてください。

## 実行内容

```bash
bash .claude/hooks/check-coherence.sh
```

## チェック項目

1. 全レイヤーの state と playbook の整合性
2. focus.current レイヤーの詳細チェック
3. staged ファイルと focus の矛盾検出

---

結果を報告し、問題があれば修正案を提示してください。
