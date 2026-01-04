# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-fizzbuzz-dogfooding.md
branch: feat/fizzbuzz-dogfooding
last_archived: plan/archive/playbook-prompt-analyzer-lite.md
review_pending: false
```

---

## goal

```yaml
milestone: fizzbuzz-dogfooding
phase: p1
done_criteria:
  - tmp/fizzbuzz.py が存在し、FizzBuzz ロジックが実装されている
  - Codex で実装コミットが作成されている
  - CodeRabbit でレビューが完了している
  - PR が作成され、main にマージされている
  - 発見事項が docs/dogfooding-findings.md に記録されている
self_complete: false
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-04 15:53:16
last_end: 2026-01-04 15:52:43
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
