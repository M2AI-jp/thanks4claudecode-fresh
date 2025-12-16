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
active: playbook-m057-cli-migration.md
branch: feat/m057-cli-migration
last_archived: M056 (achieved: 2025-12-17)
```

---

## goal

```yaml
milestone: M057
phase: p1
done_criteria:
  - .mcp.json から codex エントリが削除されている
  - docs/toolstack-patterns.md が MCP → CLI に全面書き換えされている
  - .claude/agents/codex-delegate.md が CLI ベースに修正されている
  - .claude/hooks/executor-guard.sh の MCP 参照が CLI に修正されている
  - plan/template/playbook-format.md の executor 説明が更新されている
  - .claude/CLAUDE-ref.md の MCP 参照が削除されている
  - setup/playbook-setup.md の MCP 設定が CLI に修正されている
  - repository-map.yaml が更新されている
```

---

## session

```yaml
last_start: 2025-12-17 03:03:51
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
