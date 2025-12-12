# playbook-context-clear-command-dw001

> **Claude が自分でコンテキストクリアを実行できる /cc コマンド**

---

## meta

```yaml
project: context-clear-command
branch: feat/context-clear-command
created: 2025-12-12
issue: null
derives_from: DW-001
reviewed: false
```

---

## goal

```yaml
summary: "/cc カスタムコマンド作成、CLAUDE.md への自動提案ルール追加、テスト"
done_when:
  - /cc コマンドが .claude/commands/cc.md に存在する
  - コマンド実行時に状態が context-log.md に保存される
  - CLAUDE.md に「80% 超過時に /cc を提案する」ルールがある
  - テストで動作確認済み
```

---

## phases

### Phase 1: /cc コマンド作成

> /cc コマンドを定義し、状態外部化ロジックを実装

#### done_criteria

- .claude/commands/cc.md が存在する
- コマンドに状態保存の指示が含まれている
- SlashCommand ツールで実行可能

#### tasks

```yaml
tasks:
  - id: p1-t1
    name: /cc コマンドファイル作成
    subtasks:
      - step: ".claude/commands/cc.md を作成"
        executor: claudecode
        criteria: "ls .claude/commands/cc.md が存在確認できる"
        status: "[x]"
      - step: "コマンド内容を記述（状態保存 + /clear 促進）"
        executor: claudecode
        criteria: "grep 'context-log' .claude/commands/cc.md がヒットする"
        status: "[x]"
```

---

### Phase 2: CLAUDE.md 更新

> 80% 超過時に /cc を自動提案するルールを追加

#### done_criteria

- CLAUDE.md の CONTEXT セクションに自動提案ルールがある
- 80% の閾値が明記されている

#### tasks

```yaml
tasks:
  - id: p2-t1
    name: CLAUDE.md に自動提案ルール追加
    subtasks:
      - step: "CONTEXT セクションに /cc 自動提案ルールを追加"
        executor: claudecode
        criteria: "grep '/cc' CLAUDE.md がヒットする"
        status: "[x]"
      - step: "80% 超過時のトリガー条件を明記"
        executor: claudecode
        criteria: "grep '80%' CLAUDE.md がヒットする"
        status: "[x]"
```

---

### Phase 3: テスト

> 動作確認

#### done_criteria

- /cc コマンドが SlashCommand で実行可能
- 実行後に context-log.md に記録が追加される

#### tasks

```yaml
tasks:
  - id: p3-t1
    name: 動作テスト
    subtasks:
      - step: "/cc コマンドを SlashCommand で呼び出し"
        executor: claudecode
        criteria: "エラーなく実行される"
        status: "[x]"
        note: "新規作成コマンドはセッション再起動後に認識。手動実行でテスト済み。"
      - step: "context-log.md に記録が追加されることを確認"
        executor: claudecode
        criteria: "context-log.md に Entry が追加される"
        status: "[x]"
  tools:
    subagents: [critic]
    skills: []
```

---

## 参照

- .claude/skills/context-externalization/skill.md - 状態外部化の詳細
- CLAUDE.md CONTEXT セクション - コンテキスト管理ルール
