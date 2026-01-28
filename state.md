# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: null
current_milestone: m6
status: idle
```

---

## playbook

```yaml
active: play/standalone/module-verification/plan.json
parent_project: null
current_phase: p1
branch: feat/module-verification-test
last_archived: play/archive/completion-verification
review_pending: false
```

---

## goal

```yaml
self_complete: true
milestone: module-verification
phase: p_final
done_criteria:
  - "14 Skills の SKILL.md が when/action 定義を持ち、関連スクリプトが構文エラーなく実行可能"
  - "7 SubAgents の agent 定義が必須フィールドを持ち、Task 呼び出しパターンと整合"
  - "10 Event Units の chain.sh が存在し、実行パスが正しく設定されている"
  - "全ファイルが SSOT と整合し、孤立ファイルが 0 件"
status: done
```

---

## session

```yaml
last_start: 2026-01-29 01:49:34
last_end: 2026-01-28 23:04:17
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
