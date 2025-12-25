# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-post-loop-auto-fire.md
branch: feat/post-loop-auto-fire
last_archived: plan/archive/playbook-remove-focus.md
review_pending: false
```

---

## goal

```yaml
milestone: post-loop-auto-fire
phase: p1
done_criteria:
  - archive-playbook.sh が playbook 完了時にアーカイブ/PR 作成/マージを自動実行する
  - pre-tool.sh が post-loop-pending を検出し、post-loop 実行を強制する
  - post-loop Skill が次タスク導出のみを担当し、pending を削除する
note: playbook 完了時の post-loop 自動発火を実装
```

---

## session

```yaml
last_start: 2025-12-25 15:58:13
last_end: 2025-12-24 03:27:11
last_clear: 2025-12-24 03:20:00
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
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
