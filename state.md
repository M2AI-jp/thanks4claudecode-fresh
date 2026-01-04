# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-ops-ssot.md
branch: docs/playbook-ops-ssot
last_archived: null
review_pending: false
```

---

## goal

```yaml
milestone: playbook-ops-ssot
phase: p1
done_criteria:
  - state/playbook-guard の前提強制が計画として明文化されている
  - UserPromptSubmit の固定チェーン計画が明文化されている
  - reward-guard + critic のゲート条件が計画として明文化されている
  - executor-guard の役割分離計画が明文化されている
  - post-tool-edit の自動アーカイブ計画が明文化されている
self_complete: true
status: completed
```

---

## session

```yaml
last_start: 2026-01-05 04:33:55
last_end: 2026-01-01 21:10:00
last_clear: 2025-12-24 03:20:00
```

---

## config

```yaml
security: admin
toolstack: C  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: coderabbit      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/core-feature-reclassification.md | Hook Unit SSOT |
