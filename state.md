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
active: plan/playbook-m058-system-correction.md
branch: fix/m058-system-correction
last_archived: M057 (achieved: 2025-12-17)
```

---

## goal

```yaml
milestone: M058
phase: p_final (done)
done_criteria:
  - archive-playbook.sh が state.md の正しい構造（playbook.active）を参照している
  - archive-playbook.sh の構文エラーが修正されている
  - plan/playbook-m057-cli-migration.md が削除されている
  - plan/archive/playbook-m057-cli-migration.md のみが存在する
  - project.md の M057 status が achieved に更新されている
  - project.md の M058 が新規マイルストーンとして追加されている
  - playbook-guard.sh が admin モードでも playbook チェックをバイパスしない
  - CLAUDE.md の「設計思想」セクションが Codex/CodeRabbit メインワーカーの方針に更新されている
```

---

## session

```yaml
last_start: 2025-12-17 04:32:26
last_clear: 2025-12-13 00:30:00
```

---

## config

```yaml
security: admin
toolstack: A  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画 |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
