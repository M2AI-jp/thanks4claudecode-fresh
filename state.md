# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: play/python-filesearch/plan.json
current_phase: p1
branch: feat/python-filesearch
last_archived: play/archive/dir-brief
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: python-filesearch
phase: p1
done_criteria:
  - ./tmp/dir_brief.py <path> で実行可能である
  - 1階層一覧（ファイル/ディレクトリ）が表示される
  - 件数合計が表示される
  - 最大サイズが表示される
  - 最新更新日時が表示される
  - 空ディレクトリでもサマリーが表示される
  - 出力が ASCII テーブル形式である
  - pytest tmp/test_dir_brief.py が全 PASS である
  - git push が完了している
status: active

```

---

## session

```yaml
last_start: 2026-01-06 19:55:43
last_end: 2026-01-06 19:55:42
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
| docs/core-feature-reclassification.md | Hook Unit SSOT |
