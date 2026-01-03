# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-pb01-pb08-hook-fixes.md
branch: fix/pb01-pb08-hook-fixes
last_archived: plan/archive/playbook-hook-robustness-phase2.md
review_pending: false
```

---

## goal

```yaml
milestone: pb01-pb08-hook-fixes
phase: p1
done_criteria:
  - playbook-guard.sh の INPUT=$(cat) が timeout 付きパターンに変更されている
  - 修正後の playbook-guard.sh が bash -n を通過する
  - PB-08 が fix-backlog.md で正式に CLOSED としてマーキングされている
  - PB-01 が fix-backlog.md で FIXED としてマーキングされている
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-03 18:14:25
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
