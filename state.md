# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: null
branch: null
last_archived: plan/archive/playbook-abort-playbook-skill.md
review_pending: false
```

---

## goal

```yaml
milestone: abort-playbook-skill
phase: p1
done_criteria:
  - abort-playbook Skill が存在し、playbook を plan/archive/ に移動できる
  - health.sh に orphan playbook 検出機能が存在する
  - health-checker.md に orphan 検出の説明が追加されている
  - 既存の orphan playbook-fix-playbook-branch-check.md が abort 処理されている
note: null
```

---

## session

```yaml
last_start: 2025-12-25 19:07:28
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
