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
active: plan/active/playbook-strict-criteria.md
branch: feat/strict-criteria
```

---

## goal

```yaml
milestone: M006  # 厳密な done_criteria 定義システム
phase: p3
done_criteria:
  - done_criteria が Given/When/Then 形式で定義される
  - 各 criteria に test_command が紐付けられている
  - 曖昧な表現（「動作する」「正しく」等）が検出・拒否される
```

---

## session

```yaml
last_start: 2025-12-13 01:43:25
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
