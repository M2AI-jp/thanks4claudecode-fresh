# state-initial.md

> **フォーク直後の state.md 初期状態テンプレート。**
> **セットアップ開始時に state.md をこの内容でリセットする。**

---

## 使い方

1. このファイルの「テンプレート」セクション以下を state.md にコピー
2. または `cp plan/template/state-initial.md state.md` を実行

---

## テンプレート

```markdown
# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: setup  # setup | product | plan-template
```

---

## playbook

```yaml
active: setup/playbook-setup.md
branch: null  # setup は main で実行可
last_archived: null
```

---

## goal

```yaml
phase: p0
done_criteria:
  - setup/playbook-setup.md Phase 0-8 を完了する
  - focus.current が product に切り替わる
```

---

## session

```yaml
last_start: null   # SessionStart で自動更新
last_clear: null
```

---

## config

```yaml
security: admin
toolstack: A  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode
  worker: claudecode
  reviewer: claudecode
  human: user
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
```

---

## 検証方法

state.md をこのテンプレートでリセット後、以下を確認:

1. `bash .claude/hooks/session-start.sh` を実行
2. 出力に `setup/playbook-setup.md` への Read 指示があること
3. 出力に「Phase 0 から開始」の説明があること
4. [自認] テンプレートに `playbook: setup/playbook-setup.md` があること
5. PLAYBOOK 未作成警告が出ないこと
