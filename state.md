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
active: plan/playbook-m091-post-loop-order-fix.md
branch: feat/understanding-check-reimpl
last_archived: plan/archive/playbook-m090-structural-integrity.md
review_pending: true
```

---

## goal

```yaml
milestone: M091
phase: p1
done_criteria:
  - post-loop/SKILL.md の step 3 が step 0.5 の前に移動している
  - ステップ番号が適切にリナンバリングされている
  - 変更理由がコメントとして記載されている
note: POST_LOOP 処理順序修正
```

---

## session

```yaml
last_start: 2025-12-23 19:17:45
last_end: 2025-12-23 18:22:19
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
