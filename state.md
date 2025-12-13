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
active: null  # M015 完了
branch: feat/folder-management
```

---

## goal

```yaml
milestone: M015  # フォルダ管理ルール検証テスト（完了）
phase: done
self_complete: true
done_criteria:
  - tmp/ にテストファイルが生成されている ✓
  - 永続フォルダにテストファイルが生成されている ✓
  - cleanup-hook.sh が正常動作（手動検証済み）✓
  - tmp/ のテストファイルが削除されている ✓
  - 永続ファイルは保持されている ✓
```

---

## session

```yaml
last_start: 2025-12-13 17:08:47
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
| docs/folder-management.md | フォルダ管理ルール |
