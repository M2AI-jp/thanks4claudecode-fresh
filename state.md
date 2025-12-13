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
active: plan/active/playbook-m020-changelog-monitor.md
branch: feat/m020-changelog-monitor
```

---

## goal

```yaml
milestone: M020  # Claude Code CHANGELOG モニタリングシステム
phase: p0  # キャッシュディレクトリ & メタデータ構造設計
self_complete: false
last_completed_milestone: M019 (achieved: 2025-12-13)
```

---

## session

```yaml
last_start: 2025-12-13 21:29:47
last_clear: 2025-12-13 20:59:00
last_playbook_completed: 2025-12-13 20:59:00
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
