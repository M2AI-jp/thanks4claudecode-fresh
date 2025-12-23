# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: thanks4claudecode
project: plan/project.md
```

---

## playbook

```yaml
active: null
branch: null
last_archived: plan/archive/playbook-m087-understanding-check.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: null
done_criteria: []
note: M085-M087 完了。次は M088 (POST_LOOP ワークフロー完全自動化)
```

---

## session

```yaml
last_start: 2025-12-23 17:53:08
last_end: 2025-12-23 17:27:09
last_clear: 2025-12-13 00:30:00
```

---

## config

```yaml
security: admin
toolstack: B  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: claudecode      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画 |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
