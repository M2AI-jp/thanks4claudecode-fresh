# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: play/dir-brief/plan.json
current_phase: p1
branch: feat/python-filesearch
last_archived: play/archive/dir-snapshot
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: dir-brief
phase: p1
done_criteria:
  - "./tmp/dir_brief.py <path> で実行可能である"
  - "1階層一覧（ファイル/ディレクトリ）が表示される"
  - "件数合計・最大サイズ・最新更新日時がサマリーとして表示される"
  - "空ディレクトリでもサマリーが表示される"
  - "出力が ASCII テーブル形式である"
  - "標準ライブラリのみ使用している"
  - "tmp/test_dir_brief.py の pytest テストが全て PASS する"
  - "git push が完了している"
status: active

```

---

## session

```yaml
last_start: 2026-01-06 18:55:54
last_end: 2026-01-06 18:55:53
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
