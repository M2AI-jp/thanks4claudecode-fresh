# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-verify-subagent-data-flow.md
branch: verify/subagent-data-flow
last_archived: plan/archive/playbook-subagent-data-flow.md
review_pending: false
```

---

## goal

```yaml
milestone: verify-subagent-data-flow
phase: p_final
done_criteria:
  - term-translator に「テスト」「検証」の変換ルールが存在し、内容が適切である
  - understanding-check が translated_requirements を参照している
  - playbook-format.md と context-management に永続化フィールドが定義されている
  - prompt-analyzer に test_strategy, preconditions, success_criteria, reverse_dependencies が追加されている
  - validations に validation_type と証拠記録形式が定義されている
  - reviewer に 4QV+ の具体的判定基準と PASS/FAIL ログ形式が定義されている
status: ALL PASS - 全 done_criteria を検証完了
note: playbook-subagent-data-flow.md の修正内容を網羅的に検証完了
```

---

## session

```yaml
last_start: 2026-01-01 20:50:43
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
