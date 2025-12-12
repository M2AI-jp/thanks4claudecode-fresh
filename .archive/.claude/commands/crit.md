# /crit - done_criteria の達成状況チェック

現在の `goal.done_criteria` の達成状況を CRITIQUE してください。

## 実行内容

1. state.md から現在の `done_criteria` を取得
2. 各 criteria について:
   - 達成しているか？
   - 証拠はあるか？（ファイル存在、実行結果など）
3. 結果を以下の形式で報告:

```
[CRITIQUE]
done_criteria 達成状況:
  - {criteria1}: {PASS|FAIL} - {証拠}
  - {criteria2}: {PASS|FAIL} - {証拠}
  ...
判定: {全て PASS なら PASS、1つでも FAIL なら FAIL}
```

## 現在の goal セクション

```
!bash awk '/^## goal/,/^## [^g]/' state.md
```

---

**重要**: 「満たしている気がする」ではなく、具体的な証拠を示してください。
