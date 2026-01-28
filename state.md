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
active: play/standalone/repository-final-cleanup/plan.json
parent_project: null
current_phase: p_final
branch: feat/repository-cleanup-final
last_archived: play/archive/project-fix
review_pending: false
```

---

## goal

```yaml
self_complete: true
milestone: null
phase: p_final
done_criteria:
  - README.md に存在しないファイルへの参照がない
  - play/standalone/refactoring-cleanup/ が存在しない
  - play/standalone/new-repo-setup/ が存在しない
  - play/standalone/template-strictness-v2/ が存在しない
status: completed
```

---

## session

```yaml
last_start: 2026-01-28 14:11:38
last_end: 2026-01-28 02:47:07
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
| docs/bash-protection-issues.md | Bash 保護の誤検出パターン |
| docs/reward-fraud-test-results.md | 報酬詐欺耐性テスト結果 |
| docs/file-audit-report-2026-01-28.md | 全ファイル点検レポート |
