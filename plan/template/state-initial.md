# state-initial.md

> **フォーク直後の state.md 初期状態テンプレート。**
> **M5 完了時に state.md をこの内容でリセットする。**

---

## 使い方

1. このファイルの「テンプレート」セクション以下を state.md にコピー
2. または `cp plan/template/state-initial.md state.md` を実行

---

## テンプレート

```markdown
# state.md

> **統合状態管理ファイル（Single Source of Truth）**
>
> 4つのレイヤーを管理: plan-template → workspace → setup → product
> LLMはセッション開始時に必ずこのファイルを読み、`focus.current` を確認すること。

---

## focus

```yaml
current: setup               # plan-template | workspace | setup | product
session: task                # task | discussion
```

---

## security

```yaml
mode: strict                 # strict | trusted | developer
```

---

## active_playbooks

```yaml
plan-template:    null
workspace:        null
setup:            setup/playbook-setup.md   # デフォルト playbook
product:          null                       # setup 完了後、product 開発用に作成
```

---

## context

```yaml
mode: normal                 # normal | interrupt
interrupt_reason: null
return_to: null
```

---

## plan_hierarchy

```yaml
roadmap: null                # workspace 開発者のみ使用
current_milestone: null
```

---

## project_context

> **setup 完了後に更新される。**

```yaml
generated: false             # true = setup 完了、plan/project.md 生成済み
project_plan: null           # 生成後: plan/project.md
```

---

## layer: plan-template

```yaml
state: done
sub: v3-complete
playbook: null
```

---

## layer: workspace

```yaml
state: done
sub: v7.0-plan-hierarchy-complete
playbook: null
```

---

## layer: setup

```yaml
state: pending               # これから実行
sub: null
playbook: setup/playbook-setup.md
```

### 概要
> setup/playbook-setup.md に従って環境をセットアップする。
> Phase 0-8 を完了後、plan/project.md を生成し product レイヤーへ移行。
> CATALOG.md は必要な時だけ参照。

---

## layer: product

```yaml
state: pending               # setup 完了後に有効化
sub: null
playbook: null
```

### 概要
> ユーザーが実際にプロダクトを開発するためのレイヤー。
> setup 完了後、plan/project.md を参照して TDD で開発。

---

## goal

```yaml
phase: pending
done_criteria:
  - setup/playbook-setup.md Phase 0-8 を完了する
  - plan/project.md が生成される
  - focus.current が product に切り替わる
```

### 次のステップ
```
Claude Code を起動したら、setup/playbook-setup.md の指示に従ってください。
```

---

## verification

```yaml
self_complete: false
user_verified: false
```

---

## states

```yaml
flow: pending → designing → implementing → [reviewing →] state_update → done
forbidden: [pending→implementing], [pending→done], [*→done without state_update]
```

---

## rules

```yaml
原則: focus.current のレイヤーのみ編集可能
例外: state.md の focus/context/verification は常に編集可能
保護: CLAUDE.md は BLOCK（ユーザー許可必要）
```

---

## session_tracking

> **Hooks による自動更新。LLM の行動に依存しない。**

```yaml
last_start: null             # SessionStart で自動更新
last_end: null               # SessionEnd で自動更新
uncommitted_warning: false   # 前回セッション終了時に未コミットがあったか
```

---

## 参照ファイル

| ファイル | 内容 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | Macro 計画（setup 完了後に生成） |
| architecture-*.md | システム設計図 |

---

## 変更履歴

| 日時 | 内容 |
|------|------|
| - | フォーク直後の初期状態 |
```

---

## 検証方法

state.md をこのテンプレートでリセット後、以下を確認:

1. `bash .claude/hooks/session-start.sh` を実行
2. 出力に `setup/playbook-setup.md` への Read 指示があること
3. 出力に「Phase 0 から開始」の説明があること
4. [自認] テンプレートに `playbook: setup/playbook-setup.md` があること
5. PLAYBOOK 未作成警告が出ないこと
6. GUIDE.md への参照がないこと（playbook-setup.md に統合済み）
