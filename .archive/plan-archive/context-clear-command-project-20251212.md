# project.md

> **コンテキスト自動クリア機能 - /cc コマンド**

---

## meta

```yaml
project: context-clear-command
created: 2025-12-12
type: workspace
location: plan/
```

---

## vision

### ユーザーの意図

> 「君自身が一番良いと思うタイミングで /clear を促すとかがあるといい。あとは前もいったけどclear相当のカスタムスラッシュを君が自作して、自分で実行できるようにしたらよくない？」

### 成功の定義

- Claude が自分でコンテキストクリアを判断・実行できる
- 状態が外部化され、セッション継続性が担保される
- 80% 超過時に自動的に /cc を提案する

---

## done_when

```yaml
DW-001:
  id: DW-001
  name: /cc コマンド実装
  status: not_achieved
  priority: high
  estimated_effort: 1h
  depends_on: []
  decomposition:
    playbook_summary: /cc カスタムコマンド作成、CLAUDE.md への自動提案ルール追加、テスト
    success_indicators:
      - /cc コマンドが .claude/commands/cc.md に存在する
      - コマンド実行時に状態が context-log.md に保存される
      - CLAUDE.md に「80% 超過時に /cc を提案する」ルールがある
      - テストで動作確認済み
    phase_hints:
      - name: コマンド作成
        what: /cc コマンドを定義
      - name: CLAUDE.md 更新
        what: 自動提案ルールを追加
      - name: テスト
        what: 動作確認
```

---

## milestones

- [ ] M1: /cc コマンド実装完了
