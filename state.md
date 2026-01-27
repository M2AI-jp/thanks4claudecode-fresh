# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: null
current_milestone: m1
status: idle
```

---

## playbook

```yaml
active: play/standalone/complete-deadlock-fix/plan.json
parent_project: null
current_phase: p1
branch: feat/complete-deadlock-prevention
last_archived: play/archive/deadlock-prevention
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: null
phase: p1
done_criteria:
  - BOOTSTRAP_SINGLE_PATTERNS に git rebase --skip パターンが含まれる
  - BOOTSTRAP_SINGLE_PATTERNS に git rebase --continue パターンが含まれる
  - BOOTSTRAP_SINGLE_PATTERNS に git branch -D パターンが含まれる
  - has_file_redirect 関数が heredoc (<<) を除外するロジックを含む
  - feat/complete-deadlock-prevention ブランチが main と同期されている
status: active
```

---

## session

```yaml
last_start: 2026-01-28 01:55:29
last_end: 2026-01-27 23:40:48
last_clear: 2026-01-20
```

---

## config

```yaml
security: admin
toolstack: C
roles:
  orchestrator: claudecode
  worker: codex
  reviewer: coderabbit
  human: user
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/core-feature-reclassification.md | Hook Unit SSOT |
