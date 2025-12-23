# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: thanks4claudecode
project: plan/project.md
```

---

## playbook

```yaml
active: plan/playbook-m086-4qv-structure-analysis.md
branch: feat/state-project-playbook-optimization
last_archived: plan/archive/playbook-m085-orchestration-automation.md
review_pending: false
```

---

## goal

```yaml
milestone: M086
phase: p1
done_criteria:
  - tmp/analysis-4qv-structure.md に現状マッピング図が存在する
  - 課題リストが 5 項目以上含まれている
  - 改善の方向性案が記載されている
  - 仮想シナリオ「ChatGPT アプリを作る」の動線検証結果が含まれている
```

---

## session

```yaml
last_start: 2025-12-23 16:20:03
last_end: 2025-12-22 22:35:47
last_clear: 2025-12-13 00:30:00
```

---

## config

```yaml
security: admin
toolstack: B  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: codex             # 実装担当（A: claudecode, B/C: codex）
  reviewer: claudecode      # レビュー担当（A/B: claudecode, C: coderabbit）
  human: user               # 人間の介入（常に user）
```

---

## 参照

| ファイル | 役割 |
|----------|------|
| CLAUDE.md | LLM の振る舞いルール |
| plan/project.md | プロジェクト計画 |
| docs/repository-map.yaml | 全ファイルマッピング（自動生成） |
| docs/folder-management.md | フォルダ管理ルール |
