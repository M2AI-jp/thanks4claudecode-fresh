# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: thanks4claudecode  # 現在作業中のプロジェクト名
project: plan/project.md
```

---

## playbook

```yaml
active: plan/active/playbook-m021-changelog-suggest.md
branch: feat/m021-changelog-suggest
```

---

## goal

```yaml
milestone: M021  # CHANGELOG サジェストシステム
phase: p2
self_complete: false
last_completed_milestone: M020 (achieved: 2025-12-13)
```

---

## session

```yaml
last_start: 2025-12-13 21:29:47
last_clear: 2025-12-13 20:59:00
last_playbook_completed: 2025-12-13 22:15:00
```

---

## config

```yaml
security: admin
learning:
  operator: hybrid
  expertise: intermediate
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画 |
| docs/feature-map.md | 機能マップ |
