# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: null
current_phase: null
branch: feat/python-filesearch
last_archived: play/archive/python-ext-counter
review_pending: false

```

---

## goal

```yaml
self_complete: true
milestone: python-ext-counter
phase: done
done_criteria:
  - tmp/ext_counter.py が存在し、python tmp/ext_counter.py <path> で拡張子別件数と合計を表形式で出力する
  - tmp/test_ext_counter.py が存在し、pytest tmp/test_ext_counter.py が exit 0 で終了する
  - 本体コードは Python 標準ライブラリのみを使用している
status: done

```

---

## session

```yaml
last_start: 2026-01-06 01:18:09
last_end: 2026-01-05 22:36:52
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
