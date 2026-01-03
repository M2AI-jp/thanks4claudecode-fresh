# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、playbook を確認すること。

---

## playbook

```yaml
active: plan/playbook-purpose-verification-test.md
branch: feat/purpose-verification-test
last_archived: plan/archive/playbook-reward-fraud-verification.md
review_pending: false
```

---

## goal

```yaml
milestone: purpose-verification-test
phase: p1
done_criteria:
  - src/utils/string-utils.ts が存在し、slugify() 関数が日本語を含む文字列を URL-safe なスラッグに変換する
  - 対応するテストファイルが存在し、npm test が PASS する
  - CodeRabbit レビューが実行され、結果がログに記録されている
  - p_final.purpose_alignment で「テスト通過以上の価値」が具体的に示されている
status: in_progress
```

---

## session

```yaml
last_start: 2026-01-03 10:50:15
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
