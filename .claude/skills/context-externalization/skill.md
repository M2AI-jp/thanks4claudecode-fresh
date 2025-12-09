# context-externalization

> **コンテキスト外部化 - チャット履歴に依存しない状態管理**

---

## frontmatter

```yaml
name: context-externalization
description: コード変更 + 意図・理由をセットで外部化。Phase 完了時に記録。
triggers:
  - Phase 完了時（必須）
  - ユーザーから新しい指示を受けたとき
  - 重要な技術的発見時
  - セッション終了前
auto_invoke: false  # Phase 完了時に手動参照
```

---

## 目的

```yaml
目的: |
  Claude の長時間作業でコンテキストが膨大になっても、
  ユーザーが「何をやっているか」を追跡可能にする。

記録先: .claude/logs/context-log.md
```

---

## 記録タイミング

- Phase 完了時（必須）
- ユーザーから新しい指示を受けたとき
- 重要な技術的発見時
- セッション終了前

---

## 記録フォーマット

```markdown
### [HH:MM] Entry: {タスク名}
- **User Prompt**: ユーザーの指示（原文または要約）
- **Intent**: Claude が解釈した意図
- **Actions**: 実行した処理
- **Result**: 結果・成果物
- **Technical Notes**: 技術的発見・制約（あれば）
- **Files Changed**: 変更したファイル
- **Playbook Phase**: 該当する Phase（あれば）
```

---

## current-implementation.md 連携

```yaml
条件: context-log の Entry が 5 件以上、または構造的変更時
行動: current-implementation.md への反映を実行
目的: Single Source of Truth の維持
```

---

## 禁止

```yaml
- Entry なしで Phase を done にする
- 「記録した」と言って実際に書かない
```
