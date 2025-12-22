# state.md

> **現在地を示す Single Source of Truth**
>
> LLM はセッション開始時に必ずこのファイルを読み、focus と playbook を確認すること。

---

## focus

```yaml
current: m082-repository-optimization
project: plan/project.md
```

---

## playbook

```yaml
active: plan/playbook-m082-repository-optimization.md
branch: feat/m085-work-loop-verification
last_archived: plan/archive/playbook-m088-project-complete-verification.md
```

---

## goal

```yaml
milestone: M082
phase: p8
done_criteria:
  - repository-map.yaml が MECE 原則に基づいて整理されている
  - workflows セクションが最新の Hook/SubAgent/Skill 構成を反映している
  - 全 5 workflows の E2E 動作検証が完了している
  - 変更が GitHub にプッシュされ main にマージされている
```

---

## session

```yaml
last_start: 2025-12-22 19:45:40
last_clear: 2025-12-13 00:30:00
```

---

## config

```yaml
security: admin
toolstack: A  # A: Claude Code only | B: +Codex | C: +Codex+CodeRabbit
roles:
  orchestrator: claudecode  # 監督・調整・設計（常に claudecode）
  worker: claudecode        # 実装担当（A: claudecode, B/C: codex）
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
