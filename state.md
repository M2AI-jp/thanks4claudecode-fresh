# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: null
branch: null
last_archived: plan/archive/playbook-orchestration-completeness-100.md
review_pending: false
```

---

## goal

```yaml
milestone: orchestration-completeness-100
phase: completed
done_criteria:
  - ✅ state.md が status: completed, playbook.active: null に更新されている
  - ✅ evidence/orchestration-codex-evidence.md に agentId と transform.ts の紐付け証跡が存在する
  - ✅ tests/tmp-run.bats に run.sh の統合テストが存在し、bats で PASS する (8/8)
  - ✅ shellcheck, ruff, eslint による静的解析が導入されている
  - ✅ package-lock.json の健全性が確認されている (0 vulnerabilities)
  - ✅ tmp/README.md に再現手順が記載されている
  - ✅ scripts/qa.sh が存在し、全チェックを一括実行できる (5/5 PASS)
status: completed
note: |
  orchestration-completeness-100 タスク完了
  critic PASS: 2026-01-02T (agentId: a5a9ebb, done_when: 7/7)
  prior_work:
    - playbook: plan/archive/playbook-orchestration-practice.md
    - codex_agentId: a06e567 (transform.ts)
```

---

## session

```yaml
last_start: 2026-01-02 06:57:20
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
