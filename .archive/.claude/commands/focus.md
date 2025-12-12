# /focus - レイヤーフォーカスの切り替え

state.md の `focus.current` を指定したレイヤーに変更してください。

## 引数

- `$1`: 切り替え先のレイヤー名（plan-template | workspace | setup）

## 実行内容

1. 現在の `focus.current` を確認
2. 指定されたレイヤーに変更
3. 変更結果を報告

## 現在の state.md focus セクション

```
!bash grep -A5 "## focus" state.md
```

## 変更先

`$ARGUMENTS`

---

**注意**: 引数が空の場合は、現在のフォーカスを表示するだけにしてください。
