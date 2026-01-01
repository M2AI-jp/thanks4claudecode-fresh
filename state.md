# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-subagent-data-flow.md
branch: fix/subagent-data-flow
last_archived: plan/archive/playbook-auto-retry.md
review_pending: true
```

---

## goal

```yaml
milestone: subagent-data-flow
phase: p1
done_criteria:
  - term-translator に「テスト」「検証」の変換ルールが追加されている
  - understanding-check が term-translator の出力を参照して技術用語でユーザーに確認している
  - playbook の context セクションに analysis_result, translated_requirements, user_approved_understanding が永続化される
  - prompt-analyzer にテスト戦略（test_strategy）の分析項目が追加されている
  - validations の実行フローが定義され、subtask 完了判定が自動化されている
  - reviewer の判定基準が具体化され、各 Q の PASS/FAIL がログに記録される
note: SubAgent 間のデータフロー断絶を修正し、プログラミング言語実装に耐えうる設計に改善する
```

---

## session

```yaml
last_start: 2026-01-01 18:54:16
last_end: 2025-12-24 03:27:11
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
