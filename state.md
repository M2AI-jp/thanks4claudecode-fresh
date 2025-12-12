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
active: plan/active/playbook-system-architecture-map.md
branch: feat/system-architecture-map
```

---

## goal

```yaml
milestone: M007  # システムアーキテクチャ可視化 - achieved
phase: done
done_criteria:
  - [x] docs/feature-map.md が存在する
  - [x] 全 Hook（29ファイル）が発火タイミング別に整理
  - [x] SubAgent 一覧（8種類）が記載
  - [x] Skill 一覧（13個）が記載
  - [x] ファイル間の依存関係が図解
```

---

## session

```yaml
last_start: 2025-12-13 02:06:57
last_clear: 2025-12-13 00:30:00
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
