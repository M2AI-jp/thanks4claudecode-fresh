# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、project/playbook を確認すること。

---

## project

```yaml
active: play/projects/repository-complete-verification/project.json
current_milestone: m4
status: in_progress
```

---

## playbook

```yaml
active: play/projects/repository-complete-verification/playbooks/pb-m4-skills/plan.json
parent_project: repository-complete-verification
current_phase: p1
branch: feat/m4-skill-verification
last_archived: play/archive/projects/repository-complete-verification/pb-m3-subagents
review_pending: false
```

---

## goal

```yaml
self_complete: false
milestone: m4
phase: p1
done_criteria:
  - 全 13 Skill ディレクトリに SKILL.md が存在する
  - 全 SKILL.md に Purpose セクションが存在する
  - 全 SKILL.md に When to Use セクションが存在する
  - Skill → SubAgent/Guard 参照が整合している
  - Adversarial invocation test で無効なスキル呼び出しが全て拒否されている
  - docs/reports/m4-skill-certification.json が生成され passed == true である
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-28 20:47:43
last_end: 2026-01-28 15:12:57
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
