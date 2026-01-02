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
phase: p_final
done_criteria:
  - compact.sh が最小ポインタ（playbook/phase/branch）のみを additionalContext に出力する
  - snapshot.json 作成コードが削除されている
  - start.sh から restore_from_snapshot が削除されている
  - ARCHITECTURE.md に PreCompact セクションと全 Skills が記載されている
  - repository-map.yaml が最新状態に同期されている
status: in_progress
note: |
  PreCompact 設計の刷新: snapshot.json 廃止 → 最小ポインタ設計
  p1-p4 完了、p_final（完了検証）待ち
```

---

## session

```yaml
last_start: 2026-01-02 16:46:21
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
