# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-verify-prompt-sh-grep-awk.md
branch: fix/verify-prompt-sh-grep-awk
last_archived: plan/archive/playbook-fix-pending-guard-fail-closed.md
review_pending: false
```

---

## goal

```yaml
milestone: null
phase: p1
done_criteria:
  - prompt.sh 内の全 grep/awk 使用箇所（行 18, 20, 47, 50, 52）のエラーハンドリング状態が文書化されている
  - 0 件/パターン不一致ケースでのテスト実行結果が exit 0 を維持する
  - 問題がある場合は修正済み、問題がない場合は「検証済み・問題なし」が証拠付きで記録されている
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-03 16:40:25
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
