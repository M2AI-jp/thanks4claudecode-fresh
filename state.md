# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: play/hook-fix-v1/plan.json
current_phase: p1
branch: feat/hook-fix-v1
last_archived: play/archive/python-filesearch
review_pending: false

```

---

## goal

```yaml
self_complete: false
milestone: hook-fix-v1
phase: p1
done_criteria:
  - progress.json 更新フローがドキュメントに明文化されている
  - subtask-guard.sh に validated_by: critic チェックが追加されている
  - reviewer 検証記録フローがドキュメントに明文化されている
  - executor-guard.sh の coderabbit 委譲が stdout に JSON 出力する形式になっている
  - Post-Loop 自動発火の条件と手順がドキュメントに明文化されている
  - 全修正の動作シミュレーションが PASS している
status: in_progress

```

---

## session

```yaml
last_start: 2026-01-07 02:10:34
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
