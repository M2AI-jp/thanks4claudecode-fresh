# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: thanks4claudecode
```

---

## playbook

```yaml
active: plan/playbook-understanding-check-askuser.md
branch: feat/understanding-check-askuser
last_archived: plan/archive/playbook-docs-consolidation.md
review_pending: false
```

---

## goal

```yaml
milestone: understanding-check-askuser
phase: p1
done_criteria:
  - SKILL.md に選択肢フォーマット定義が存在する
  - pm.md に構造化された選択肢データを返す仕様が記載されている
  - AskUserQuestion で選択肢を提示するフローがドキュメント化されている
note: pm SubAgent の理解確認結果を選択肢形式でユーザーに提示する
```

---

## session

```yaml
last_start: 2025-12-25 02:50:32
last_end: 2025-12-24 03:27:11
last_clear: 2025-12-24 03:20:00
```

---

## config

```yaml
security: admin
toolstack: B  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: claudecode      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
