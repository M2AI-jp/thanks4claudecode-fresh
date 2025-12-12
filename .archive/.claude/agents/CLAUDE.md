# .claude/agents/

> **SubAgents - 特定の検証・操作を担当する専門エージェント**

---

## 役割

SubAgents は Claude Code の Task ツールで呼び出される専門エージェントです。
各 SubAgent は特定の検証や操作を担当し、メインの Claude とは独立して動作します。

---

## 呼び出し方法

```
Task(subagent_type="agent-name")
```

例: `Task(subagent_type="critic")` で critic SubAgent を呼び出し

---

## 利用可能な SubAgents

| SubAgent | 役割 | 主な用途 |
|----------|------|----------|
| critic | done_criteria の検証 | Phase 完了前の必須検証 |
| pm | playbook 管理 | タスク開始、playbook 作成 |
| reviewer | コード/設計/playbook レビュー | playbook 検証、PR レビュー、設計評価 |
| health-checker | システム状態監視 | state.md/playbook 整合性確認 |
| Explore | コードベース探索 | ファイル検索、構造理解 |

> **playbook レビュー**: `Task(subagent_type='reviewer', prompt='playbook をレビュー。.claude/frameworks/playbook-review-criteria.md を参照')`

---

## SubAgent の構成

各 SubAgent は以下のファイルで定義されます：
- `{agent-name}.md` - SubAgent の詳細定義

---

## 連携

- **Hooks** → SubAgent 呼び出しのトリガー
- **Skills** → SubAgent が内部で呼び出す専門知識
- **Frameworks** → SubAgent が参照する評価基準
