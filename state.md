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
active: plan/playbook-m063-repository-cleanup.md
branch: feat/m063-repository-cleanup
last_archived: M062 playbook-m062-fraud-investigation-e2e.md (2025-12-17)
```

---

## goal

```yaml
milestone: M063
phase: p1
done_criteria:
  - 孤立ファイル（plan-guard.md, CLAUDE-ref.md, context-externalization/, execution-management/）が削除されている
  - protected-files.txt から存在しないファイルへの参照が削除されている
  - 壊れた Hook（check-file-dependencies.sh, doc-freshness-check.sh, update-tracker.sh）が削除されている
  - settings.json から削除した Hook の登録が削除されている
  - ドキュメント（repository-map.yaml, CLAUDE.md 等）が更新されている
```

---

## session

```yaml
last_start: 2025-12-17 19:30:00
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
