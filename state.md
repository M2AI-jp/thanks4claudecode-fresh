# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-precompact-debug-log.md
branch: fix/restore-demo-files
last_archived: plan/archive/playbook-restore-demo-files.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p1
done_criteria:
  - compact.sh の33行目（mkdir -p "$INIT_DIR"）直後にデバッグログコードが追加されている
  - evidence/precompact-debug.log にログが出力される仕組みが実装されている
status: in_progress
note: |
  PreCompact Hook デバッグログ追加
  目的: Hook が /compact 実行時に snapshot.json を作成しているか検証
```

---

## session

```yaml
last_start: 2026-01-02 09:27:08
last_end: 2026-01-01 21:10:00
last_clear: 2025-12-24 03:20:00
```

---

## config

```yaml
security: admin
toolstack: C  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: coderabbit      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
