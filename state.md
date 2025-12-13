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
active: plan/active/playbook-m014-folder-management.md
branch: feat/folder-management
```

---

## goal

```yaml
milestone: M014  # フォルダ管理ルール確立 & クリーンアップ機構実装
phase: p0  # アーカイブ候補ファイルの整理
self_complete: false
done_criteria:
  - 不要ファイルが .archive/ に移動されている
  - tmp/ フォルダが新設され、.gitignore に登録されている
  - .claude/hooks/cleanup-hook.sh が実装されている
  - 全 playbook テンプレートに cleanup phase が追加されている
  - docs/folder-management.md が作成されている
  - project.md に参照が追加されている
```

---

## session

```yaml
last_start: 2025-12-13 01:58:01
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
